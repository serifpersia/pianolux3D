extends Node2D

@onready var animation_player = $AnimationPlayer

func _ready():
	animation_player.play("fade_in")
	await get_tree().create_timer(1).timeout
	animation_player.play("fade_out")
	await get_tree().create_timer(1).timeout
	get_tree().change_scene_to_file("res://scenes/main.tscn")
