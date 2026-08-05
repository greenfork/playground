package his_only_son

import "core:slice"
import "core:fmt"
import "core:log"
import k2 "karl2d"

Drawing_Queue :: struct {
	items: [dynamic; 256]Drawing_Item,
}
drawing_queue_add :: proc(item: Drawing_Item, cull := true) -> bool {
	if cull {
		dst_rect := Rect{item.position.x, item.position.y,
			item.source_rect.w, item.source_rect.h}
		if !k2.rect_overlapping(dst_rect, w.game_camera_world_rect) {
			return false
		}
	}

	if append(&w.drawing_queue.items, item) == 0 {
		log.errorf("Failed to push drawing item to queue: %v", item)
		return false
	}
	return true
}
_drawing_queue_sort :: proc(q: ^Drawing_Queue) {
	slice.sort_by(q.items[:], proc(m, p: Drawing_Item) -> bool {
		return m.position.y < p.position.y
	})
}
drawing_queue_draw :: proc(q: ^Drawing_Queue, camera: k2.Camera) {
	_drawing_queue_sort(q)
	for item in q.items {
		drawing_item_draw(item)
	}
	if debug_drawing_queue { log.debugf("dq len: %v", len(q.items)) }
	clear(&q.items)
}
drawing_queue_draw_debug_info :: proc(q: Drawing_Queue) {
	if debug_drawing_queue {
		k2.draw_text(fmt.tprintf("drawing queue cap: %v", cap(q.items)), {2,2}, 4, k2.WHITE)
	}
}

Drawing_Item :: struct {
	texture: ^k2.Texture,
	source_rect: Rect,
	position: Vec2,
}
drawing_item_draw :: proc(item: Drawing_Item) {
	k2.draw_texture_rect(item.texture^, item.source_rect, item.position)
}
