package his_only_son

import "core:log"
import k2 "karl2d"
import "myvendor:tiled"
import "core:mem"
import "core:fmt"
import "core:math/linalg"
import "core:math"
import vmem "core:mem/virtual"

ZOOM :: 4
SCREEN_WIDTH :: 240
SCREEN_HEIGHT :: 180

debug_anim := false

BG_COLOR :: k2.Color{0x0f,0x11,0x1d,0xff} // 0f111d

Vec2 :: k2.Vec2

logger: log.Logger

World :: struct {
	arena: vmem.Arena,
	arena_allocator: mem.Allocator,
	maps: [1]tiled.Map,
	current_map_idx: int,
	tile_textures: [1]k2.Texture,
	textures: [Texture_Kind]k2.Texture,
	game_camera: k2.Camera,
	player: Player,
	room: Room,
}
w: World
world_init :: proc(world: ^World) {
	arena: vmem.Arena
	arena_err := vmem.arena_init_growing(&arena)
	log.ensuref(arena_err == nil, "Virtual Arena init failed")
	world.arena = arena
	world.arena_allocator = vmem.arena_allocator(&world.arena)
}
world_destroy :: proc(world: ^World) {
	free_all(world.arena_allocator)
}

Texture_Kind :: enum { Chest }
Direction :: enum { East, West, North, South }

Player :: struct {
	pos: Vec2,
	size: Vec2,
	textures_idle: k2.Texture,
	textures_walk: k2.Texture,
	dir: Direction,
	speed: f32,
	is_moving: bool,
	animation_dt_idle: f32,
	animation_dt_walk: f32,
}
player_load_textures :: proc(player: ^Player) {
	player.textures_idle = k2.load_texture_from_bytes(#load("assets/TinyTerrors/Character_Idle.png"))
	player.textures_walk = k2.load_texture_from_bytes(#load("assets/TinyTerrors/Character_Walk.png"))
}
player_draw :: proc(player: Player) {
	player_pos := player.pos - {0,16}
	if player.is_moving {
		src_rect: k2.Rect
		switch player.dir {
		case .East: src_rect = {0,0,16,16}
		case .West: src_rect = {0,0,-16,16}
		case .North: src_rect = {0,16,16,16}
		case .South: src_rect = {0,32,16,16}
		}
		// +1 because first walk frame is the same as idle frame,
		// hero moves but no animation starts playing
		src_rect.x = f32(int(player.animation_dt_walk*player.speed/8 + 1) % 4) * TILE_WIDTH
		k2.draw_texture_rect(player.textures_walk, src_rect, player_pos)
	} else {
		src_rect: k2.Rect
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
			k2.draw_texture_rect(player.textures_idle, src_rect, player_pos)
		} else {
			k2.draw_texture_rect(player.textures_idle, src_rect, player_pos)
		}
	}
}
player_draw_debug_info :: proc(player: Player) {
	if debug_anim {
		k2.draw_text(fmt.tprintf("is_moving: %v\nanim_dt_walk: %v\nanim_dt_idle: %v", player.is_moving, player.animation_dt_walk, player.animation_dt_idle), player.pos + {0,-player.size.y - 16}, 4, k2.WHITE)
	}
}

Room :: struct {
	interactables: [dynamic; 32]Interactable,
}

Interactable :: struct {
	kind: Interactable_Kind,
	pos: Vec2,
}
Interactable_Kind :: enum { Chest }
interactables_draw :: proc(interactables: []Interactable) {
	src_rect := k2.Rect{0,0,TILE_WIDTH,TILE_HEIGHT}
	skew := Vec2{0,-TILE_HEIGHT}
	for interactable in interactables {
		switch interactable.kind {
		case .Chest: k2.draw_texture_rect(w.textures[.Chest], src_rect, interactable.pos+skew)
		}
	}
}

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

	k2.init(SCREEN_WIDTH*ZOOM, SCREEN_HEIGHT*ZOOM, "His only Son [windowed]", {window_mode=.Windowed})
	load_textures()
	load_maps()
	load_current_room(w.maps[w.current_map_idx])
	player_load_textures(&w.player)
	w.player.speed = 50
	w.player.size = {16,16}
}

step :: proc() -> bool {
	context.logger = logger
	free_all(context.temp_allocator)

	if !k2.update() {
		return false
	}

	if w.player.is_moving {
		w.player.animation_dt_idle = 0
		w.player.animation_dt_walk += k2.get_frame_time()
	} else {
		w.player.animation_dt_idle += k2.get_frame_time()
		w.player.animation_dt_walk = 0
	}

	process_input()

	w.game_camera = {
		zoom = f32(k2.get_screen_height()) / SCREEN_HEIGHT,
		target = w.player.pos + {TILE_WIDTH/2,-TILE_HEIGHT/2},
		offset = {f32(k2.get_screen_width())/2, f32(k2.get_screen_height())/2},
	}
	k2.set_scissor_rect(k2.Rect{
		0, 0,
		SCREEN_WIDTH*w.game_camera.zoom,
		SCREEN_HEIGHT*w.game_camera.zoom,
	})
	k2.set_camera(w.game_camera)

	k2.clear(BG_COLOR)
	draw_map(w.maps[w.current_map_idx])
	interactables_draw(w.room.interactables[:])
	player_draw(w.player)
	player_draw_debug_info(w.player)
	k2.present()

	return true
}

shutdown :: proc() {
	context.logger = logger

	unload_textures()
	k2.shutdown()
	log.destroy_console_logger(logger)
	world_destroy(&w)
}
