extends Node

func _ready():
	if Engine.has_singleton("DiscordRPC"):
		var discord_rpc = Engine.get_singleton("DiscordRPC")
		discord_rpc.app_id = 1226128527049494588
		discord_rpc.details = "PianoLux in 3D"
		discord_rpc.state = "Making piano covers with LEDs"
		discord_rpc.large_image = "discord-rcp"
		discord_rpc.start_timestamp = int(Time.get_unix_time_from_system())
		discord_rpc.refresh()
	else:
		print("Discord RPC plugin not installed. Skipping Discord integration.")
