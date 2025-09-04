extends CharacterBody2D

@export var movement_data: PlayerMovementData

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var air_jump: bool = false
var has_jumped: bool = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var coyote_jump_timer: Timer = $CoyoteJumpTimer
@onready var starting_position: Vector2 = global_position

func _physics_process(delta: float) -> void:
	var direction: float = Input.get_axis("left", "right")

	apply_gravity(delta)
	handle_jump()
	handle_wall_jump()
	handle_acceleration(direction, delta)
	handle_air_acceleration(direction, delta)
	handle_friction(direction, delta)
	apply_air_resistance(direction, delta)
	update_animations(direction)

	# handle coyote jump
	var was_on_floor: bool = is_on_floor()
	move_and_slide()
	var just_left_ledge: bool = was_on_floor and not is_on_floor() and velocity.y >= 0
	if just_left_ledge:
		coyote_jump_timer.start()

	if is_on_floor():
		has_jumped = false

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * movement_data.gravity_scale * delta

func handle_jump() -> void:
	if is_on_floor(): air_jump = true

	if is_on_floor() or coyote_jump_timer.time_left > 0.0 and not has_jumped:
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = movement_data.jump_velocity
			has_jumped = true
	elif not is_on_floor():
		if Input.is_action_just_released("ui_accept") and velocity.y < movement_data.jump_velocity / 2:
			velocity.y = movement_data.jump_velocity / 2
		if Input.is_action_just_pressed("ui_accept") and air_jump:
			velocity.y = movement_data.jump_velocity
			air_jump = false

func handle_wall_jump() -> void:
	if not is_on_wall(): return
	var wall_normal: Vector2 = get_wall_normal()
	if Input.is_action_just_pressed("left") and wall_normal == Vector2.LEFT:
		velocity.x = wall_normal.x * movement_data.speed
		velocity.y = movement_data.jump_velocity
	if Input.is_action_just_pressed("right") and wall_normal == Vector2.RIGHT:
		velocity.x = wall_normal.x * movement_data.speed
		velocity.y = movement_data.jump_velocity

func handle_acceleration(direction: float, delta: float) -> void:
	if not is_on_floor(): return
	if direction != 0:
		velocity.x = move_toward(velocity.x, movement_data.speed * direction, movement_data.acceleration * delta)
	
func handle_air_acceleration(direction: float, delta: float) -> void:
	if is_on_floor(): return
	if direction != 0:
		velocity.x = move_toward(velocity.x, movement_data.speed * direction, movement_data.air_acceleration * delta)

func handle_friction(direction: float, delta: float) -> void:
	if direction == 0 and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, movement_data.friction * delta)

func apply_air_resistance(direction: float, delta: float) -> void:
	if direction == 0 and not is_on_floor():
		velocity.x = move_toward(velocity.x, 0, movement_data.air_resistance * delta)

func update_animations(input_axis: float) -> void:
	if input_axis != 0:
		animated_sprite_2d.flip_h = input_axis < 0
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("idle")

	if not is_on_floor():
		animated_sprite_2d.play("jump")


func _on_hazard_detector_area_entered(area: Area2D) -> void:
		global_position = starting_position
