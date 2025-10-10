extends CharacterBody2D

var speed := 200
var gravity := 900
var jump_force := 450       # <-- Sprungkraft
var facing_right := true    # Blickrichtung merken
var attack_duration := 0.2  # Dauer, wie lange die Hitbox aktiv ist
var attacking := false
var attack_timer := 0.0

@onready var attack_sprite = $AttackSprite


func _physics_process(delta):
	var input_dir := Input.get_axis("ui_left", "ui_right")

	# --- Bewegung links/rechts ---
	velocity.x = input_dir * speed

	# --- Gravitation ---
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = max(velocity.y, 0)

	# --- Springen ---
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = -jump_force

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


func start_attack():
	attacking = true
	attack_timer = attack_duration
	$AttackHitbox2D/CollisionShape2D.disabled = false
	$AttackHitbox2D/ColorRect.visible = true

	var offset := Vector2.ZERO
	var distance := 60  # Abstand der Hitbox vom Spieler – größer für besseres Feedback

	# --- Angriffsrichtung bestimmen ---
	var attack_dir := Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		attack_dir = Vector2.RIGHT
	elif Input.is_action_pressed("ui_left"):
		attack_dir = Vector2.LEFT
	elif Input.is_action_pressed("ui_up"):
		attack_dir = Vector2.UP
	elif Input.is_action_pressed("ui_down"):
		attack_dir = Vector2.DOWN

	if attack_dir == Vector2.ZERO:
		if facing_right:
			attack_dir = Vector2.RIGHT
		else:
			attack_dir = Vector2.LEFT

	# Position der Hitbox setzen
	offset = attack_dir * distance
	$AttackHitbox2D.position = offset

	# --- Angriffssprite anzeigen ---
	show_attack_sprite()


func stop_attack():
	attacking = false
	$AttackHitbox2D/CollisionShape2D.disabled = true
	$AttackHitbox2D/ColorRect.visible = false


func _on_AttackHitbox2D_body_entered(body: Node) -> void:
	print("Getroffen: ", body.name)
	# Hier kannst du body.take_damage() o.ä. aufrufen


func _draw():
	if attacking:
		draw_circle($AttackHitbox2D.position, 20, Color.RED)


func show_attack_sprite():
	# Sprite spiegeln je nach Blickrichtung
	attack_sprite.flip_h = not facing_right

	# Sprite-Position leicht vor dem Spieler setzen
	var distance := 30
	if facing_right:
		attack_sprite.position.x = distance
	else:
		attack_sprite.position.x = -distance

	attack_sprite.position.y = 0

	# Sprite kurz anzeigen
	attack_sprite.visible = true
	await get_tree().create_timer(attack_duration).timeout
	attack_sprite.visible = false
