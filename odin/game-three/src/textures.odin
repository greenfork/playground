package main

import sdl "vendor:sdl3"

Texture_Type :: enum {
	Computer_Scene_Selected_Monitor,
	Computer_Scene_Selected_Beer,
	Computer_Scene_Selected_Power_Button,
	Dialog_Bubble,
}

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

textures_deinit :: proc(appstate: ^App_State) {
	for tx in appstate.textures {
		sdl.DestroyTexture(tx)
	}
}
