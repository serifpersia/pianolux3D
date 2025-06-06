extends Node3D

@export var note_on_white_key_particles_material: StandardMaterial3D
@export var particle_scene: PackedScene

@onready var midi_keyboard: Node3D = $"../MIDI_Keyboard"

var active_particles = {}
var child_particles = {}
var active_timers = {}

func spawn_particle(pitch: int) -> void:
	if not particle_scene or not Global.particles_state:
		return
	if midi_keyboard.is_black_key(pitch):
		return

	var particle_instance = particle_scene.instantiate()
	var note_mesh := midi_keyboard.get_node(str(pitch))
	
	particle_instance.position = Vector3(note_mesh.position.x, note_mesh.position.y + 0.015, note_mesh.position.z)

	if particle_instance is GPUParticles3D or particle_instance is CPUParticles3D or particle_instance is MeshInstance3D:
		if note_on_white_key_particles_material:
			var new_material = note_on_white_key_particles_material.duplicate(true) as StandardMaterial3D
			if new_material:
				new_material.albedo_color = midi_keyboard.white_notes_on_mat.albedo_color
				if particle_instance is GPUParticles3D:
					particle_instance.material_override = new_material
				elif particle_instance is CPUParticles3D:
					particle_instance.material = new_material
				elif particle_instance is MeshInstance3D:
					particle_instance.material_override = new_material
	
	add_child(particle_instance)
	if "emitting" in particle_instance:
		particle_instance.emitting = true
	active_particles[pitch] = particle_instance
	
	for child_node in particle_instance.get_children():
		if child_node is GPUParticles3D or child_node is CPUParticles3D or child_node is MeshInstance3D:
			if note_on_white_key_particles_material:
				var new_child_material = note_on_white_key_particles_material.duplicate(true) as StandardMaterial3D
				if new_child_material:
					new_child_material.albedo_color = midi_keyboard.white_note_mesh_color
					if child_node is GPUParticles3D:
						child_node.material_override = new_child_material
		
		if "emitting" in child_node:
			child_node.emitting = true
		
		if not child_particles.has(pitch):
			child_particles[pitch] = []
		child_particles[pitch].append(child_node)

func stop_particle(pitch: int) -> void:
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

func _on_particle_timer_timeout(particle_instance, timer) -> void:
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
