package main

import "core:c"
import "base:runtime"
import sdl "vendor:sdl3"
import sdl_ttf "vendor:sdl3/ttf"

App_State :: struct {
	window: ^sdl.Window,
	renderer: ^sdl.Renderer,
	input: Input,
	world: World,
	textures: Textures,
	fonts: Fonts,
}

SCREEN_MULTIPLIER :: 2
LOGICAL_SCREEN_WIDTH :: 848*SCREEN_MULTIPLIER
LOGICAL_SCREEN_HEIGHT :: 480*SCREEN_MULTIPLIER

World :: struct {
	scene: Scene,
}
world_init :: proc(w: ^World) {
	w.scene = computer_scene_init()
}

Scene :: union { Computer_Scene }

Input_Key :: enum { Left, Right, Up, Down, Enter, Space }
Input :: struct {
	keys: [Input_Key]bool,
	any_key_pressed: bool,
	any_key_down: bool,
}

handle_input :: proc(as: ^App_State) {
	as.input.any_key_pressed = false
	for key in as.input.keys {
		if key {
			as.input.any_key_pressed = true
			break
		}
	}

	switch &scene in as.world.scene {
	case Computer_Scene:
		computer_scene_handle_input(as.input, &scene)
	}
}

draw :: proc(appstate: ^App_State) {
	switch scene in appstate.world.scene {
	case Computer_Scene:
		computer_scene_draw(appstate, scene)
	case:
		sdl.Log("Skipping scene rendering, scene == nil")
	}
}

main :: proc() {
	init :: proc "c" (appstate: ^rawptr, argc: c.int, argv: [^]cstring) -> sdl.AppResult {
		context = runtime.default_context()
		as := new(App_State)
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
		if !sdl.CreateWindowAndRenderer("Game Two", LOGICAL_SCREEN_WIDTH, LOGICAL_SCREEN_HEIGHT, {.RESIZABLE}, &as.window, &as.renderer) {
			sdl.Log("CreateWindowAndRenderer failed: %s", sdl.GetError())
			return .FAILURE
		}
		sdl.SetRenderVSync(as.renderer, 1)
		sdl.SetRenderLogicalPresentation(as.renderer, LOGICAL_SCREEN_WIDTH, LOGICAL_SCREEN_HEIGHT, .LETTERBOX)
		if !sdl_ttf.Init() {
			sdl.Log("TTF_INIT failed: %s", sdl.GetError())
			return .FAILURE
		}
		if !fonts_init(as) {
			sdl.Log("font_init failed: %s", sdl.GetError())
			return .FAILURE
		}

		if !textures_init(as.renderer, &as.textures) {
			sdl.Log("textures_init failed")
			return .FAILURE
		}

		return .CONTINUE
	}
	events :: proc "c" (appstate: rawptr, event: ^sdl.Event) -> sdl.AppResult {
		context = runtime.default_context()
		as := cast(^App_State)appstate

		#partial switch event.type {
		case .QUIT:
			return .SUCCESS
		case .KEY_DOWN:
			if !event.key.repeat {
				#partial switch event.key.scancode {
				case .A ..= .Z, .COMMA, .PERIOD, .SLASH, .SEMICOLON, .LEFTBRACKET, .RIGHTBRACKET, .SPACE, .APOSTROPHE:
					as.input.any_key_down = true
				}
			}

			#partial switch event.key.scancode {
			case .LEFT: as.input.keys[.Left] = true
			case .RIGHT: as.input.keys[.Right] = true
			case .UP: as.input.keys[.Up] = true
			case .DOWN: as.input.keys[.Down] = true
			case .RETURN: as.input.keys[.Enter] = true
			case .SPACE: as.input.keys[.Space] = true
			}
		case .KEY_UP:
			#partial switch event.key.scancode {
			case .LEFT: as.input.keys[.Left] = false
			case .RIGHT: as.input.keys[.Right] = false
			case .UP: as.input.keys[.Up] = false
			case .DOWN: as.input.keys[.Down] = false
			case .RETURN: as.input.keys[.Enter] = false
			case .SPACE: as.input.keys[.Space] = false
			}
		}
		return .CONTINUE
	}
	iterate :: proc "c" (appstate: rawptr) -> sdl.AppResult {
		context = runtime.default_context()
		as := cast(^App_State)appstate
		handle_input(as)
		draw(as)
		as.input.any_key_down = false
		return .CONTINUE
	}
	quit :: proc "c" (appstate: rawptr, result: sdl.AppResult) {
		context = runtime.default_context()
		as := cast(^App_State)appstate
		textures_deinit(as)
		fonts_deinit(as)
		free(as)
		sdl_ttf.Quit()
		sdl.Quit()
	}

	sdl.EnterAppMainCallbacks(0, nil, init, iterate, events, quit)
}
