extends Node

func _ready():
	
	DiscordRPC.app_id = 1226128527049494588
	DiscordRPC.details = "PianoLux in 3D"
	DiscordRPC.state = "Making MIDI piano covers with Leds"
	DiscordRPC.large_image = "discord-rcp"
	DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system())
	DiscordRPC.refresh()
