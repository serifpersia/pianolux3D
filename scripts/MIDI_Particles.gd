extends Node3D

@export var note_on_white_key_particles_material : StandardMaterial3D

@export var particle_scene : PackedScene

@onready var midi_notes: Node3D = $"../MIDI_Notes"

var active_particles = {}
var child_particles = {}
	
func spawn_particle(pitch):
	if not particle_scene:
		return
		
	if Global.particles_state:
		var particle_instance = particle_scene.instantiate()
		
		var is_black = midi_notes.is_black_key(pitch)

		var note_mesh := midi_notes.get_node(str(pitch))
		
		var note_mesh_y =  note_mesh.position.y + 3.65 if is_black else note_mesh.position.y + 6.25
		var note_mesh_z = note_mesh.position.z + 11.35 if is_black else note_mesh.position.z + 9.35
		
		particle_instance.position = Vector3(note_mesh.position.x, note_mesh_y, note_mesh_z)
		particle_instance.scale = Vector3(2.75, 2.75, 2.75)

		if is_black:
			note_on_white_key_particles_material.emission = midi_notes.black_note_mesh_color
		else:
			note_on_white_key_particles_material.emission = midi_notes.white_note_mesh_color
			
		add_child(particle_instance)
		
		particle_instance.emitting = true
		
		active_particles[pitch] = particle_instance
		
		for child in particle_instance.get_children():
			child.emitting = true
			if not child_particles.has(pitch):
				child_particles[pitch] = []
			child_particles[pitch].append(child)

func stop_particle(pitch):
	if pitch in active_particles:
		var particle_instance = active_particles[pitch]
		particle_instance.emitting = false
		
		var parent_timer = Timer.new()
		parent_timer.one_shot = true
		parent_timer.wait_time = particle_instance.lifetime
		parent_timer.connect("timeout", Callable(self, "_remove_particle_instance").bind(particle_instance))
		add_child(parent_timer)
		parent_timer.start()
		
		if pitch in child_particles:
			for child in child_particles[pitch]:
				child.emitting = false
				var child_timer = Timer.new()
				child_timer.one_shot = true
				child_timer.wait_time = child.lifetime
				child_timer.connect("timeout", Callable(self, "_remove_particle_instance").bind(child))
				add_child(child_timer)
				child_timer.start()
			
		active_particles.erase(pitch)
		child_particles.erase(pitch)


func _remove_particle_instance(particle_instance):
	if particle_instance and particle_instance.get_parent():
		particle_instance.queue_free()
