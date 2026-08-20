package his_only_son

import k2 "karl2d"
import "core:log"
import "core:math"

MENU_LINE_HEIGHT :: 1.5
MENU_FONT_SIZE :: 10

Scene_Starting_Screen :: struct {
	menu: Menu,
}
scene_starting_screen_init :: proc() -> Scene_Starting_Screen {
	menu: Menu
	append(&menu.items, Menu_Item{text="Start", size=MENU_FONT_SIZE, action_fun=proc(world: ^World) {
		scene := scene_room_load_first()
		scene_transition(scene)
	}})
	append(&menu.items, Menu_Item{text="Load", size=MENU_FONT_SIZE, action_fun=proc(world: ^World){}})
	append(&menu.items, Menu_Item{text="Settings", size=MENU_FONT_SIZE, action_fun=proc(world: ^World){}})
	append(&menu.items, Menu_Item{text="Quit", size=MENU_FONT_SIZE, action_fun=proc(world: ^World) {
		world.should_quit = true
	}})
	return {menu=menu}
}
Menu :: struct {
	items: [dynamic; 12]Menu_Item,
	selected_item_idx: int,
}
Menu_Item :: struct {
	text: string,
	size: f32,
	action_fun: proc(^World),
}
menu_item_draw :: proc(menu_item: Menu_Item, pos: Vec2, selected: bool) {
	color := selected ? k2.YELLOW : k2.WHITE
	k2.draw_text(menu_item.text, pos, menu_item.size, color)
}

scene_starting_screen_step :: proc(scene: ^Scene_Starting_Screen, dt: f32) {
	menu := scene.menu

	if k2.key_went_down(.Down) {
		scene.menu.selected_item_idx = math.min(len(menu.items)-1, menu.selected_item_idx+1)
	}
	if k2.key_went_down(.Up) {
		scene.menu.selected_item_idx = math.max(0, menu.selected_item_idx-1)
	}
	if k2.key_went_down(.Enter) {
		menu_item := menu.items[menu.selected_item_idx]
		menu_item.action_fun(&w)
	}

	w.ui_camera = {
		zoom = f32(k2.get_screen_height()) / SCREEN_HEIGHT,
	}
	k2.set_camera(w.ui_camera)
	k2.clear(BG_COLOR)
	for menu_item, idx in menu.items {
		pos := Vec2{10*VW, 50*VH + f32(idx)*menu_item.size*MENU_LINE_HEIGHT}
		menu_item_draw(menu_item, pos, idx == menu.selected_item_idx)
	}
	k2.draw_text("Ver 0.1.2", {90*VW,95*VH}, 4, k2.WHITE)
	k2.present()
}
