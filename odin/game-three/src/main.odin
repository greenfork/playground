package main

import "core:fmt"
import "core:c"
import "base:runtime"
import "core:strings"
import "core:mem"
import "core:math"
import sdl "vendor:sdl3"
import sdl_ttf "vendor:sdl3/ttf"

App_State :: struct {
	window: ^sdl.Window,
	renderer: ^sdl.Renderer,
	input: Input,
	world: World,
	textures: Textures,
	font: ^sdl_ttf.Font,
}

SCREEN_MULTIPLIER :: 2
LOGICAL_SCREEN_WIDTH :: 848*SCREEN_MULTIPLIER
LOGICAL_SCREEN_HEIGHT :: 480*SCREEN_MULTIPLIER

COMPUTER_SCREEN_RECT :: sdl.FRect{72*SCREEN_MULTIPLIER,42*SCREEN_MULTIPLIER,470*SCREEN_MULTIPLIER,303*SCREEN_MULTIPLIER}

Texture_Type :: enum { Computer_Scene_Selected_Monitor, Computer_Scene_Selected_Beer, Computer_Scene_Selected_Power_Button, Dialog_Bubble }
Textures :: [Texture_Type]^sdl.Texture
texture_load :: proc(r: ^sdl.Renderer, path: cstring) -> ^sdl.Texture {
	surface := sdl.LoadPNG(path)
	if surface == nil {
		sdl.Log("computer-screen.png surface failed to load: %s", sdl.GetError())
	}
	texture := sdl.CreateTextureFromSurface(r, surface)
	if texture == nil {
		sdl.Log("computer-screen.png texture failed to load: %s", sdl.GetError())
	}
	sdl.DestroySurface(surface)
	return texture
}
textures_init :: proc(r: ^sdl.Renderer, textures: ^Textures) -> bool {
	textures[.Computer_Scene_Selected_Monitor] = texture_load(r, "assets/computer-scene-selected-monitor.png")
	textures[.Computer_Scene_Selected_Beer] = texture_load(r, "assets/computer-scene-selected-beer.png")
	textures[.Computer_Scene_Selected_Power_Button] = texture_load(r, "assets/computer-scene-selected-power-button.png")
	textures[.Dialog_Bubble] = texture_load(r, "assets/dialog-bubble.png")
	return true
}

font_init :: proc() -> ^sdl_ttf.Font {
	font := sdl_ttf.OpenFont("assets/VictorMono-Regular.ttf", 64)
	return font
}
font_draw :: proc(appstate: ^App_State, str: cstring, x, y: f32, font_size: f32, color: sdl.Color, wrap_width: c.int) -> bool {
	if (cast([^]u8)str)[0] == 0x0000 { return true }

	sdl_ttf.SetFontSize(appstate.font, font_size)
	sdl_ttf.SetFontLineSkip(appstate.font, cast(c.int)(font_size*1.2))
	text := sdl_ttf.RenderText_Blended_Wrapped(appstate.font, str, 0, color, wrap_width)
	defer sdl.DestroySurface(text)
	if text == nil {
		sdl.Log("RenderText failed: %s", sdl.GetError())
		return false
	}
	texture := sdl.CreateTextureFromSurface(appstate.renderer, text)
	defer sdl.DestroyTexture(texture)
	if texture == nil {
		sdl.Log("CreateTextureFromSurface failed: %s", sdl.GetError())
		return false
	}
	w, h: c.int
	if !sdl_ttf.GetStringSizeWrapped(appstate.font, str, 0, wrap_width, &w, &h) {
		sdl.Log("GetStringSize failed: %s", sdl.GetError())
		return false
	}
	rect := sdl.FRect{x,y,cast(f32)w,cast(f32)h}
	sdl.RenderTexture(appstate.renderer, texture, nil, &rect)
	return true
}

World :: struct {
	scene: Scene,
}
world_init :: proc(w: ^World) {
	w.scene = computer_scene_init()
}

Scene :: union { Computer_Scene }
Computer_Scene :: struct {
	screen_text: string,
	offset: int,
	index: int,
	column_number: int,
	line_number: int,
	lines: int,
	max_lines: int,
	max_columns: int,
	selected_thing: enum { Monitor, Beer, Power_Button }
}

SCREEN_TEXT :: `# frozen_string_literal: true

require "pcelka/server/writing"
require "pcelka/server/commandable"
require "pcelka/server/notifiable"

# Runs several command line programs.
module Pcelka
  class Server
    include Writing, Commandable, Notifiable

    WAKEUP_BYTE = 1

    # @param spec [Spec]
    # @param client_sink [Object#<<]
    # @param wakeup_io [IO#readbyte]
    # @param mailbox [Object#pop] receives messages
    # from clients.
    # @param programs_status_changed_cond
    # [Async::Condition]
    def initialize(spec:, client_sink:, wakeup_io:,
        mailbox:, programs_status_changed_cond:)
      @spec, @client_sink, @wakeup_io, @mailbox =
        spec, client_sink, wakeup_io, mailbox
      @running_programs = []
      @started_programs = []
      @watch_ios = []
      @is_pending_cmd = false
      @should_stop = false
      init_writer
      init_notifiable programs_status_changed_cond:
    end

    def run
      until @should_stop
        if ready_io = check_ready_io
          remove_wakeup_io(ready_io[0])
          programs = ready_programs(ready_io[0])
          write_programs_output(programs)
          process_cmd
        end
        notify_programs_status_changed
        prune_dead_programs
      end
    end

    private
      def check_ready_io
        ios_to_watch = @running_programs
          .flat_map(&:ios)
        ios_to_watch << @wakeup_io
        IO.select ios_to_watch, nil, nil, 0.1
      end

      def ready_programs(ios)
        programs = ios.map{|io| @running_programs
          .find{ it.mark_ready(io) } }
        programs.uniq!(&:id)
        programs
      end

      def prune_dead_programs
        @running_programs.filter! do |program|
          next true if program.alive?
          @writer.write app: program.id,
            message: "_died", is_error: true
          program.stop
          false
        end
      end
  end
end`

computer_scene_init :: proc() -> Computer_Scene {
	return Computer_Scene{
		screen_text = SCREEN_TEXT,
		column_number = 1,
		line_number = 1,
		lines = 1,
		max_lines = 16,
		max_columns = 53,
		selected_thing = .Monitor,
	}
}

Input_Key :: enum { Left, Right, Up, Down, Enter, Space }
Input :: struct {
	keys: [Input_Key]bool,
	any_key_pressed: bool,
	any_key_down: bool,
}

Vec2 :: [2]f32

computer_scene_draw :: proc(appstate: ^App_State, scene: Computer_Scene) {
	draw_bounding_rect :: proc(r: ^sdl.Renderer) {
		sdl.SetRenderDrawColor(r, 255, 0, 0, 255)
		rect := COMPUTER_SCREEN_RECT
		sdl.RenderRect(r, &rect)
	}

	draw_text :: proc(appstate: ^App_State, scene: Computer_Scene) {
		buf: [2048]byte
		mem.copy(raw_data(buf[:]), raw_data(scene.screen_text[scene.offset:]), scene.index - scene.offset)
		buf[scene.index] = 0
		x, y := COMPUTER_SCREEN_RECT.x, COMPUTER_SCREEN_RECT.y
		font_draw(appstate, cstring(raw_data(buf[:])), x, y, 16*SCREEN_MULTIPLIER, sdl.Color{0,255,0,255}, 0)
	}

	// draw_bounding_rect(appstate.renderer)
	draw_text(appstate, scene)
	dialog_bubble_draw(appstate, "Добавляем грёбаный аксессор...\nТак, стоп, что это за хрень...\nАаааа, точно! Я же неделю назад сделал эту фичу, чтобы выгрести весь мусор")
}

computer_scene_handle_input :: proc(input: Input, scene: ^Computer_Scene) {
	if input.any_key_down && scene.selected_thing == .Monitor {
		inc: int
		newlines: int
		for r in scene.screen_text[scene.index:] {
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
			scene.offset += strings.index_rune(scene.screen_text[scene.offset:], '\n') + 1
			scene.lines -= 1
		}
		scene.index = math.min(scene.index+1, len(scene.screen_text))
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

draw :: proc(as: ^App_State) {
	r := as.renderer

	switch scene in as.world.scene {
	case Computer_Scene:
		sdl.SetRenderDrawColor(r, 51, 51, 51, 255)
		sdl.RenderClear(r)

		full_screen_texture: ^sdl.Texture
		switch scene.selected_thing {
		case .Monitor:
			full_screen_texture = as.textures[.Computer_Scene_Selected_Monitor]
		case .Beer:
			full_screen_texture = as.textures[.Computer_Scene_Selected_Beer]
		case .Power_Button:
			full_screen_texture = as.textures[.Computer_Scene_Selected_Power_Button]
		}
		sdl.RenderTexture(r, full_screen_texture, nil, nil)

		computer_scene_draw(as, scene)

		sdl.RenderPresent(r)
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
		font := font_init()
		if font == nil {
			sdl.Log("font_init failed: %s", sdl.GetError())
			return .FAILURE
		}
		as.font = font

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
		for tx in as.textures {
			sdl.DestroyTexture(tx)
		}
		free(as)
		sdl_ttf.Quit()
		sdl.Quit()
	}

	sdl.EnterAppMainCallbacks(0, nil, init, iterate, events, quit)
}
