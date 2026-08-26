package his_only_son

import "core:log"
import k2 "karl2d"
import "myvendor:tiled"
import "core:mem"
import "core:fmt"
import "core:math/linalg"
import "core:math"

ZOOM :: 4
SCREEN_WIDTH :: 240
SCREEN_HEIGHT :: 180
VW :: f32(SCREEN_WIDTH)/100
VH :: f32(SCREEN_HEIGHT)/100

debug_positions := false
debug_animations := false
debug_drawing_queue := false
debug_collisions := false
debug_interactions := false
debug_with_mouse := true
debug_audio := false
debug_aggression := false

BG_COLOR :: k2.Color{0x0f,0x11,0x1d,0xff} // 0f111d

Vec2 :: k2.Vec2
Rect :: k2.Rect

logger: log.Logger

World :: struct {
	arena: mem.Arena,
	arena_allocator: mem.Allocator,
	arena_buffer: []byte,

	audio: Audio,

	maps: [1]tiled.Map,
	current_map_idx: int,
	tile_textures: [1]k2.Texture,
	textures: [Texture_Kind]k2.Texture,
	game_camera: k2.Camera,
	game_camera_world_rect: Rect,
	ui_camera: k2.Camera,
	player: Player,
	scenes: [dynamic; 5]Scene,
	drawing_queue: Drawing_Queue,
	should_quit: bool,
}
w: World
world_init :: proc(world: ^World) {
	world.arena_buffer = make([]byte, 20000)
	arena: mem.Arena
	mem.arena_init(&arena, world.arena_buffer[:])
	world.arena = arena
	world.arena_allocator = mem.arena_allocator(&world.arena)
}
world_destroy :: proc(world: ^World) {
	free_all(world.arena_allocator)
	delete(world.arena_buffer)
}

Direction :: enum { East, West, North, South }

PLAYER_INVULNERABILITY_TIME :: 3
PLAYER_INVULNERABILITY_BLINKING_PERIOD :: 0.3
Player :: struct {
	pos: Vec2,
	size: Vec2,
	dir: Direction,
	speed: f32,
	is_moving: bool,
	animation_dt_idle: f32,
	animation_dt_walk: f32,
	active_interactable: ^Interactable,
	invulnerability_timer: f32,

	gold: int,
	health: int,
}
player_endure_enemy_aggression :: proc(player: ^Player, enemies: []Enemy) {
	if player.invulnerability_timer > 0 do return

	for enemy in enemies {
		if k2.rect_overlapping(player_collision_rect(player^), enemy->collision_rect_fun()) {
			player_take_damage(player, enemy.attack_power)
			if debug_aggression do log.debugf("Player collided with enemy: %v", enemy)
			break
		}
	}
}
player_take_damage :: proc(player: ^Player, damage: int) {
	if player.invulnerability_timer > 0 do return
	player.invulnerability_timer = PLAYER_INVULNERABILITY_TIME
	player.health -= damage
	sound_play(.Male_Pain)
	if debug_aggression do log.debugf("Player took %v damage", damage)
}
player_count_invulnerability_time :: proc(player: ^Player, dt: f32) {
	if player.invulnerability_timer > 0 {
		player.invulnerability_timer = math.max(player.invulnerability_timer-dt, 0)
	}
}
player_draw :: proc(player: Player) {
	dont_draw := false
	if player.invulnerability_timer > 0 {
		if int(math.trunc(player.invulnerability_timer / PLAYER_INVULNERABILITY_BLINKING_PERIOD)) % 2 != 0 {
			dont_draw = true
		}
	}

	if dont_draw do return

	player_pos := player.pos - {0,16}
	if player.is_moving {
		src_rect: Rect
		switch player.dir {
		case .East: src_rect = {0,0,16,16}
		case .West: src_rect = {0,0,-16,16}
		case .North: src_rect = {0,16,16,16}
		case .South: src_rect = {0,32,16,16}
		}
		// +1 because first walk frame is the same as idle frame,
		// hero moves but no animation starts playing
		src_rect.x = f32(int(player.animation_dt_walk*player.speed/8 + 1) % 4) * TILE_WIDTH
		drawing_queue_add({&w.textures[.Player_Walk], src_rect, player_pos})
	} else {
		src_rect: Rect
		switch player.dir {
		case .East: src_rect = {0,0,16,16}
		case .West: src_rect = {0,0,-16,16}
		case .North: src_rect = {0,16,16,16}
		case .South: src_rect = {0,32,16,16}
		}

		// Play animation only sometimes.
		if int(player.animation_dt_idle) % 7 == 5 {
			// Truncate the whole part of `animation_dt_idle` so that
			// animation always starts at the first frame.
			src_rect.x = f32(int((player.animation_dt_idle - math.trunc(player.animation_dt_idle))*6) % 5) * TILE_WIDTH
		}
		drawing_queue_add({&w.textures[.Player_Idle], src_rect, player_pos})
	}
}
player_rect :: proc(player: Player) -> Rect {
	return k2.rect_from_pos_size(player.pos - {0,player.size.y}, player.size)
}
player_collision_rect :: proc(player: Player) -> Rect {
	return k2.rect_from_pos_size(player.pos + {3,-player.size.y/2}, {player.size.x-6, player.size.y/2})
}
player_point :: proc(player: Player) -> Vec2 {
	return player.pos + {player.size.x/2, -player.size.y/2 + 3}
}
player_draw_debug_info :: proc(player: Player) {
	if debug_animations {
		k2.draw_text(fmt.tprintf("is_moving: %v\nanim_dt_walk: %v\nanim_dt_idle: %v", player.is_moving, player.animation_dt_walk, player.animation_dt_idle), player.pos + {0,-player.size.y - 16}, 4, k2.WHITE)
	}
	if debug_positions {
		k2.draw_text(fmt.tprintf("pos: (%v,  %v)", player.pos.x, player.pos.y), player.pos + {0,-player.size.y-8}, 4, k2.WHITE)
	}
	if debug_collisions {
		k2.draw_rect_outline(player_collision_rect(player), 0.5, k2.MAGENTA)
	}
	if debug_interactions {
		k2.draw_circle(player_point(player), 1, k2.YELLOW)
	}
}
player_set_active_interactable :: proc(player: ^Player, interactables: []Interactable) {
	if len(interactables) == 0 {
		player.active_interactable = nil
		return
	}
	closest_active_interactable := &interactables[0]
	pp := player_point(player^)
	closest_distance := linalg.length(interactable_point(closest_active_interactable^) - pp)
	for &interactable in interactables {
		new_distance := linalg.length(interactable_point(interactable) - pp)
		if new_distance < closest_distance {
			closest_active_interactable = &interactable
			closest_distance = new_distance
		}
	}

	if closest_distance < INTERACTABLE_REACH_PIXELS {
		player.active_interactable = closest_active_interactable
	} else {
		player.active_interactable = nil
	}
}

Scene :: union { Scene_Starting_Screen, Scene_Game_Over, Scene_Room }
Scene_Room :: struct {
	room: Room,
}
scene_room_load_first :: proc() -> Scene_Room {
	room := load_current_room(w.maps[w.current_map_idx])
	return {room=room}
}
Scene_Game_Over :: struct {
	state: Scene_Game_Over_State,
}
Scene_Game_Over_State :: enum { Won, Lost }
scene_transition :: proc(new_scene: Scene) {
	w.scenes[len(w.scenes)-1] = new_scene
}
scene_stack :: proc(new_scene: Scene) {
	append(&w.scenes, new_scene)
}
scene_game_over_stack :: proc(state: Scene_Game_Over_State) {
	scene_stack(Scene_Game_Over{state=state})
}
scene_check_game_over :: proc() {
	if w.player.health <= 0 do scene_game_over_stack(.Lost)
}

Room :: struct {
	interactables: [dynamic; 32]Interactable,
	colliders: [dynamic; 32]Collider,
	enemies: [dynamic; 32]Enemy,
}
room_debug_report :: proc(room: Room) {
	for enemy in room.enemies {
		log.debugf("Enemy: %v", enemy)
	}
}

INTERACTABLE_REACH_PIXELS :: 13
Interactable :: struct {
	pos: Vec2,
	animation_dt: f32,
	animation_state: Animation_State,
	animation_frame: int,
	animation_frame_max: int,
	animation_speed: f32,

	variant: union { Chest },
}
Chest :: struct {
	state: enum { Closed, Open },
	kind: enum { Golden_Crystals },
	gold_amount: int,
}
Animation_State :: enum { Not_Started, In_Progress, Finished }
interactables_draw :: proc(interactables: []Interactable) {
	src_rect := Rect{0,0,TILE_WIDTH,TILE_HEIGHT}
	skew := Vec2{0,-TILE_HEIGHT}
	for interactable in interactables {
		switch var in interactable.variant {
		case Chest:
			switch var.kind {
			case .Golden_Crystals: src_rect.y = TILE_HEIGHT
			}
			src_rect.x = TILE_WIDTH*f32(interactable.animation_frame)
			drawing_queue_add({&w.textures[.Chest], src_rect, interactable.pos+skew})
		}
	}
}
interactable_point :: proc(interactable: Interactable) -> Vec2 {
	return interactable.pos + {TILE_WIDTH/2, -TILE_HEIGHT/2}
}
interactable_rect :: proc(i: Interactable) -> Rect {
	return Rect{i.pos.x, i.pos.y-TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT}
}
interactables_draw_debug_info :: proc(interactables: []Interactable, player: Player) {
	if debug_interactions {
		for interactable in interactables {
			k2.draw_circle(interactable_point(interactable), 1, k2.LIGHT_YELLOW)
		}

		if player.active_interactable != nil {
			k2.draw_circle(interactable_point(player.active_interactable^), 1, k2.ORANGE)
		}
	}
}
interactable_act :: proc(i: ^Interactable) {
	switch &var in i.variant {
	case Chest:
		if var.state == .Closed {
			var.state = .Open
			sound_play(.Chest_Open)
			if i.animation_state == .Not_Started { i.animation_state = .In_Progress }
			w.player.gold += var.gold_amount
		}
	}
	if debug_interactions {
		log.debugf("interactable acted: %v", i)
	}
}
interactables_animate :: proc(interactables: []Interactable) {
	for &i in interactables {
		switch i.animation_state {
		case .Not_Started:
		case .Finished:
		case .In_Progress:
			if debug_animations {
				log.debugf("interactable animates -- dt: %v, frame: %v, frame_max: %v", i.animation_dt, i.animation_frame, i.animation_frame_max)
			}
			i.animation_dt += k2.get_frame_time()
			i.animation_frame = int(i.animation_dt * i.animation_speed)
			if i.animation_frame >= i.animation_frame_max {
				i.animation_state = .Finished
				i.animation_frame = i.animation_frame_max
				if debug_animations { log.debug("Animation finished") }
			}
		}
	}
}

Collider :: struct {
	rect: Rect,
}
colliders_draw_debug_info :: proc(colliders: []Collider) {
	if debug_collisions {
		for collider in colliders {
			k2.draw_rect_outline(collider.rect, 0.5, k2.PURPLE)
		}
	}
}
colliders_fix_position :: proc(colliders: []Collider, pos, to_move: Vec2, collision_rect: Rect) -> (fixed_position: Vec2, collided: bool) {
	pos := pos
	collision_rect := collision_rect

	pos.x += to_move.x
	collision_rect.x += to_move.x
	for collider in colliders {
		overlap, overlapping := k2.rect_overlap(collision_rect, collider.rect)
		if overlapping && overlap.w != 0 {
			sign: f32 = to_move.x >= 0 ? -1 : +1
			fix := (overlap.w + 0.001) * sign
			pos.x += fix
			collision_rect.x += fix
			collided = true
		}
	}

	pos.y += to_move.y
	collision_rect.y += to_move.y
	for collider in colliders {
		overlap, overlapping := k2.rect_overlap(collision_rect, collider.rect)
		if overlapping && overlap.h != 0 {
			sign: f32 = to_move.y >= 0 ? -1 : +1
			fix := (overlap.h + 0.001) * sign
			pos.y += fix
			collision_rect.y += fix
			collided = true
		}
	}
	fixed_position = pos
	return
}

Enemy_Animation :: struct {
	idle_time: f32,
	walk_time: f32,
	speed: f32,
	frame: int,
	idle_frame_max: int,
	walk_frame_max: int,
}

Enemy :: struct {
	pos: Vec2,
	velocity: Vec2,
	attack_power: int,
	script_fun: proc(self: ^Enemy, dt: f32, room: ^Room),
	is_moving: bool,
	animation: Enemy_Animation,
	dir: Direction,
	collision_rect_fun: proc(self: Enemy) -> Rect,
	existed_time: f32, // how much time the instance exists
	no_actions_time: f32, // how much time there were no actions taken
	next_action_in: f32, // how much time should pass for no_actions_time for an action to happen

	variant: union{Slime},
}
Slime :: struct {
	kind: Slime_Kind,
}
Slime_Kind :: enum{Green}
slime_init_from_object :: proc(object: tiled.Object) -> Enemy {
	kind: Slime_Kind
	switch object.type {
	case "green_slime": kind = .Green
	}
	collision_rect_fun :: proc(self: Enemy) -> Rect {
		return Rect{self.pos.x+2, self.pos.y-TILE_HEIGHT+8, TILE_WIDTH-2, TILE_HEIGHT-8}
	}
	return Enemy{pos={f32(object.x), f32(object.y)}, attack_power=1,
		variant=Slime{kind=kind}, script_fun=green_slime_script_fun,
		animation={speed=6, idle_frame_max=4, walk_frame_max=8}, collision_rect_fun=collision_rect_fun,
		velocity={0,-5}, next_action_in=5}
}
enemies_update :: proc(enemies: []Enemy, dt: f32, room: ^Room) {
	for &enemy in enemies {
		if enemy.script_fun != nil {
			enemy->script_fun(dt, room)
		}
	}
}
enemies_draw :: proc(enemies: []Enemy) {
	skew := Vec2{0,-TILE_HEIGHT}
	for enemy in enemies {
		src_rect: Rect
		tex: ^k2.Texture
		switch var in enemy.variant {
		case Slime:
			switch var.kind {
			case .Green:
				if enemy.is_moving {
					tex = &w.textures[.Green_Slime_Walk]
				} else {
					tex = &w.textures[.Green_Slime_Idle]
				}
			}
		}
		switch enemy.dir {
		case .East: src_rect = {0,0,16,16}
		case .West: src_rect = {0,0,-16,16}
		case .North: src_rect = {0,16,16,16}
		case .South: src_rect = {0,32,16,16}
		}
		frame_max := enemy.animation.walk_frame_max if enemy.is_moving else enemy.animation.idle_frame_max
		if enemy.is_moving  {
			src_rect.x = TILE_WIDTH * f32(int(enemy.animation.walk_time*enemy.animation.speed + 1) % frame_max)
		} else {
			if int(enemy.animation.idle_time) % 7 == 6 {
				src_rect.x = f32(int((enemy.animation.idle_time - math.trunc(enemy.animation.idle_time))*6) % frame_max) * TILE_WIDTH
			}
		}
		drawing_queue_add({tex, src_rect, enemy.pos+skew})
	}
}
enemies_draw_debug_info :: proc(enemies: []Enemy) {
	for enemy in enemies {
		if debug_collisions {
			k2.draw_rect_outline(enemy->collision_rect_fun(), 0.5, k2.PURPLE)
		}
		if debug_animations {
			k2.draw_text(fmt.tprintf("is_moving: %v\nidle_time: %v\nwalk_time: %v",
				enemy.is_moving, enemy.animation.idle_time,
				enemy.animation.walk_time), enemy.pos + {0,-20}, 4, k2.WHITE)
		}
	}
}

draw_ui :: proc() {
	k2.draw_text(fmt.tprintf("Gold: %d", w.player.gold), {5, 165}, 8, k2.YELLOW)
	for heart_no in 1..<w.player.health+1 {
		k2.draw_texture(w.textures[.Heart], {SCREEN_WIDTH-20*f32(heart_no),SCREEN_HEIGHT-20})
	}
}

process_input_in_room :: proc(room: ^Room) {
	movement: Vec2

	if k2.key_is_held(.Up) {
		movement.y -= 1
	}
	if k2.key_is_held(.Down) {
		movement.y += 1
	}
	if k2.key_is_held(.Left) {
		movement.x -= 1
	}
	if k2.key_is_held(.Right) {
		movement.x += 1
	}

	movement = linalg.normalize0(movement)

	w.player.is_moving = movement.x != 0 || movement.y != 0

	if movement.x > 0 {
		w.player.dir = .East
	} else if movement.x < 0 {
		w.player.dir = .West
	} else if movement.y > 0 {
		w.player.dir = .South
	} else if movement.y < 0 {
		w.player.dir = .North
	}

	dt := k2.get_frame_time()
	to_move := movement * dt * w.player.speed
	fixed_position, collided := colliders_fix_position(room.colliders[:], w.player.pos, to_move, player_collision_rect(w.player))
	w.player.pos = fixed_position

	if k2.key_went_down(.Space) {
		if w.player.active_interactable != nil {
			interactable_act(w.player.active_interactable)
		}
	}

	if k2.key_went_down(.M) {
		if w.audio.playing {
			if debug_audio { log.debug("Pausing audio") }
			audio_pause()
		} else {
			if debug_audio { log.debug("Playing audio") }
			audio_play()
		}
	}

	if debug_with_mouse && k2.mouse_button_went_down(.Left) {
		screen_pos := k2.get_mouse_position()
		world_pos := k2.screen_to_world(screen_pos, w.game_camera)
		if k2.point_in_rect(world_pos, player_rect(w.player)) {
			log.debugf("Clicked on player: %v", w.player)
		}
		for i in room.interactables {
			if k2.point_in_rect(world_pos, interactable_rect(i)) {
				log.debugf("Clicked on interactable: %v", i)
			}
		}
	}

	if k2.key_went_down(.X) {
		room_debug_report(room^)
	}
}

main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)
	}

	init()
	for step() {}
	shutdown()

	when ODIN_DEBUG {
		if len(track.allocation_map) > 0 {
			fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
			for _, entry in track.allocation_map {
				fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
			}
		}
		mem.tracking_allocator_destroy(&track)
	}
}

init :: proc() {
	logger = log.create_console_logger()
	context.logger = logger
	world_init(&w)

	k2.init(SCREEN_WIDTH*ZOOM, SCREEN_HEIGHT*ZOOM, "His only Son [windowed]", {window_mode=.Windowed_Resizable})
	load_textures()
	load_maps()
	starting_screen := scene_starting_screen_init()
	append(&w.scenes, starting_screen)
	scene_transition(scene_room_load_first())
	w.player.speed = 50
	w.player.size = {16,16}
	w.player.health = 3
	if debug_with_mouse { k2.set_cursor_visible(true) }
	audio_load()
}

scene_room_step :: proc(scene: ^Scene_Room, dt: f32) {
	room := &scene.room

	if w.player.is_moving {
		w.player.animation_dt_idle = 0
		w.player.animation_dt_walk += k2.get_frame_time()
	} else {
		w.player.animation_dt_idle += k2.get_frame_time()
		w.player.animation_dt_walk = 0
	}
	interactables_animate(room.interactables[:])

	process_input_in_room(room)
	player_set_active_interactable(&w.player, room.interactables[:])
	enemies_update(room.enemies[:], dt, room)
	player_endure_enemy_aggression(&w.player, room.enemies[:])
	player_count_invulnerability_time(&w.player, dt)

	scene_check_game_over()

	{
		w.game_camera = {
			zoom = f32(k2.get_screen_height()) / SCREEN_HEIGHT,
			target = w.player.pos + {TILE_WIDTH/2,-TILE_HEIGHT/2},
			offset = {f32(k2.get_screen_width())/2, f32(k2.get_screen_height())/2},
		}
		game_camera_world_matrix := k2.camera_world_matrix(w.game_camera)
		top_left := (game_camera_world_matrix * k2.Vec4{0,0,0,1}).xy
		bottom_right := (game_camera_world_matrix * k2.Vec4{SCREEN_WIDTH*w.game_camera.zoom, SCREEN_HEIGHT*w.game_camera.zoom, 0, 1}).xy
		w.game_camera_world_rect = Rect{
			top_left.x, top_left.y,
			bottom_right.x - top_left.x,
			bottom_right.y - top_left.y,
		}
	}

	w.ui_camera = {
		zoom = f32(k2.get_screen_height()) / SCREEN_HEIGHT,
	}
	k2.set_scissor_rect(Rect{
		0, 0,
		SCREEN_WIDTH*w.game_camera.zoom,
		SCREEN_HEIGHT*w.game_camera.zoom,
	})
	k2.set_camera(w.game_camera)

	k2.clear(BG_COLOR)
	draw_map(w.maps[w.current_map_idx])
	interactables_draw(room.interactables[:])
	enemies_draw(room.enemies[:])
	player_draw(w.player)
	drawing_queue_draw(&w.drawing_queue, w.game_camera)

	colliders_draw_debug_info(room.colliders[:])
	enemies_draw_debug_info(room.enemies[:])
	player_draw_debug_info(w.player)
	interactables_draw_debug_info(room.interactables[:], w.player)

	k2.set_camera(w.ui_camera)
	draw_ui()
	drawing_queue_draw_debug_info(w.drawing_queue)
	k2.present()
}

scene_game_over_step :: proc(scene: ^Scene_Game_Over, dt: f32) {
	room := w.scenes[len(w.scenes)-2].(Scene_Room).room

	k2.clear(BG_COLOR)
	k2.set_camera(w.game_camera)
	draw_map(w.maps[w.current_map_idx])
	interactables_draw(room.interactables[:])
	enemies_draw(room.enemies[:])
	player_draw(w.player)
	drawing_queue_draw(&w.drawing_queue, w.game_camera)

	k2.set_camera(w.ui_camera)
	draw_ui()
	k2.draw_text("YOU LOST", {10,10}, 10, k2.WHITE)
	k2.present()
}

step :: proc() -> bool {
	context.logger = logger
	free_all(context.temp_allocator)

	if !k2.update() do return false
	if w.should_quit do return false

	dt := k2.get_frame_time()

	if !w.audio.first_time_inited {
//		audio_play()
		w.audio.first_time_inited = true
	}
	audio_update()

	switch &sc in w.scenes[len(w.scenes)-1] {
	case Scene_Room: scene_room_step(&sc, dt)
	case Scene_Starting_Screen: scene_starting_screen_step(&sc, dt)
	case Scene_Game_Over: scene_game_over_step(&sc, dt)
	}

	return true
}

shutdown :: proc() {
	context.logger = logger

	unload_textures()
	audio_destroy()
	k2.shutdown()
	log.destroy_console_logger(logger)
	world_destroy(&w)
}
