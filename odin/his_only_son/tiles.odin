package his_only_son

import k2 "karl2d"
import "myvendor:tiled"
import "core:log"

TILE_WIDTH :: 16
TILE_HEIGHT :: 16

load_textures :: proc() {
	w.tile_textures = {
		k2.load_texture_from_bytes(#load("assets/TinyTerrors/Tileset.png")),
	}
	w.textures = {
		.Chest = k2.load_texture_from_bytes(#load("assets/TinyTerrors/Chests.png")),
		.Player_Idle = k2.load_texture_from_bytes(#load("assets/TinyTerrors/Character_Idle.png")),
		.Player_Walk = k2.load_texture_from_bytes(#load("assets/TinyTerrors/Character_Walk.png")),
	}
}
unload_textures :: proc() {
	for tex in w.tile_textures { k2.destroy_texture(tex) }
	for tex in w.textures { k2.destroy_texture(tex) }
}

load_maps :: proc() {
	w.maps = {
		tiled.parse_tilemap_from_bytes(#load("assets/Tiled/hallway.json"), allocator=w.arena_allocator),
	}
}

draw_map :: proc(m: tiled.Map) {
	make_drawing_item :: proc(m: tiled.Map, layer: tiled.Layer, chunk: tiled.Chunk, skew_x, skew_y: i32, row, column: i32) -> (di: Drawing_Item, ok: bool) {
		global_tile_id := chunk.data[row*chunk.width + column]
		if global_tile_id == 0 { return {}, false }

		_flags: tiled.FlippingFlags
		global_tile_id, _flags = tiled.strip_flags(global_tile_id)

		tileset, tileset_idx := tiled.get_tileset_from_gid(m.tilesets, global_tile_id)

		tile_x := (global_tile_id - tileset.first_gid) % tileset.columns
		tile_y := (global_tile_id - tileset.first_gid) / tileset.columns

		src_rect := Rect{
			x = f32(tile_x * tileset.tile_width),
			y = f32(tile_y * tileset.tile_height),
			w = f32(tileset.tile_width),
			h = f32(tileset.tile_height),
		}
		dst_pos := Vec2{f32((column+skew_x) * TILE_WIDTH),f32((row+skew_y) * TILE_HEIGHT)}
		return {&w.tile_textures[tileset_idx], src_rect, dst_pos}, true
	}

	for layer in m.layers {
		is_floor := layer.name == "floor"
		#partial switch layer.type {
		case .Tile_Layer:
			if m.infinite {
				for chunk in layer.chunks {
					for row in 0..<chunk.height {
						for column in 0..<chunk.width {
							item, ok := make_drawing_item(m, layer, chunk, chunk.x, chunk.y, row, column)
							if ok {
								if is_floor {
									drawing_item_draw(item)
								} else {
									drawing_queue_add(item)
								}
							}
						}
					}
				}
			}
		}
	}
}

load_current_room :: proc(m: tiled.Map) {
	load_interactable :: proc(object: tiled.Object) {
		switch object.name {
		case "hero":
			w.player.pos = {f32(object.x), f32(object.y)}
		case "chest":
			switch object.type {
			case "golden_crystals_chest":
				interactable := Interactable{kind=.GoldenCrystalsChest, pos={f32(object.x), f32(object.y)},
					animation_frame_max=2, animation_speed=10}
				if append(&w.room.interactables, interactable) == 0 {
					log.errorf("Failed to push to interactables: %v", interactable)
				}
				collider := Collider{rect=Rect{f32(object.x)+2, f32(object.y-TILE_HEIGHT)+2, TILE_WIDTH-4, TILE_HEIGHT-4}}
				if append(&w.room.colliders, collider) == 0 {
					log.errorf("Failed to push to collider: %v", collider)
				}
			}
		}
	}

	load_collider :: proc(object: tiled.Object) {
		collider := Collider{rect=Rect{object.x, object.y,
			object.width, object.height}}
		if append(&w.room.colliders, collider) == 0 {
			log.errorf("Failed to push to colliders: %v", collider)
		}
	}

	for layer in m.layers {
		is_interactable := layer.name == "interactables"
		is_collider := layer.name == "colliders"

		#partial switch layer.type {
		case .Object_Group:
			if is_interactable {
				for object in layer.objects { load_interactable(object) }
			}
			if is_collider {
				for object in layer.objects { load_collider(object)}
			}
		}
	}
}
