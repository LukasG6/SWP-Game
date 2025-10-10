extends CharacterBody2D

var speed := 200
var gravity := 900
var jump_force := 450
var facing_right := true
var attack_duration := 0.2
var attacking := false
var attack_timer := 0.0

var max_jumps := 2
var jumps_done := 0

# --- Dash-Variablen ---
var dash_speed := 600
var dash_time := 0.2
var dash_cooldown := 1.0
var dashing := false
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_direction := Vector2.ZERO

@onready var attack_sprite = $AttackSprite


func _physics_process(delta):
	var input_dir := Input.get_axis("ui_left", "ui_right")

	# --- Dash Cooldown ---
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# --- Dash aktiv ---
	if dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			dashing = false
			# cooldown läuft weiter, wird ggf. durch Boden zurückgesetzt
		else:
			velocity = dash_direction * dash_speed
			move_and_slide()
			return  # normale Bewegung während Dash verhindern

	# --- Bewegung links/rechts ---
	velocity.x = input_dir * speed

	# --- Gravitation ---
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = max(velocity.y, 0)
		jumps_done = 0  # Doppelsprung zurücksetzen
		dashing = false  # Dash zurücksetzen
		dash_cooldown_timer = 0  # Dash sofort wieder verfügbar

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
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0 and not dashing:
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


func _on_AttackHitbox2D_body_entered(body: Node) -> void:
	print("Getroffen: ", body.name)


func _draw():
	if attacking:
		draw_circle($AttackHitbox2D.position, 20, Color.RED)


func show_attack_sprite(attack_dir: Vector2):
	var distance := 30
	attack_sprite.visible = true

	if attack_dir == Vector2.UP:
		attack_sprite.flip_h = false
		attack_sprite.position = Vector2(0, -distance)
	elif attack_dir == Vector2.DOWN:
		attack_sprite.flip_h = false
		attack_sprite.position = Vector2(0, distance)
	else:
		if attack_dir == Vector2.RIGHT:
			facing_right = true
			attack_sprite.flip_h = false
			attack_sprite.position = Vector2(distance, 0)
		else:
			facing_right = false
			attack_sprite.flip_h = true
			attack_sprite.position = Vector2(-distance, 0)

	await get_tree().create_timer(attack_duration).timeout
	attack_sprite.visible = false


func start_dash():
	dashing = true
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

	print("Dash gestartet in Richtung:", dash_direction)
