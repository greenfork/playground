package his_only_son

import "core:math"
import "core:math/rand"
import "core:math/linalg"

enemy_dir :: proc(to_move: Vec2) -> (dir: Direction) {
	angle := math.atan2(to_move.x, to_move.y)
	north_south_angle: f32 : 45 * math.RAD_PER_DEG
	if math.abs(angle) < north_south_angle {
		dir = .South
	} else if math.abs(angle) > math.PI - north_south_angle {
		dir = .North
	} else if angle > 0 {
		dir = .East
	} else if angle < 0 {
		dir = .West
	}
	return
}

player_in_range :: proc(player: Player, enemy: Enemy, range: f32) -> bool {
	return linalg.length(player.pos - enemy.pos) < range
}

green_slime_script_fun :: proc(slime: ^Enemy, dt: f32, room: ^Room) {
	defer {
		slime.existed_time += dt
		slime.no_actions_time += dt
	}

	to_move: Vec2
	if player_in_range(w.player, slime^, 32) {
		to_move = 5*linalg.normalize0(w.player.pos - slime.pos)*dt
	} else {
		to_move = slime.velocity*dt
	}

	slime.is_moving = false
	if to_move.x != 0 || to_move.y != 0 {
		slime.is_moving = true
	}

	slime.dir = enemy_dir(to_move)

	if slime.is_moving {
		slime.animation.walk_time += dt
		slime.animation.idle_time = 0
	} else {
		slime.animation.walk_time = 0
		slime.animation.idle_time += dt
	}

	fixed_position, collided := colliders_fix_position(room.colliders[:], slime.pos, to_move, slime->collision_rect_fun())
	slime.pos = fixed_position

	choose_direction :: proc() -> Vec2 {
		return rand.choice([]Vec2{Vec2{0, 5}, Vec2{0, -5}, Vec2{5, 0}, Vec2{-5, 0}})
	}

	if collided || slime.no_actions_time > slime.next_action_in {
		slime.velocity = choose_direction()
		slime.no_actions_time = 0
		slime.next_action_in = rand.float32_range(3, 12)
	}
}