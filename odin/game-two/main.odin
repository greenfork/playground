package main

import "core:fmt"
import "core:c"
import "base:runtime"
import sdl "vendor:sdl3"

AppState :: struct {
	window: ^sdl.Window,
	renderer: ^sdl.Renderer,
	input: Input,
	world: World,
}

World :: struct {
	p: Player,
}
world_init :: proc(w: ^World) {
	w.p = player_init()
}

InputKey :: enum { Left, Right, Up, Down }
Input :: struct {
	keys: [InputKey]bool,
	any_key_pressed: bool,
}

Vec2 :: [2]f32

Player :: struct {
	pos: Vec2,
	size: f32,
	speed: f32,
}
player_init :: proc() -> Player {
	return Player{ pos = {10,10}, size = 100, speed = 5 };
}
player_move :: proc(p: ^Player, dir: Vec2) {
	p.pos += dir*p.speed
}
player_draw :: proc(as: ^AppState, p: Player) {
	r := as.renderer
	sdl.SetRenderDrawColor(r, 255, 0, 0, 255)
	if as.input.any_key_pressed {
		sdl.SetRenderDrawColor(r, 0, 255, 0, 255)
	}
	rect := sdl.FRect{p.pos.x, p.pos.y, p.size, p.size}
	sdl.RenderFillRect(r, &rect)
}

handle_input :: proc(as: ^AppState) {
	as.input.any_key_pressed = false
	for key in as.input.keys {
		if key {
			as.input.any_key_pressed = true
			break
		}
	}

	w := &as.world
	if as.input.keys[.Left] { player_move(&w.p, {-1,0}) }
	if as.input.keys[.Right] { player_move(&w.p, {1,0}) }
	if as.input.keys[.Up] { player_move(&w.p, {0,-1}) }
	if as.input.keys[.Down] { player_move(&w.p, {0,1}) }
}

draw :: proc(as: ^AppState) {
	r := as.renderer
	sdl.SetRenderDrawColor(r, 99, 99, 99, 255)
	sdl.RenderClear(r)

	player_draw(as, as.world.p)

	sdl.RenderPresent(r)
}

main :: proc() {
	init :: proc "c" (appstate: ^rawptr, argc: c.int, argv: [^]cstring) -> sdl.AppResult {
		context = runtime.default_context()
		as := new(AppState)
		world_init(&as.world)
		appstate^ = as

		if !sdl.SetAppMetadata("Game Two", "1.0", "me.greenfork.game-two") {
			sdl.Log("SetAppMetadata failed: %s", sdl.GetError())
			return .FAILURE
		}
		if !sdl.Init({.VIDEO}) {
			sdl.Log("Init failed: %s", sdl.GetError())
			return .FAILURE
		}
		if !sdl.CreateWindowAndRenderer("Game Two", 640, 480, {.RESIZABLE}, &as.window, &as.renderer) {
			sdl.Log("CreateWindowAndRenderer failed: %s", sdl.GetError())
			return .FAILURE
		}
		sdl.SetRenderVSync(as.renderer, 1)
		sdl.SetRenderLogicalPresentation(as.renderer, 640, 480, .LETTERBOX)

		return .CONTINUE
	}
	events :: proc "c" (appstate: rawptr, event: ^sdl.Event) -> sdl.AppResult {
		as := cast(^AppState)appstate

		#partial switch event.type {
		case .QUIT:
			return .SUCCESS
		case .KEY_DOWN:
			#partial switch event.key.scancode {
			case .LEFT: as.input.keys[.Left] = true
			case .RIGHT: as.input.keys[.Right] = true
			case .UP: as.input.keys[.Up] = true
			case .DOWN: as.input.keys[.Down] = true
			}
		case .KEY_UP:
			#partial switch event.key.scancode {
			case .LEFT: as.input.keys[.Left] = false
			case .RIGHT: as.input.keys[.Right] = false
			case .UP: as.input.keys[.Up] = false
			case .DOWN: as.input.keys[.Down] = false
			}
		}
		return .CONTINUE
	}
	iterate :: proc "c" (appstate: rawptr) -> sdl.AppResult {
		context = runtime.default_context()
		as := cast(^AppState)appstate
		handle_input(as)
		draw(as)
		return .CONTINUE
	}
	quit :: proc "c" (appstate: rawptr, result: sdl.AppResult) {
		context = runtime.default_context()
		as := cast(^AppState)appstate
		free(as)
	}

	sdl.EnterAppMainCallbacks(0, nil, init, iterate, events, quit)
}
