package main

import "core:c"
import sdl "vendor:sdl3"
import sdl_ttf "vendor:sdl3/ttf"

Fonts :: struct {
	monospace: ^sdl_ttf.Font,
}

fonts_init :: proc(appstate: ^App_State) -> bool {
	fonts := Fonts{}
	monospace := sdl_ttf.OpenFont("assets/VictorMono-Regular.ttf", 64)
	if monospace != nil {
		fonts.monospace = monospace
		appstate.fonts = fonts
		return true
	} else {
		return false
	}
}

fonts_deinit :: proc(appstate: ^App_State) {
	sdl_ttf.CloseFont(appstate.fonts.monospace)
}

font_draw :: proc(appstate: ^App_State, str: cstring, x, y: f32, font_size: f32, color: sdl.Color, wrap_width: c.int) -> bool {
	if (cast([^]u8)str)[0] == 0 { return true }

	font := appstate.fonts.monospace

	sdl_ttf.SetFontSize(font, font_size)
	sdl_ttf.SetFontLineSkip(font, cast(c.int)(font_size*1.2))
	text := sdl_ttf.RenderText_Blended_Wrapped(font, str, 0, color, wrap_width)
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
	if !sdl_ttf.GetStringSizeWrapped(font, str, 0, wrap_width, &w, &h) {
		sdl.Log("GetStringSize failed: %s", sdl.GetError())
		return false
	}
	rect := sdl.FRect{x,y,cast(f32)w,cast(f32)h}
	sdl.RenderTexture(appstate.renderer, texture, nil, &rect)
	return true
}
