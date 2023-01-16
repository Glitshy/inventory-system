extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var mouse_sensitivity := 0.002
@export var vertical_angle_limit := 90.0
var rot := Vector3()

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left_move", "right_move", "forward_move", "back_move")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	interact()

# Called when there is an input event
func _input(event: InputEvent) -> void:
	# Mouse look (only if the mouse is captured).
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_camera(event.relative)

func rotate_camera(mouse_axis : Vector2) -> void:
	# Horizontal mouse look.
	rot.y -= mouse_axis.x * mouse_sensitivity
	# Vertical mouse look.
	rot.x = clamp(rot.x - mouse_axis.y * mouse_sensitivity, -vertical_angle_limit, vertical_angle_limit)
	
	rotation.y = rot.y
	$Camera3D.rotation.x = rot.x
	1
func interact():
	var raycast : RayCast3D = $Camera3D/RayCast3D
	if raycast.is_colliding():
		var object = raycast.get_collider()
		var inv = object.get_inventory()
		if inv != null:
			var player_inventory_handler : InventoryHandler = $InventoryHandler
			$"../UI/Labels/InteractMessage".visible = !player_inventory_handler.is_open(inv)
			if Input.is_action_just_pressed("Interact"):
				open_inventory(inv)
			return
	$"../UI/Labels/InteractMessage".visible = false
	
func open_inventory(inventory : Inventory):
	var player_inventory_handler : InventoryHandler = $InventoryHandler
	if not player_inventory_handler.is_open(inventory):
		player_inventory_handler.open(inventory)
	if not player_inventory_handler.is_open_personal_inventory():
		player_inventory_handler.open_personal_inventory()
