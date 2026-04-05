package main

import "core:fmt"
import "core:c"
import "base:runtime"
import "core:strings"
import "core:mem"
import "core:math"
import sdl "vendor:sdl3"
import sdl_ttf "vendor:sdl3/ttf"

AppState :: struct {
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

TextureType :: enum { Computer }
Textures :: [TextureType]^sdl.Texture
textures_init :: proc(r: ^sdl.Renderer, textures: ^Textures) -> bool {
	surface := sdl.LoadPNG("assets/computer-screen.png")
	if surface == nil {
		sdl.Log("computer-screen.png surface failed to load: %s", sdl.GetError())
		return false
	}
	texture := sdl.CreateTextureFromSurface(r, surface)
	if texture == nil {
		sdl.Log("computer-screen.png texture failed to load: %s", sdl.GetError())
		return false
	}
	sdl.DestroySurface(surface)
	textures[.Computer] = texture
	return true
}

font_init :: proc() -> ^sdl_ttf.Font {
	font := sdl_ttf.OpenFont("assets/VictorMono-Regular.ttf", 64)
	return font
}
font_draw :: proc(appstate: ^AppState, str: cstring, x, y: f32, font_size: f32, color: sdl.Color, wrap_width: c.int) -> bool {
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

Scene :: union { ComputerScene }
ComputerScene :: struct {
	screen_text: string,
	offset: int,
	index: int,
	column_number: int,
	line_number: int,
	lines: int,
	max_lines: int,
	max_columns: int,
}

SCREEN_TEXT2 :: `A
B
C
D

E
G
H`

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

computer_scene_init :: proc() -> ComputerScene {
	return ComputerScene{
		screen_text = SCREEN_TEXT,
		column_number = 1,
		line_number = 1,
		lines = 1,
		max_lines = 16,
		max_columns = 53,
	}
}

InputKey :: enum { Left, Right, Up, Down }
Input :: struct {
	keys: [InputKey]bool,
	any_key_pressed: bool,
	any_key_down: bool,
}

Vec2 :: [2]f32

computer_scene_draw :: proc(appstate: ^AppState, scene: ComputerScene) {
	draw_bounding_rect :: proc(r: ^sdl.Renderer) {
		sdl.SetRenderDrawColor(r, 255, 0, 0, 255)
		rect := COMPUTER_SCREEN_RECT
		sdl.RenderRect(r, &rect)
	}

	draw_text :: proc(appstate: ^AppState, scene: ComputerScene) {
		buf: [2048]byte
		mem.copy(raw_data(buf[:]), raw_data(scene.screen_text[scene.offset:]), scene.index - scene.offset)
		buf[scene.index] = 0
		x, y := COMPUTER_SCREEN_RECT.x, COMPUTER_SCREEN_RECT.y
		font_draw(appstate, cstring(raw_data(buf[:])), x, y, 16*SCREEN_MULTIPLIER, sdl.Color{0,255,0,255}, 0)
	}

	// draw_bounding_rect(appstate.renderer)
	draw_text(appstate, scene)
}

computer_scene_handle_input :: proc(input: Input, scene: ^ComputerScene) {
	if input.any_key_down {
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
}

handle_input :: proc(as: ^AppState) {
	as.input.any_key_pressed = false
	for key in as.input.keys {
		if key {
			as.input.any_key_pressed = true
			break
		}
	}

	if as.input.keys[.Left] {  }
	if as.input.keys[.Right] {  }
	if as.input.keys[.Up] {  }
	if as.input.keys[.Down] {  }

	switch &scene in as.world.scene {
	case ComputerScene:
		computer_scene_handle_input(as.input, &scene)
	}
}

draw :: proc(as: ^AppState) {
	r := as.renderer

	switch scene in as.world.scene {
	case ComputerScene:
		sdl.SetRenderDrawColor(r, 51, 51, 51, 255)
		sdl.RenderClear(r)

		sdl.RenderTexture(r, as.textures[.Computer], nil, nil)

		computer_scene_draw(as, scene)

		sdl.RenderPresent(r)
	case:
		sdl.Log("Skipping scene rendering, scene == nil")
	}
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
		as := cast(^AppState)appstate

		#partial switch event.type {
		case .QUIT:
			return .SUCCESS
		case .KEY_DOWN:
			if !event.key.repeat {
				#partial switch event.key.scancode {
				case .A ..= .Z, .COMMA, .PERIOD, .SLASH, .SEMICOLON, .LEFTBRACKET, .RIGHTBRACKET, .SPACE, .RETURN, .APOSTROPHE:
					as.input.any_key_down = true
				}
			}

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
		as.input.any_key_down = false
		return .CONTINUE
	}
	quit :: proc "c" (appstate: rawptr, result: sdl.AppResult) {
		context = runtime.default_context()
		as := cast(^AppState)appstate
		sdl.DestroyTexture(as.textures[.Computer])
		free(as)
		sdl_ttf.Quit()
		sdl.Quit()
	}

	sdl.EnterAppMainCallbacks(0, nil, init, iterate, events, quit)
}
