extends CharacterBody2D

# --- Bewegungsvariablen ---
var speed := 200
var gravity := 900
var jump_force := 450
var facing_right := true

# --- Angriff ---
var attack_duration := 0.2
var attacking := false
var attack_timer := 0.0

# --- Sprung ---
var max_jumps := 2
var jumps_done := 0

# --- Dash ---
var dash_speed := 600
var dash_time := 0.2
var dashing := false
var dash_timer := 0.0
var dash_direction := Vector2.ZERO
var can_dash := true

# --- Nodes ---
@onready var attack_sprite = $AttackSprite
@onready var dash_sprite = $DashSprite   # <-- dein Dash-Sprite (füge es in der Szene hinzu!)

func _physics_process(delta):
	var input_dir := Input.get_axis("ui_left", "ui_right")

	# --- Dash aktiv ---
	if dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			dashing = false
			dash_sprite.visible = false
		else:
			velocity = dash_direction * dash_speed
			move_and_slide()
			return  # verhindert normale Bewegung während Dash

	# --- Bewegung links/rechts ---
	velocity.x = input_dir * speed

	# --- Gravitation ---
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = max(velocity.y, 0)
		jumps_done = 0
		can_dash = true  # Dash beim Bodenkontakt zurücksetzen

	# --- Springen & Doppelsprung ---
	if Input.is_action_just_pressed("ui_accept") and jumps_done < max_jumps:
		velocity.y = -jump_force
		jumps_done += 1

	move_and_slide()

	# --- Blickrichtung merken ---
	if input_dir != 0:
		facing_right = input_dir > 0

	# --- Angriff starten ---
	if Input.is_action_just_pressed("attack") and not attacking:
		start_attack()

	# --- Angriffstimer ---
	if attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			stop_attack()

	# --- Dash starten ---
	if Input.is_action_just_pressed("dash") and can_dash and not dashing:
		start_dash()

func start_attack():
	attacking = true
	attack_timer = attack_duration
	$AttackHitbox2D/CollisionShape2D.disabled = false
	$AttackHitbox2D/ColorRect.visible = true

	var offset := Vector2.ZERO
	var distance := 60

	# --- Richtung bestimmen ---
	var attack_dir := Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		attack_dir = Vector2.UP
	elif Input.is_action_pressed("ui_down"):
		attack_dir = Vector2.DOWN
	elif Input.is_action_pressed("ui_right"):
		attack_dir = Vector2.RIGHT
	elif Input.is_action_pressed("ui_left"):
		attack_dir = Vector2.LEFT
	else:
		attack_dir = Vector2.RIGHT if facing_right else Vector2.LEFT

	offset = attack_dir * distance
	$AttackHitbox2D.position = offset

	show_attack_sprite(attack_dir)


func stop_attack():
	attacking = false
	$AttackHitbox2D/CollisionShape2D.disabled = true
	$AttackHitbox2D/ColorRect.visible = false


func show_attack_sprite(attack_dir: Vector2):
	var distance := 30
	attack_sprite.visible = true

	if attack_dir == Vector2.UP:
		attack_sprite.position = Vector2(0, -distance)
		attack_sprite.rotation_degrees = -90
		attack_sprite.flip_h = false

	elif attack_dir == Vector2.DOWN:
		attack_sprite.position = Vector2(0, distance)
		attack_sprite.rotation_degrees = 90
		attack_sprite.flip_h = false

	else:
		if attack_dir == Vector2.RIGHT:
			facing_right = true
			attack_sprite.flip_h = false
			attack_sprite.position = Vector2(distance, 0)
			attack_sprite.rotation_degrees = 0
		else:
			facing_right = false
			attack_sprite.flip_h = true
			attack_sprite.position = Vector2(-distance, 0)
			attack_sprite.rotation_degrees = 0

	await get_tree().create_timer(attack_duration).timeout
	attack_sprite.visible = false


func start_dash():
	dashing = true
	can_dash = false  # Dash nur einmal bis Bodenkontakt
	dash_timer = dash_time

	if Input.is_action_pressed("ui_up"):
		dash_direction = Vector2.UP
	elif Input.is_action_pressed("ui_down"):
		dash_direction = Vector2.DOWN
	elif Input.is_action_pressed("ui_right"):
		dash_direction = Vector2.RIGHT
	elif Input.is_action_pressed("ui_left"):
		dash_direction = Vector2.LEFT
	else:
		dash_direction = Vector2.RIGHT if facing_right else Vector2.LEFT

	show_dash_sprite()
	print("Dash gestartet in Richtung:", dash_direction)


func show_dash_sprite():
	dash_sprite.visible = true
	dash_sprite.position = Vector2.ZERO
	dash_sprite.flip_v = false
	dash_sprite.rotation_degrees = 0

	# --- Grundrotation & Spiegelung ---
	if dash_direction == Vector2.UP:
		dash_sprite.rotation_degrees = 90
	elif dash_direction == Vector2.DOWN:
		dash_sprite.rotation_degrees = -90
	elif dash_direction == Vector2.LEFT:
		dash_sprite.flip_h = true
	elif dash_direction == Vector2.RIGHT:
		dash_sprite.flip_h = false

	# --- Wenn man nach links schaut, invertiere Vertikalrotation ---
	if not facing_right:
		if dash_direction == Vector2.UP or dash_direction == Vector2.DOWN:
			dash_sprite.rotation_degrees *= -1

	await get_tree().create_timer(dash_time).timeout
	dash_sprite.visible = false

func _on_AttackHitbox2D_body_entered(body: Node) -> void:
	print("Getroffen: ", body.name)

func _draw():
	if attacking:
		draw_circle($AttackHitbox2D.position, 20, Color.RED)
