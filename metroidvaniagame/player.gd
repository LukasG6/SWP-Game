extends CharacterBody2D

var speed := 200
var gravity := 900
var jump_force := 450       # <-- Sprungkraft
var facing_right := true    # Blickrichtung merken
var attack_duration := 0.2  # Dauer, wie lange die Hitbox aktiv ist
var attacking := false
var attack_timer := 0.0

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

	# Hitbox aktivieren
	$"Player/AttackHitbox2D".disabled = false

	# Offset HIER definieren
	var offset := Vector2(30, 0)

	if facing_right:
		$"Player/AttackHitbox2D".position = offset
	else:
		$"Player/AttackHitbox2D".position = -offset



func stop_attack():
	attacking = false
	$"Player/AttackHitbox2D".disabled = true  # <-- RICHTIGER NAME


func _on_AttackHitbox2D_body_entered(body: Node) -> void:
	print("Getroffen: ", body.name)
	# Hier kannst du body.take_damage() o.ä. aufrufen
