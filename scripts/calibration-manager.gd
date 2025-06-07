extends Node

enum ReferenceAxis { X_POSITIVE, Y_POSITIVE, Z_POSITIVE, X_NEGATIVE, Y_NEGATIVE, Z_NEGATIVE }

@export var reference_3d_distance: float = 2.0
@export var reference_axis_direction: ReferenceAxis = ReferenceAxis.X_POSITIVE
@export var reference_point1_idx: int = 0 
@export var reference_point2_idx: int = 1

@onready var fps = $"../SubViewportContainer/SubViewport/FPS"

@onready var calibration_overlay = $"../CalibrationOverlay"

@onready var drag_points := [
	$"../CalibrationOverlay/DragPoint1",
	$"../CalibrationOverlay/DragPoint2",
	$"../CalibrationOverlay/DragPoint3",
	$"../CalibrationOverlay/DragPoint4",
	$"../CalibrationOverlay/DragPoint5",
	$"../CalibrationOverlay/DragPoint6",
	$"../CalibrationOverlay/DragPoint7",
	$"../CalibrationOverlay/DragPoint8"
]

const EPSILON = 1e-5
const DETERMINANT_TOLERANCE = EPSILON * 1000 

func _ready():
	for point in drag_points:
		point.position_changed.connect(_on_drag_point_moved)

func _on_drag_point_moved():
	_on_calibrate_pressed()

func _on_calibrate_pressed():
	var viewport_size = get_viewport().get_visible_rect().size
	var principal_point = viewport_size / 2.0
	
	if abs(reference_3d_distance) <= EPSILON:
		#push_warning("Reference 3D distance magnitude must be positive.")
		return
	if reference_point1_idx < 0 or reference_point1_idx >= drag_points.size() or \
	   reference_point2_idx < 0 or reference_point2_idx >= drag_points.size() or \
	   reference_point1_idx == reference_point2_idx:
		#push_warning("Invalid reference point indices.")
		return

	var vp_x_gw_img = get_intersection(drag_points[0].position, drag_points[1].position, drag_points[2].position, drag_points[3].position)
	var vp_z_gw_img = get_intersection(drag_points[4].position, drag_points[5].position, drag_points[6].position, drag_points[7].position)

	if vp_x_gw_img == Vector2.INF or vp_z_gw_img == Vector2.INF:
		#push_warning("Could not compute vanishing points for X or Z axes.")
		return

	var focal_length_px = estimate_focal_length_from_vps(vp_x_gw_img, vp_z_gw_img, principal_point)
	if focal_length_px <= EPSILON:
		#push_warning("Invalid focal length estimated: " + str(focal_length_px))
		return
	
	var initial_dir_X_GW_in_Rc = -pixel_to_camera_rc_direction(vp_x_gw_img, focal_length_px, principal_point).normalized()
	var initial_dir_Z_GW_in_Rc = -pixel_to_camera_rc_direction(vp_z_gw_img, focal_length_px, principal_point).normalized() 
	var calculated_dir_Y_GW_in_Rc = initial_dir_X_GW_in_Rc.cross(initial_dir_Z_GW_in_Rc).normalized()
	var final_dir_X_GW_in_Rc = initial_dir_X_GW_in_Rc
	var final_dir_Y_GW_in_Rc = calculated_dir_Y_GW_in_Rc
	final_dir_Y_GW_in_Rc = final_dir_Y_GW_in_Rc - final_dir_X_GW_in_Rc.dot(final_dir_Y_GW_in_Rc) * final_dir_X_GW_in_Rc
	final_dir_Y_GW_in_Rc = final_dir_Y_GW_in_Rc.normalized()
	var final_dir_Z_GW_in_Rc = final_dir_X_GW_in_Rc.cross(final_dir_Y_GW_in_Rc).normalized()
	var R_GodotWorld_to_Rc = Basis(final_dir_X_GW_in_Rc, final_dir_Y_GW_in_Rc, final_dir_Z_GW_in_Rc)

	#if abs(R_GodotWorld_to_Rc.determinant() - 1.0) > DETERMINANT_TOLERANCE:
		#push_warning("Failed to compute valid R_GodotWorld_to_Rc basis. Det: " + str(R_GodotWorld_to_Rc.determinant()))
	
	fps.basis = R_GodotWorld_to_Rc.transposed() * Basis.IDENTITY.scaled(Vector3(1,1,-1))
	fps.get_child(1).fov = rad_to_deg(2.0 * atan(viewport_size.y / (2.0 * focal_length_px)))

	var p1_img = drag_points[reference_point1_idx].position
	var p2_img = drag_points[reference_point2_idx].position
	var v1_rc_unnormalized = pixel_to_camera_rc_direction(p1_img, focal_length_px, principal_point)
	var v2_rc_unnormalized = pixel_to_camera_rc_direction(p2_img, focal_length_px, principal_point)

	if v1_rc_unnormalized.length_squared() < EPSILON or v2_rc_unnormalized.length_squared() < EPSILON:
		#push_warning("Reference image points for position coincide with principal point.")
		return
		
	var v1_rc = v1_rc_unnormalized.normalized()
	var v2_rc = v2_rc_unnormalized.normalized()
	
	var reference_segment_direction_gw : Vector3
	match reference_axis_direction:
		ReferenceAxis.X_POSITIVE: reference_segment_direction_gw = Vector3.RIGHT
		ReferenceAxis.Y_POSITIVE: reference_segment_direction_gw = Vector3.UP
		ReferenceAxis.Z_POSITIVE: reference_segment_direction_gw = Vector3.FORWARD
		ReferenceAxis.X_NEGATIVE: reference_segment_direction_gw = Vector3.LEFT
		ReferenceAxis.Y_NEGATIVE: reference_segment_direction_gw = Vector3.DOWN
		ReferenceAxis.Z_NEGATIVE: reference_segment_direction_gw = Vector3.BACK
	
	var reference_segment_direction_rc = R_GodotWorld_to_Rc * reference_segment_direction_gw
	var s1 : float
	var den = (v1_rc.cross(v2_rc)).y 
	var num = reference_3d_distance * (reference_segment_direction_rc.cross(v2_rc)).y
	
	if abs(den) > EPSILON:
		s1 = num / den 
	else: 
		den = (v1_rc.cross(v2_rc)).z 
		num = reference_3d_distance * (reference_segment_direction_rc.cross(v2_rc)).z
		if abs(den) > EPSILON:
			s1 = num / den
			#push_warning("Used XY plane for position s1 calculation.")
		else:
			#push_warning("Cannot determine depth s1 for P_ref1_GW accurately.")
			return

	if s1 < 0.0:
		#print("INFO: s1 was " + str(s1) + ". Forcing positive, assuming P_ref1_GW is in front of camera.")
		s1 = abs(s1) 
	#elif abs(s1) < EPSILON: 
		#push_warning("Calculated depth s1 for P_ref1_GW ("+str(s1)+") is too small.")
	
	var t_P_ref1_GW_in_Rc = s1 * v1_rc 
	fps.global_position = -(R_GodotWorld_to_Rc.transposed() * t_P_ref1_GW_in_Rc)
	fps.basis = fps.basis.scaled(Vector3(1,1,-1)) 
	fps.global_position.z *= -1.0
	
	#print("--- Calibration Results ---")
	#print("Camera Position (CamOrigin in GW): ", camera_3d.global_position)
	#print("Camera Basis (R_GCF_to_W): ", camera_3d.basis)
	#print("Vertical FOV (deg): ", camera_3d.fov)

func get_intersection(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2) -> Vector2:
	var a1 = p2.y - p1.y; var b1 = p1.x - p2.x; var c1 = a1 * p1.x + b1 * p1.y
	var a2 = p4.y - p3.y; var b2 = p3.x - p4.x; var c2 = a2 * p3.x + b2 * p3.y
	var det = a1 * b2 - a2 * b1
	if abs(det) < EPSILON: return Vector2.INF 
	return Vector2((b2 * c1 - b1 * c2) / det, (a1 * c2 - a2 * c1) / det)

func pixel_to_camera_rc_direction(pixel_coords: Vector2, focal_length: float, principal_point: Vector2) -> Vector3:
	return Vector3(pixel_coords.x - principal_point.x, -(pixel_coords.y - principal_point.y), focal_length)

func estimate_focal_length_from_vps(vp1_img: Vector2, vp2_img: Vector2, principal_point: Vector2) -> float:
	var v1_img_plane_rc_x = vp1_img.x - principal_point.x
	var v1_img_plane_rc_y = -(vp1_img.y - principal_point.y) 
	var v2_img_plane_rc_x = vp2_img.x - principal_point.x
	var v2_img_plane_rc_y = -(vp2_img.y - principal_point.y)
	var f_squared = -(v1_img_plane_rc_x * v2_img_plane_rc_x + v1_img_plane_rc_y * v2_img_plane_rc_y)
	if f_squared <= EPSILON:
		#push_warning("Cannot estimate focal length: f^2 is " + str(f_squared))
		return -1.0 
	return sqrt(f_squared)
