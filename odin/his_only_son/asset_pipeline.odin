package his_only_son

import k2 "karl2d"
import "core:log"

DYNAMIC_ASSETS :: #config(DYNAMIC_ASSETS, false)

Texture_Kind :: enum { Tiny_Terrors_Tileset, Chest, Player_Idle, Player_Walk, Heart, Green_Slime_Walk, Green_Slime_Idle }
Textures :: [Texture_Kind]Texture_Item
Texture_Item :: struct {
	texture: k2.Texture,
	loaded: bool,
	kind: Texture_Kind,
	path: string,
}

load_textures :: proc(room_kind: Room_Kind) {
	t := &w.textures
	switch room_kind {
	case .First:
		register_texture(t, .Tiny_Terrors_Tileset, "assets/TinyTerrors/Tileset.png")
		register_texture(t, .Chest, "assets/TinyTerrors/Chests.png")
		register_texture(t, .Player_Idle, "assets/TinyTerrors/Character_Idle.png")
		register_texture(t, .Player_Walk, "assets/TinyTerrors/Character_Walk.png")
		register_texture(t, .Heart, "assets/mine/heart.png")
		register_texture(t, .Green_Slime_Walk, "assets/TinyTerrors/SlimeGreen_Walk.png")
		register_texture(t, .Green_Slime_Idle, "assets/TinyTerrors/SlimeGreen_Idle.png")
	}
}
unload_textures :: proc() {
	for texture_item, kind in w.textures {
		unregister_texture(&w.textures, kind)
	}
}
reload_textures :: proc() {
	switch scene in current_scene() {
	case Scene_Room:
		unload_textures()
		load_textures(scene.room.kind)
	case Scene_Starting_Screen:
	case Scene_Game_Over:
	}
}

register_texture :: proc(textures: ^Textures, kind: Texture_Kind, $path: string) {
	when DYNAMIC_ASSETS {
		textures[kind] = {k2.load_texture_from_file(path), true, kind, path}
	} else {
		textures[kind] = {k2.load_texture_from_bytes(#load(path)), true, kind, path}
	}
}
unregister_texture :: proc(textures: ^Textures, kind: Texture_Kind) {
	if !textures[kind].loaded do return
	k2.destroy_texture(textures[kind].texture)
	textures[kind].loaded = false
}
get_texture :: proc(textures: ^Textures, kind: Texture_Kind) -> k2.Texture {
	texture_item := textures[kind]
	log.assertf(texture_item.loaded, "Texture %v is not loaded!", kind)
	return texture_item.texture
}
get_texture_ptr :: proc(textures: ^Textures, kind: Texture_Kind) -> ^k2.Texture {
	texture_item := &textures[kind]
	log.assertf(texture_item.loaded, "Texture %v is not loaded!", kind)
	return &texture_item.texture
}
