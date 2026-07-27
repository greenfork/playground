package main

import "core:strings"
import "core:mem"
import "core:math"
import sdl "vendor:sdl3"

Computer_Scene :: struct {
	code_source: Code_Source,
	offset: int,
	index: int,
	column_number: int,
	line_number: int,
	lines: int,
	max_lines: int,
	max_columns: int,
	selected_thing: enum { Monitor, Beer, Power_Button }
}

COMPUTER_SCREEN_RECT :: sdl.FRect{72*SCREEN_MULTIPLIER,42*SCREEN_MULTIPLIER,470*SCREEN_MULTIPLIER,303*SCREEN_MULTIPLIER}

computer_scene_init :: proc() -> Computer_Scene {
	return Computer_Scene{
		code_source = code_source_get(.Pcelka_Server),
		column_number = 1,
		line_number = 1,
		lines = 1,
		max_lines = 16,
		max_columns = 53,
		selected_thing = .Monitor,
	}
}

computer_scene_draw :: proc(appstate: ^App_State, scene: Computer_Scene) {
	draw_bounding_rect :: proc(r: ^sdl.Renderer) {
		sdl.SetRenderDrawColor(r, 255, 0, 0, 255)
		rect := COMPUTER_SCREEN_RECT
		sdl.RenderRect(r, &rect)
	}

	draw_text :: proc(appstate: ^App_State, scene: Computer_Scene) {
		buf: [2048]byte
		mem.copy(raw_data(buf[:]), raw_data(scene.code_source.src[scene.offset:]), scene.index - scene.offset)
		buf[scene.index] = 0
		x, y := COMPUTER_SCREEN_RECT.x, COMPUTER_SCREEN_RECT.y
		font_draw(appstate, cstring(raw_data(buf[:])), x, y, 16*SCREEN_MULTIPLIER, sdl.Color{0,255,0,255}, 0)
	}

	r := appstate.renderer

	sdl.SetRenderDrawColor(r, 51, 51, 51, 255)
	sdl.RenderClear(r)

	full_screen_texture: ^sdl.Texture
	switch scene.selected_thing {
	case .Monitor:
		full_screen_texture = appstate.textures[.Computer_Scene_Selected_Monitor]
	case .Beer:
		full_screen_texture = appstate.textures[.Computer_Scene_Selected_Beer]
	case .Power_Button:
		full_screen_texture = appstate.textures[.Computer_Scene_Selected_Power_Button]
	}
	sdl.RenderTexture(r, full_screen_texture, nil, nil)

	// draw_bounding_rect(appstate.renderer)
	draw_text(appstate, scene)
	// if text, ok := code_source_comment(scene); ok {
	// 	dialog_bubble_draw(appstate, text)
	// }

	sdl.RenderPresent(r)
}

computer_scene_handle_input :: proc(input: Input, scene: ^Computer_Scene) {
	if input.any_key_down && scene.selected_thing == .Monitor {
		inc: int
		newlines: int
		for r in scene.code_source.src[scene.index:] {
			if r == '\n' {
				newlines += 1
				scene.column_number = 1
			} else {
				scene.column_number += 1
			}
			if strings.is_space(r) {
				inc += 1
			} else {
				break
			}
		}
		scene.index += inc
		scene.line_number += newlines
		scene.lines += newlines
		lines_proficit := scene.lines - scene.max_lines
		for _ in 0..<lines_proficit {
			scene.offset += strings.index_rune(scene.code_source.src[scene.offset:], '\n') + 1
			scene.lines -= 1
		}
		scene.index = math.min(scene.index+1, len(scene.code_source.src))
	}

	if input.keys[.Left] {
		switch scene.selected_thing {
		case .Monitor:
		case .Beer, .Power_Button:
			scene.selected_thing = .Monitor
		}
	}
	if input.keys[.Right] {
		switch scene.selected_thing {
		case .Monitor:
			scene.selected_thing = .Power_Button
		case .Beer, .Power_Button:
		}
	}
	if input.keys[.Up] {
		switch scene.selected_thing {
		case .Monitor, .Power_Button:
		case .Beer:
			scene.selected_thing = .Power_Button
		}
	}
	if input.keys[.Down] {
		switch scene.selected_thing {
		case .Monitor, .Beer:
		case .Power_Button:
			scene.selected_thing = .Beer
		}
	}
}
