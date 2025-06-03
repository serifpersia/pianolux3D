extends Control

var pitch: int

@onready var led_offset_dropdown: OptionButton = $VBoxContainer/LedOffsetDropdown
@onready var close_dialog_button: Button = $VBoxContainer/CloseDialogButton
@onready var led_offset_label: Label = $VBoxContainer/LedOffsetLabel

var note_names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

@export var player : CharacterBody3D

# Function to convert pitch to note name
func pitch_to_note_name(note_pitch: int) -> String:
	if note_pitch < 21 or note_pitch > 108:
		return ""

	var note_index = (note_pitch - 21 + 9) % 12
	var octave = float(note_pitch - 21 + 9) / 12

	return note_names[note_index] + str(int(octave))

func _ready() -> void:
	populate_dropdown()
	led_offset_dropdown.select(12)

func populate_dropdown() -> void:
	led_offset_dropdown.clear()
	for i in range(-12, 13):
		led_offset_dropdown.add_item(str(i))

func initialize_dialog(passed_pitch: int, passed_player: CharacterBody3D):
	self.pitch = passed_pitch
	self.player = passed_player
	
	#print("Dialog initialized for pitch:", pitch)
	
	var current_offset = Global.offset_map.get(pitch, 0)
	
	led_offset_dropdown.select(current_offset + 12)
	led_offset_label.text = "Led Offset For: " + pitch_to_note_name(pitch)

func _on_led_offset_dropdown_item_selected(index: int) -> void:
	var selected_offset = int(led_offset_dropdown.get_item_text(index))
	Global.offset_map[pitch] = selected_offset
	#print("Updated Global offset map for pitch", pitch, ": ", selected_offset)

func _on_close_dialog_button_pressed() -> void:
	queue_free()

func _on_reset_all_offsets_button_pressed() -> void:
	for note in range(21, 109):
		Global.offset_map[note] = 0
	led_offset_dropdown.select(12)
	queue_free()
