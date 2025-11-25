extends Node

# Constants
const PORT := 2450
const DISCOVERY_PORT := 55555
const MAX_PLAYERS := 2
const TIMEOUT_SEC = 2.0

var server_mode = "LAN"
var game_mode = "standard"

# LAN networking
var peer: ENetMultiplayerPeer
var udpServer := PacketPeerUDP.new()
var udpClient := PacketPeerUDP.new()
var broadcast_timer: SceneTreeTimer
var broadcast_timer_active := false

# Steam networking
var steam = Steam
var lobby_id: int = 0
var last_lobby_members: Array = []

signal log_message(msg: String)
signal chess_lobby_joined()
signal message_received(sender, text: String, colon: bool)
signal move_received(packet)
signal role_received(is_white: bool)
signal lobby_left()

func _ready():
	if steam:
		var init = steam.steamInit()
		if init != false:
			emit_signal("log_message", "Steam API initialized: " + str(steam.isSteamRunning()))
			steam.lobby_created.connect(_on_steam_lobby_created)
			steam.lobby_joined.connect(_on_steam_lobby_joined)
			steam.lobby_match_list.connect(_on_steam_lobby_list)
			steam.p2p_session_request.connect(_on_steam_p2p_session_request)
			steam.p2p_session_connect_fail.connect(_on_steam_p2p_session_fail)
			steam.join_requested.connect(_on_lobby_join_requested)
		else:
			emit_signal("log_message", "Steam API failed to initialize!")
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	connect("log_message", Callable(self, "_on_log"))

func _process(_delta):
	if steam:
		steam.run_callbacks()
		# Check for Steam P2P packets
		while steam.getAvailableP2PPacketSize(0) > 0:
			var pkt = steam.readP2PPacket(1024, 0)
			if pkt.has("data") and pkt.data.size() > 0:
				var packet = pkt.data.get_string_from_utf8()
				if packet.type == "chat":
					emit_signal("message_received", steam.getFriendPersonaName(pkt.remote_steam_id), packet.message, true)
				elif packet.type == "move":
					emit_signal("move_received", packet)
				elif packet.type == "role":
					emit_signal("role_received", packet.is_white)
		# Check lobby member changes
		if lobby_id != 0:
			check_lobby_member_changes()

func _on_log(msg: String):
	print(msg)

# =========================================================
# PUBLIC API (called from UI or game scene)
# =========================================================
func set_modes(new_server_mode: String, new_game_mode: String):
	server_mode = new_server_mode
	game_mode = new_game_mode

#func host():
	#if mode == "LAN":
		#_host_lan()
	#elif mode == "Steam":
		#_host_steam()
#
#func join():
	#if mode == "LAN":
		#_join_lan()
	#elif mode == "Steam":
		#_join_steam()

func leave():
	if server_mode == "LAN":
		_leave_lan()
	elif server_mode == "Steam":
		_leave_steam()

func send_packet(msg: String, _target_id: int = 0):
	if peer and multiplayer.multiplayer_peer == peer:
		if multiplayer.is_server():
			rpc("receive_packet", msg, multiplayer.get_unique_id())
		else:
			rpc_id(1, "receive_packet", msg, multiplayer.get_unique_id())
	elif steam and lobby_id != 0:
		# Broadcast to all members
		var members = []
		for i in range(steam.getNumLobbyMembers(lobby_id)):
			var sid = steam.getLobbyMemberByIndex(lobby_id, i)
			if sid != steam.getSteamID():
				members.append(sid)
		var buf = msg.to_utf8_buffer()
		for m in members:
			steam.sendP2PPacket(m, buf, steam.P2P_SEND_RELIABLE, 0)
		emit_signal("log_message", "Steam: Sent msg: " + msg)

func send_roles():
	var rng = RandomNumberGenerator.new()
	var data = {
		"type": "role",
		"is_white": true
	}
	if rng.randi_range(0, 1) == 0:
		data.is_white = true
	else:
		data.is_white = false
	
	emit_signal("role_received", not data.is_white)
	var packet = JSON.stringify(data)
	send_packet(packet)

# =========================================================
# LAN Implementation
# =========================================================
func start_lan(game_mode: String):
	set_modes("LAN", game_mode)
	if not await _join_lan():
		_host_lan()

func _host_lan():
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(PORT, MAX_PLAYERS)
	if err != OK:
		emit_signal("log_message", "LAN: Failed to host (error %s)" % err)
		return
	multiplayer.multiplayer_peer = peer
	
	emit_signal("log_message", "LAN: Server hosted on port %d" % PORT)
	emit_signal("chess_lobby_joined")
	
	broadcast_timer_active = true
	_send_broadcast_loop()

func _send_broadcast_loop():
	if not broadcast_timer_active:
		return
	
	udpServer.set_broadcast_enabled(true)
	udpServer.set_dest_address("255.255.255.255", DISCOVERY_PORT)
	
	_send_broadcast()
	
	# Schedule next broadcast after 2 seconds
	var t = get_tree().create_timer(2.0)
	t.timeout.connect(_send_broadcast_loop)

func _send_broadcast():
	emit_signal("log_message", "LAN: Broadcasting server")
	var msg = {
		"id" : "CHESS_HOST",
		"mode" : game_mode
	}
	udpServer.put_packet(JSON.stringify(msg).to_utf8_buffer())

func _join_lan() -> bool:
	emit_signal("log_message", "LAN: Searching for LAN host...")
	var err = udpClient.bind(DISCOVERY_PORT)
	if err != OK:
		emit_signal("log_message", "LAN: UDP bind failed (error %s)" % err)
		return false
	
	udpClient.set_broadcast_enabled(true)
	
	var timer := 0.0
	while timer < TIMEOUT_SEC:
		if udpClient.get_available_packet_count() > 0:
			var data = JSON.parse_string(udpClient.get_packet().get_string_from_utf8())
			if data.id == "CHESS_HOST" and data.mode == game_mode:
				var host_ip = udpClient.get_packet_ip()
				udpClient.close()
				emit_signal("log_message", "LAN: Found host at %s" % host_ip)
				peer = ENetMultiplayerPeer.new()
				var err2 = peer.create_client(host_ip, PORT)
				if err2 == OK:
					multiplayer.multiplayer_peer = peer
					emit_signal("log_message", "LAN: Connected to server on %s:%d" % [host_ip, PORT])
					emit_signal("chess_lobby_joined")
				else:
					emit_signal("log_message", "LAN: Failed to connect (error %s)" % err2)
				return true
		await get_tree().process_frame
		timer += get_process_delta_time()
	emit_signal("log_message", "LAN: No host found on LAN")
	udpClient.close()
	return false

func _leave_lan():
	broadcast_timer_active = false
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	emit_signal("lobby_left")

func _on_peer_connected(id: int):
	if id != 1:
		broadcast_timer_active = false
		emit_signal("message_received", "guest", " joined", false)
		send_roles()

func _on_peer_disconnected(id: int):
	if id == 1:
		emit_signal("message_received", "host", " left", false)
	else:
		emit_signal("message_received", "guest", " left", false)
		broadcast_timer_active = true
		_send_broadcast_loop()

@rpc("any_peer")
func receive_packet(data: String, from_id: int):
	var packet = JSON.parse_string(data)
	if packet.type == "chat":
		emit_signal("message_received", "host" if from_id == 1 else "guest", packet.message, true)
	elif packet.type == "move":
		emit_signal("move_received", packet)
	elif packet.type == "role":
		emit_signal("role_received", packet.is_white)

# =========================================================
# Steam Implementation
# =========================================================
func start_steam(game_mode: String):
	set_modes("Steam", game_mode)
	_join_steam()

func _host_steam():
	if steam == null:
		emit_signal("log_message", "Steam not available")
		return
	steam.createLobby(steam.LOBBY_TYPE_PUBLIC, MAX_PLAYERS)
	emit_signal("log_message", "Steam: Creating lobby...")

func _join_steam():
	if steam == null:
		emit_signal("log_message", "Steam not available")
		return
	emit_signal("log_message", "Steam: Requesting lobby list...")
	steam.addRequestLobbyListStringFilter("name", "chessgame61849", Steam.LOBBY_COMPARISON_EQUAL)
	steam.addRequestLobbyListStringFilter("mode", game_mode, Steam.LOBBY_COMPARISON_EQUAL)
	steam.requestLobbyList()

func _leave_steam():
	if lobby_id != 0:
		close_all_p2p_sessions()
		Steam.leaveLobby(lobby_id)
		lobby_id = 0
	emit_signal("lobby_left")

func close_all_p2p_sessions():
	if lobby_id == 0:
		return
	var member_count = steam.getNumLobbyMembers(lobby_id)
	for i in range(member_count):
		var member_steam_id = steam.getLobbyMemberByIndex(lobby_id, i)
		if member_steam_id != steam.getSteamID():
			steam.closeP2PSessionWithUser(member_steam_id)
			print("Closed P2P session with:", member_steam_id)

func check_lobby_member_changes():
	var current_members: Array = []
	var member_count = steam.getNumLobbyMembers(lobby_id)
	
	for i in range(member_count):
		var member = steam.getLobbyMemberByIndex(lobby_id, i)
		if member != 0:
			current_members.append(member)
	
	# Detect joins
	for m in current_members:
		if not last_lobby_members.has(m):
			if m != steam.getSteamID():
				print(last_lobby_members, " - ", current_members)
				emit_signal("message_received", steam.getFriendPersonaName(m), " joined", false)
	
	# Detect leaves
	for m in last_lobby_members:
		if not current_members.has(m):
			print(last_lobby_members, " - ", current_members)
			emit_signal("message_received", steam.getFriendPersonaName(m), " left", false)
	
	last_lobby_members = current_members

# =========================================================
# Steam Callbacks
# =========================================================
func _on_steam_lobby_created(connectionStatus, new_lobby_id):
	if connectionStatus != 1:
		emit_signal("log_message", "Steam: Failed to create lobby")
		return
	lobby_id = new_lobby_id
	steam.setLobbyJoinable(lobby_id, true)
	steam.setLobbyData(lobby_id, "name", "chessgame61849")
	steam.setLobbyData(lobby_id, "mode", game_mode)
	
	Steam.allowP2PPacketRelay(true)
	
	emit_signal("log_message", "Steam: Lobby created with ID %s" % str(lobby_id))

func _on_steam_lobby_list(lobbies):
	emit_signal("log_message", "Lobbies found: %d" % lobbies.size())
	if lobbies.size() > 0:
		steam.joinLobby(lobbies[0])
	else:
		_host_steam()

func _on_steam_lobby_joined(new_lobby_id, _permissions, _locked, response):
	if response != 1:
		emit_signal("log_message", "Steam: Failed to join lobby (response %s)" % str(response))
		return
	lobby_id = new_lobby_id
	
	last_lobby_members = []
	var member_count = steam.getNumLobbyMembers(lobby_id)
	for i in range(member_count):
		last_lobby_members.append(steam.getLobbyMemberByIndex(lobby_id, i))
	
	emit_signal("log_message", "Steam: Joined lobby %s" % str(lobby_id))
	emit_signal("chess_lobby_joined")

func _on_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
	var owner_name: String = Steam.getFriendPersonaName(friend_id)
	emit_signal("log_message", "Steam: Joining %s's lobby..." % owner_name)
	steam.joinLobby(this_lobby_id)

func _on_steam_p2p_session_request(remote_id):
	emit_signal("log_message", "Steam: P2P session request from %s" % str(remote_id))
	steam.acceptP2PSessionWithUser(remote_id)

func _on_steam_p2p_session_fail(remote_id, error):
	emit_signal("log_message", "Steam: P2P session with %s failed (error %s)" % [str(remote_id), str(error)])
