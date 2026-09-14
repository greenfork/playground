package his_only_son

import "core:fmt"
import k2 "karl2d"
import mu "vendor:microui"

mouse_buttons_map := [mu.Mouse]k2.Mouse_Button{
	.LEFT    = .Left,
	.RIGHT   = .Right,
	.MIDDLE  = .Middle,
}
key_map := [mu.Key][2]k2.Keyboard_Key{
	.SHIFT     = {.Left_Shift,   .Right_Shift},
	.CTRL      = {.Left_Control, .Right_Control},
	.ALT       = {.Left_Alt,     .Right_Alt},
	.BACKSPACE = {.Backspace,    .None},
	.DELETE    = {.Delete,       .None},
	.RETURN    = {.Enter,        .NP_Enter},
	.LEFT      = {.Left,         .None},
	.RIGHT     = {.Right,        .None},
	.HOME      = {.Home,         .None},
	.END       = {.End,          .None},
	.A         = {.A,            .None},
	.X         = {.X,            .None},
	.C         = {.C,            .None},
	.V         = {.V,            .None},
}

microui_input :: proc(ctx: ^mu.Context) {
	mpos := k2.get_mouse_position()
	mx, my := i32(mpos.x), i32(mpos.y)
	mu.input_mouse_move(ctx, mx, my)

	mwheel_dt := k2.get_mouse_wheel_delta()
	mu.input_scroll(ctx, 0, i32(mwheel_dt)*30)

	for button_k2, button_mu in mouse_buttons_map {
		switch {
		case k2.mouse_button_went_down(button_k2):
			mu.input_mouse_down(ctx, mx, my, button_mu)
		case k2.mouse_button_went_up(button_k2):
			mu.input_mouse_up  (ctx, mx, my, button_mu)
		}
	}
	for keys_k2, key_mu in key_map {
		for key_k2 in keys_k2 {
			switch {
			case key_k2 == .None:
			case k2.key_went_down(key_k2), k2.key_is_held(key_k2):
				mu.input_key_down(ctx, key_mu)
			case k2.key_went_up(key_k2):
				mu.input_key_up  (ctx, key_mu)
			}
		}
	}

	// TODO: currently no alternative to rl.GetCharPressed() in karl2d.
	// buf: [512]byte
	// n: int
	// for n < len(buf) {
	// 	c := rl.GetCharPressed()
	// 	if c == 0 {
	// 		break
	// 	}
	// 	b, w := utf8.encode_rune(c)
	// 	n += copy(buf[n:], b[:w])
	// }
	// mu.input_text(ctx, string(buf[:n]))
}

microui_draw :: proc(ctx: ^mu.Context, atlas_texture: k2.Texture) {
	mu.begin(ctx)
	defer mu.end(ctx)
	if mu.window(ctx, "My Window", mu.Rect{10, 10, 300, 400}) {
		if .ACTIVE in mu.header(ctx, "Window Info") {
			win := mu.get_current_container(ctx)
			mu.layout_row(ctx, {54, -1}, 0)
			mu.label(ctx, "Position:")
			mu.label(ctx, fmt.tprintf("%d, %d", win.rect.x, win.rect.y))
			mu.label(ctx, "Size:")
			mu.label(ctx, fmt.tprintf("%d, %d", win.rect.w, win.rect.h))
		}
	}
}

microui_init :: proc(ctx: ^mu.Context, atlas_texture: ^k2.Texture) {
	mu.init(&w.mu_ctx)
	ctx.text_width = mu.default_atlas_text_width
	ctx.text_height = mu.default_atlas_text_height

	k2.create_texture(mu.DEFAULT_ATLAS_WIDTH, mu.DEFAULT_ATLAS_HEIGHT, .RGBA_32_Float)
	// pixels := make([][4]u8, mu.DEFAULT_ATLAS_WIDTH*mu.DEFAULT_ATLAS_HEIGHT)
	// for alpha, i in mu.default_atlas_alpha {
	// 	pixels[i].rgb = 0xff
	// 	pixels[i].a = alpha
	// }
	pixels := make([]u8, mu.DEFAULT_ATLAS_WIDTH*mu.DEFAULT_ATLAS_HEIGHT*4)
	for alpha, i in mu.default_atlas_alpha {
		x := i % mu.DEFAULT_ATLAS_WIDTH
		y := i / mu.DEFAULT_ATLAS_WIDTH
		color := rl.Color{255, 255, 255, alpha}
		rl.ImageDrawPixel(&image, c.int(x), c.int(y), color)
		pixels[i].rgb = 0xff
		pixels[i].a = alpha
	}
	atlas_texture^ = k2.load_texture_from_bytes_raw(pixels,
		mu.DEFAULT_ATLAS_WIDTH, mu.DEFAULT_ATLAS_HEIGHT, .RGBA_32_Float)
}
microui_destroy :: proc(ctx: ^mu.Context, atlas_texture: k2.Texture) {
	k2.destroy_texture(atlas_texture)
}
