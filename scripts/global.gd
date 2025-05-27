extends Node

var particles_state : bool = true
var offset_map: Dictionary = {}

var player: CharacterBody3D

func _ready() -> void:
	for note in range(21, 109):
		offset_map[note] = 0
