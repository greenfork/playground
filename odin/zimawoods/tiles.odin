package zimawoods

import "core:encoding/json"
import "core:log"
import k2 "karl2d"
import tiled "myvendor:tiled"
import "core:fmt"

tiles_textures: [2]k2.Texture
lpc_winter_map: tiled.Map
TILE_WIDTH :: 16
TILE_HEIGHT :: 16

tiles_draw :: proc() {
	for layer in lpc_winter_map.layers {
		for row in 0..<layer.height {
			for column in 0..<layer.width {
				global_tile_id := layer.data[row*layer.width + column]
				if global_tile_id == 0 { continue }

				_flags: tiled.FlippingFlags
				global_tile_id, _flags = tiled.strip_flags(global_tile_id)

				tileset, tileset_idx := tiled.get_tileset_from_gid(lpc_winter_map.tilesets, global_tile_id)

				tile_x := (global_tile_id - tileset.first_gid) % tileset.columns
				tile_y := (global_tile_id - tileset.first_gid) / tileset.columns

				src_rect := k2.Rect{
					x = f32(tile_x * tileset.tile_width),
					y = f32(tile_y * tileset.tile_height),
					w = f32(tileset.tile_width),
					h = f32(tileset.tile_height),
				}
				dst_rect := k2.Rect{
					x = f32(column * TILE_WIDTH),
					y = f32(row * TILE_HEIGHT),
					w = TILE_WIDTH,
					h = TILE_HEIGHT,
				}
				k2.draw_texture_fit(tiles_textures[tileset_idx], src_rect, dst_rect)
			}
		}
	}
}

texture_load_all :: proc() {
	tiles_textures = {
		texture_load("assets/tilesets/lpc-winter-tiles/TilesA2.png"),
		texture_load("assets/tilesets/lpc-winter-tiles/TilesB.png")
	}
	lpc_winter_map = tiled.parse_tilemap_from_bytes(#load("assets/map1.json"))
}

texture_load :: proc($path: string) -> k2.Texture {
	return k2.load_texture_from_bytes(#load(path))
}
