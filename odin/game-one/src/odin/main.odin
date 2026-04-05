package main

import "core:fmt"
import rl "vendor:raylib"

Vec2 :: [2]f32

Player :: struct {
	pos: Vec2,
	size: f32,
	speed: f32,
	color: rl.Color
}
player_draw :: proc(p: Player) {
	rl.DrawRectangleV(p.pos, {p.size,p.size}, p.color)
}
player_move :: proc(p: ^Player, dir: Vec2) {
	p.pos += dir*p.speed
}

frame_counter: u64
p := Player{ pos = {100,300}, size = 100, color = rl.RED, speed = 5}

dbg :: proc(format: string, args: ..any) {
	if frame_counter % 20 == 0 {
		fmt.printfln(format, ..args)
	}
}

main :: proc() {
	rl.InitWindow(800, 640, "Game One")
	rl.SetTargetFPS(60)
	rl.SetExitKey(nil)
	for !rl.WindowShouldClose() {
		frame_counter += 1

		if rl.IsKeyDown(.RIGHT) { player_move(&p, {1,0}) }
		if rl.IsKeyDown(.LEFT) { player_move(&p, {-1,0}) }
		if rl.IsKeyDown(.UP) { player_move(&p, {0,-1}) }
		if rl.IsKeyDown(.DOWN) { player_move(&p, {0,1}) }

		rl.BeginDrawing()
		rl.ClearBackground(rl.WHITE)
		player_draw(p)
		rl.EndDrawing()
	}
	rl.CloseWindow()
}
