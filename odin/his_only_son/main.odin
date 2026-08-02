package his_only_son

import "core:log"
import k2 "karl2d"
import "myvendor:tiled"
import "core:mem"
import "core:fmt"
import "core:math/linalg"

ZOOM :: 4
SCREEN_WIDTH :: 240
SCREEN_HEIGHT :: 180

BG_COLOR :: k2.Color{0x0f,0x11,0x1d,0xff} // 0f111d

Vec2 :: k2.Vec2

logger: log.Logger

World :: struct {
	maps: [1]tiled.Map,
	current_map_idx: int,
	textures: [3]k2.Texture,
	game_camera: k2.Camera,
	player: Player,
	room: Room,
}
w: World

Direction :: enum { East, West, North, South }

Player :: struct {
	pos: Vec2,
	textures_idle: k2.Texture,
	dir: Direction,
	speed: f32,
}
player_load_textures :: proc(player: ^Player) {
	player.textures_idle = k2.load_texture_from_bytes(#load("assets/TinyTerrors/Character_Idle.png"))
}
player_draw :: proc(player: Player) {
	src_rect := k2.Rect{0,0,16,16}
	k2.draw_texture_rect(player.textures_idle, src_rect, player.pos - {0,16})
}

Room :: struct {
	interactables: [dynamic; 32]Interactable,
}

Interactable :: struct {
	kind: Interactable_Type,
	pos: Vec2,
}
Interactable_Type :: enum { Chest }

process_input :: proc() {
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
	w.player.pos += to_move
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

	// JSON needs to be freed via arena, otherwise it spams
	// when ODIN_DEBUG {
	// 	if len(track.allocation_map) > 0 {
	// 		fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
	// 		for _, entry in track.allocation_map {
	// 			fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
	// 		}
	// 	}
	// 	mem.tracking_allocator_destroy(&track)
	// }
}

init :: proc() {
	logger = log.create_console_logger()
	context.logger = logger

	k2.init(SCREEN_WIDTH*ZOOM, SCREEN_HEIGHT*ZOOM, "His only Son [windowed]", {window_mode=.Windowed})
	load_textures()
	load_maps()
	load_current_room(w.maps[w.current_map_idx])
	player_load_textures(&w.player)
	w.player.speed = 50
}

step :: proc() -> bool {
	context.logger = logger

	if !k2.update() {
		return false
	}

	process_input()

	w.game_camera = {
		zoom = f32(k2.get_screen_height()) / SCREEN_HEIGHT,
	}
	k2.set_scissor_rect(k2.Rect{
		0, 0,
		SCREEN_WIDTH*w.game_camera.zoom,
		SCREEN_HEIGHT*w.game_camera.zoom,
	})
	k2.set_camera(w.game_camera)

	k2.clear(BG_COLOR)
	draw_map(w.maps[w.current_map_idx])
	player_draw(w.player)
	k2.present()

	return true
}

shutdown :: proc() {
	context.logger = logger

	k2.shutdown()

	log.destroy_console_logger(logger)
}
