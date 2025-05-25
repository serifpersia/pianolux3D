extends Node3D

@export var note_on_white_key_particles_material : StandardMaterial3D
@export var particle_scene : PackedScene

@onready var midi_keyboard: Node3D = $"../MIDI_Keyboard"

var active_particles = {}
var child_particles = {}
var active_timers = {}

func spawn_particle(pitch):
	if not particle_scene or not Global.particles_state:
		return
		
	var particle_instance = particle_scene.instantiate()
	var is_black = midi_keyboard.is_black_key(pitch)
	var note_mesh := midi_keyboard.get_node(str(pitch))
	
	var note_mesh_y = note_mesh.position.y
	
	particle_instance.position = Vector3(note_mesh.position.x, note_mesh_y, note_mesh.position.z)
	particle_instance.scale = Vector3(0.025, 0.025, 0.025)

	note_on_white_key_particles_material.emission = (
		midi_keyboard.black_note_mesh_color if is_black 
		else midi_keyboard.white_note_mesh_color
	)

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
		parent_timer.connect("timeout", _on_particle_timer_timeout.bind(particle_instance, parent_timer))
		add_child(parent_timer)
		parent_timer.start()
		
		if not active_timers.has(pitch):
			active_timers[pitch] = []
		active_timers[pitch].append(parent_timer)
		
		if pitch in child_particles:
			for child in child_particles[pitch]:
				child.emitting = false
				var child_timer = Timer.new()
				child_timer.one_shot = true
				child_timer.wait_time = child.lifetime
				child_timer.connect("timeout", _on_particle_timer_timeout.bind(child, child_timer))
				add_child(child_timer)
				child_timer.start()
				active_timers[pitch].append(child_timer)
			
		active_particles.erase(pitch)
		child_particles.erase(pitch)

func _on_particle_timer_timeout(particle_instance, timer):
	if particle_instance and is_instance_valid(particle_instance) and particle_instance.get_parent():
		particle_instance.queue_free()

	if timer and is_instance_valid(timer) and timer.get_parent():
		timer.queue_free()

	for pitch in active_timers.keys():
		if timer in active_timers[pitch]:
			active_timers[pitch].erase(timer)
			if active_timers[pitch].is_empty():
				active_timers.erase(pitch)
			break
