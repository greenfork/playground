package zimawoods

import "core:log"
import k2 "karl2d"

Vec2 :: k2.Vec2
SCREEN_WIDTH :: 240
SCREEN_HEIGHT :: 180
CELL_WIDTH :: 8
CELL_HEIGHT :: 8
CELL_SIZE :: Vec2{CELL_WIDTH, CELL_HEIGHT}

World :: struct {
	player_moved: bool,
}
world: World
world_init :: proc() -> World {
	return World{}
}
world_frame_reset :: proc(w: ^World) {
	w.player_moved = false
}

game_camera: k2.Camera

Entity :: struct {
	id: int,
	pos: Vec2,
	size: Vec2,
	kind: Entity_Kind,
	dir: Direction,
}

Entity_Kind :: enum { Player, Tree }

Entities :: struct {
	last_id: int,
	arr: [dynamic]Entity,
}
entities: Entities
ent_init :: proc() -> Entities {
	entities := Entities{}
	return entities
}
@require_results
ent_add :: proc(ent: ^Entities, entity: Entity) -> Entity {
	id := ent.last_id
	ent.last_id += 1
	e := entity
	e.id = id
	append(&ent.arr, e)
	return e
}
ent_remove :: proc(ent: ^Entities, id: int) {
	idx: int = -1
	for e, i in ent.arr {
		if e.id == id {
			idx = i
			break
		}
	}
	if idx >= 0 {
		unordered_remove(&ent.arr, idx)
	}
}
ent_get_mut :: proc(ent: ^Entities, id: int) -> ^Entity {
	for &e in ent.arr {
		if e.id == id {
			return &e
		}
	}
	return nil
}
ent_draw :: proc(ent: ^Entities) {
	for e in ent.arr {
		entity_draw(e)
	}
}

entity_draw :: proc(e: Entity) {
	k2.draw_rect_vec(e.pos, CELL_SIZE * e.size, k2.BROWN)
}

player: ^Entity
Direction :: enum { Up, Down, Left, Right }
player_textures: [Direction][6]k2.Texture
player_textures_load :: proc() {
	player_textures[.Up] = {
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Up/Zarutska_Run_Up_1.png")),
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Up/Zarutska_Run_Up_2.png")),
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Up/Zarutska_Run_Up_3.png")),
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Up/Zarutska_Run_Up_4.png")),
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Up/Zarutska_Run_Up_5.png")),
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Up/Zarutska_Run_Up_6.png")),
	}
	player_textures[.Down] = {
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Down/Zarutska_Run_Down_1.png")),
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Down/Zarutska_Run_Down_2.png")),
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Down/Zarutska_Run_Down_3.png")),
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Down/Zarutska_Run_Down_4.png")),
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Down/Zarutska_Run_Down_5.png")),
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Down/Zarutska_Run_Down_6.png")),
	}
	player_textures[.Left] = {
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Left/Zarutska_Run_Left_1.png")),
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Left/Zarutska_Run_Left_2.png")),
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Left/Zarutska_Run_Left_3.png")),
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Left/Zarutska_Run_Left_4.png")),
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Left/Zarutska_Run_Left_5.png")),
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Left/Zarutska_Run_Left_6.png")),
	}
	player_textures[.Right] = {
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Right/Zarutska_Run_Right_1.png")),
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Right/Zarutska_Run_Right_2.png")),
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Right/Zarutska_Run_Right_3.png")),
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Right/Zarutska_Run_Right_4.png")),
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Right/Zarutska_Run_Right_5.png")),
		k2.load_texture_from_bytes(#load("assets/hero/character1/Demo/Zarutska_Brejnev/Right/Zarutska_Run_Right_6.png")),
	}
}

main :: proc() {
	context.logger = log.create_console_logger()
	init()
	for step() {}
	shutdown()
}

init :: proc() {
	log.debug("Init!")
	entities = ent_init()
	p := ent_add(&entities, Entity{pos={40,40}, size={2,2}, kind=.Player})
	player = ent_get_mut(&entities, p.id)
	world = world_init()

	k2.init(SCREEN_WIDTH*4, SCREEN_HEIGHT*4, "ZimaWoods [windowed]", {window_mode=.Windowed})
	texture_load_all()
}

process_input :: proc() {
	moved: bool
	if k2.key_went_down(.Left) {
		player.pos -= CELL_SIZE*{1,0}
		moved = true
	}
	if k2.key_went_down(.Right) {
		player.pos += CELL_SIZE*{1,0}
		moved = true
	}
	if k2.key_went_down(.Up) {
		player.pos -= CELL_SIZE*{0,1}
		moved = true
	}
	if k2.key_went_down(.Down) {
		player.pos += CELL_SIZE*{0,1}
		moved = true
	}
	world.player_moved = moved
}

step :: proc() -> bool {
	if !k2.update() {
		return false
	}

	game_camera = {
		zoom = f32(k2.get_screen_height()) / SCREEN_HEIGHT,
	}
	k2.set_scissor_rect(k2.Rect{
		0, 0,
		SCREEN_WIDTH*game_camera.zoom,
		SCREEN_HEIGHT*game_camera.zoom,
	})

	world_frame_reset(&world)

	process_input()

	k2.clear(k2.BLACK)
	k2.set_camera(game_camera)
	tiles_draw()
	ent_draw(&entities)
	k2.present()

	return true
}

shutdown :: proc() {
	log.debug("Shutdown!")
	k2.shutdown()
}
