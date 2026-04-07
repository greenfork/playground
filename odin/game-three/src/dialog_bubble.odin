package main

import "core:c"
import sdl "vendor:sdl3"

DIALOG_BUBBLE_RECT :: sdl.FRect{33*SCREEN_MULTIPLIER,385*SCREEN_MULTIPLIER,551*SCREEN_MULTIPLIER,83*SCREEN_MULTIPLIER}
DIALOG_BUBBLE_PADDING :: 15

dialog_bubble_draw :: proc(appstate: ^App_State, text: cstring) {
	rect := DIALOG_BUBBLE_RECT
	sdl.RenderTexture(appstate.renderer, appstate.textures[.Dialog_Bubble], nil, &rect)
	x := DIALOG_BUBBLE_RECT.x + DIALOG_BUBBLE_PADDING
	y := DIALOG_BUBBLE_RECT.y + DIALOG_BUBBLE_PADDING
	w := cast(c.int)DIALOG_BUBBLE_RECT.w - 2*DIALOG_BUBBLE_PADDING
	font_draw(appstate, text, x, y, 19*SCREEN_MULTIPLIER, sdl.Color{0x1a,0x1a,0x1a,0xff}, w)
}
