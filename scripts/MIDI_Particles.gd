extends Node3D

@export var particles_material : StandardMaterial3D
@export var particles_flash_material : StandardMaterial3D

@export var particle_scene : PackedScene

@onready var virtual_keyboard = $"../Virtual_Keyboard"

var active_particles = {}
var child_particles = {}

func spawn_particle(pitch):
	if not particle_scene:
		return
		
	if Global.particles_state:
		var particle_instance = particle_scene.instantiate()
		var x_offset = virtual_keyboard.calculate_x_offset(pitch)
		particle_instance.position = Vector3(x_offset - 31.57, -8.5, 0.3)
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
