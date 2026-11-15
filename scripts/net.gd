extends Node
## Autoload "Net": ENet host/join plus LAN discovery over UDP broadcast.
## Host = server + player (peer id 1). Join = type the host's IP, or pick it from the LAN list.

signal joined           # client connected to a host
signal join_failed
signal host_lost        # client lost connection to the host
signal peer_left(id: int)

var player_name := "Survivor"
var _beacon: PacketPeerUDP
var _beacon_timer := 0.0
var _listener: PacketPeerUDP
var lan_games := {} # ip -> { name, players, seen_ms }


func _ready() -> void:
	multiplayer.connected_to_server.connect(func(): joined.emit())
	multiplayer.connection_failed.connect(func(): _reset(); join_failed.emit())
	multiplayer.server_disconnected.connect(func(): _reset(); host_lost.emit())
	multiplayer.peer_disconnected.connect(func(id: int): peer_left.emit(id))


func host() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(Config.PORT, Config.MAX_PLAYERS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	stop_listening()
	_beacon = PacketPeerUDP.new()
	_beacon.set_broadcast_enabled(true)
	_beacon.set_dest_address("255.255.255.255", Config.DISCOVERY_PORT)
	return OK


func join(ip: String) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip.strip_edges(), Config.PORT)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	return OK


func leave() -> void:
	_reset()


func _reset() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	if _beacon:
		_beacon.close()
		_beacon = null


func is_online() -> bool:
	return not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer)


## Round-trip time to the host in ms (0 on the host itself).
func ping_ms() -> int:
	var peer := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if peer == null or multiplayer.is_server():
		return 0
	var host_peer := peer.get_peer(1)
	return int(host_peer.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME)) if host_peer else 0


# --- LAN discovery ------------------------------------------------------------

func start_listening() -> void:
	if _listener:
		return
	_listener = PacketPeerUDP.new()
	if _listener.bind(Config.DISCOVERY_PORT) != OK:
		push_warning("LAN discovery port %d busy; type the IP instead." % Config.DISCOVERY_PORT)
		_listener = null


func stop_listening() -> void:
	if _listener:
		_listener.close()
		_listener = null
	lan_games.clear()


func _process(delta: float) -> void:
	if _beacon:
		_beacon_timer -= delta
		if _beacon_timer <= 0.0:
			_beacon_timer = 1.0
			var info := { "game": "zombie-extraction", "name": player_name,
				"players": multiplayer.get_peers().size() + 1 }
			_beacon.put_packet(JSON.stringify(info).to_utf8_buffer())
	if _listener:
		while _listener.get_available_packet_count() > 0:
			var data := _listener.get_packet().get_string_from_utf8()
			var ip := _listener.get_packet_ip()
			var info = JSON.parse_string(data)
			if info is Dictionary and info.get("game") == "zombie-extraction":
				lan_games[ip] = { "name": str(info.get("name", "?")), "players": int(info.get("players", 0)),
					"seen_ms": Time.get_ticks_msec() }
		for ip in lan_games.keys():
			if Time.get_ticks_msec() - lan_games[ip].seen_ms > 3500:
				lan_games.erase(ip)


## This machine's LAN IPv4 addresses, to show the host what to tell friends.
func local_ips() -> PackedStringArray:
	var out := PackedStringArray()
	for ip in IP.get_local_addresses():
		if ip.count(".") == 3 and not ip.begins_with("127.") and not ip.begins_with("169.254."):
			out.append(ip)
	return out
