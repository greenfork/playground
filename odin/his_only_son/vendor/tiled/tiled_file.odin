/*
 * Copyright (c) 2024 SabeDoesThings.
 * Copyright (c) 2026 Dmitry Matveyev.
 * SPDX-License-Identifier: MIT
 */
#+build !freestanding
#+build !js
package tiled

import "core:encoding/json"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:path/filepath"

// parse_tilemap takes a Tiled tilemap JSON file
// and converts it into an Odin data structure.
parse_tilemap :: proc(path: string, alloc: mem.Allocator) -> Map {
	m: Map
	jdata, read_err := os.read_entire_file(path, alloc)
	if read_err != nil {
		fmt.println("ODIN_TILED: Failed to read file: ", path)
		return m
	}

	err := json.unmarshal(jdata, &m, allocator = alloc)
	if err != nil {
		fmt.print("ODIN_TILED: Failed to unmarshal JSON: ", err, "\n")
		ext := filepath.ext(path)
		if ext == ".tmx" || ext == ".tsx" || ext == ".xml" {
			fmt.println("ODIN_TILED: file appears to be XML; only JSON is supported")
		}
		return m
	}
	return m
}

// tries to parse tilemap and all external tilesets.
// should probably be the default
parse_tilemap_and_tilesets :: proc(path: string, alloc: mem.Allocator) -> Map {
	m := parse_tilemap(path, alloc)
	dir := filepath.dir(path)
	for &ts in m.tilesets {
		if ts.source == "" do continue
		ts_path, _ := filepath.join({dir, ts.source}, alloc)
		external_ts := parse_tileset(ts_path, alloc)

		// check could be better
		if external_ts.type == "" {
			fmt.printfln("Couldn't parse tileset %v", ts.source)
		}

		external_ts.first_gid = ts.first_gid
		external_ts.source = ts.source
		ts = external_ts
	}
	return m
}

// parse_tileset takes a Tiled tileset JSON file
// and converts it into an Odin data structure.
parse_tileset :: proc(path: string, alloc: mem.Allocator) -> Tileset {
	ts: Tileset
	jdata, read_err := os.read_entire_file(path, alloc)
	if read_err != nil {
		fmt.print("Failed to read file: ", path, "\n")
		return ts
	}

	err := json.unmarshal(jdata, &ts, allocator = alloc)
	if err != nil {
		fmt.print("ODIN_TILED: Failed to unmarshal JSON from ", path, ": ", err, "\n")
		ext := filepath.ext(path)
		if ext == ".tmx" || ext == ".tsx" || ext == ".xml" {
			fmt.println("ODIN_TILED: File appears to be XML; only JSON is supported")
		}
		return ts
	}
	return ts
}
