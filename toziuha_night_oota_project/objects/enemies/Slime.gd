extends KinematicBody2D

var id = "slime"

var hp_max = Vars.enemy[id]["hp_max"]
var hp_now = hp_max

#velocidad de movimiento
var velocity = Vector2()
#direcion en x o y
var direction = Vector2()

var facing = -1

export var gravity = 600
export var speed = 20

var state = "idle"

var player = null

var list_items = ["none","none","none","none","money_1","money_1","money_1","money_1","money_1","money_10"]

#establecer hacia donde mira el enemigo
#dependiendo de posicion de jugador (debe verlo de frente
func check_player_position():
	if state == "dead":
		return
	if player != null:
		if player.global_position.x > global_position.x:
			change_dir(1)
		else:
			change_dir(-1)
	if state == "idle":
		change_state("walk")

func _ready():
	
	#obtener al jugador
	player = get_tree().get_nodes_in_group("player")

	#si no se ha agredado un solo jugador...
	if player.size() == 1:
		#get the player's node
		player = player[0]
	else:
		player = null
		
	check_player_position()
	
	randomize()
	list_items.shuffle()
	
	set_physics_process(false)
	
	change_state("idle")

func _physics_process(delta):

	
	if state=="walk":
		velocity.x = speed*facing
		
	#gravedad
	velocity.y += gravity*delta
	
	velocity = move_and_slide(velocity, Vector2.UP)
	
	if is_on_wall():
		change_dir(0)

	#-------------- deteccion de colisiones ----------------------
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if collision.collider.is_in_group("player"):
			collision.collider.hurt(id,position)
				


func change_state(new_state):
	if state != new_state:
		$AnimationPlayer.play(new_state)
		state = new_state


func hurt(damage,weapon_position):
	if $TimerHurt.get_time_left() == 0:
		$Sprite.modulate = Color(1,0,0,1)
		velocity.x = 0
		change_state("idle")
		$TimerHurt.start()
		Audio.play_sfx("hit2")
				
		#damage calcule
		#reducir damage gracias a defensa
		damage = Functions.get_value(damage,"-",Vars.enemy[id]["def"])
		hp_now -= damage
		
		var indicator_position = Vector2(global_position.x,weapon_position.y)
		Functions.show_damage_indicator(damage,indicator_position,"red")
		
		if hp_now <= 0:
			die()

func change_dir(dir):
	var new_facing = dir
	#un valor 0 significa que solo se quiere el facing contrario
	if dir == 0:
		if facing == 1:
			new_facing = -1
		else:
			new_facing = 1
	facing = new_facing
	$Sprite.scale.x = facing
	
func die():
	Audio.play_sfx("hit3")
	velocity.x = 0
	#spawnear item como recompensa
	Functions.spawn_drop_item(list_items[0],position)
	Functions.show_hud_notif(tr(Vars.enemy[id]["name"]))
	set_collision_mask_bit(0,false)
	set_collision_mask_bit(4,false)
	set_collision_layer_bit(2,false)
	change_state("dead")


func _on_VisibilityNotifier2D_screen_entered():
	set_physics_process(true)
	if state != "dead":
		check_player_position()
		change_state("walk")

func _on_VisibilityNotifier2D_screen_exited():
	set_physics_process(false)
	if state != "dead":
		change_state("idle")


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "dead":
		queue_free()


func _on_TimerHurt_timeout():
	$Sprite.modulate = Color(1,1,1,1)
	if state != "dead":
		change_state("walk")