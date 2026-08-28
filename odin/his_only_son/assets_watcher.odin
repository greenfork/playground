package his_only_son

import "myvendor:fsw"
import "core:log"

Assets_Watcher :: struct {
	watcher: fsw.Watcher,
	path: string,
	cb: Assets_Watcher_Callback,
}
Assets_Watcher_Callback :: proc(Assets_Watcher_Event)
Assets_Watcher_Event :: fsw.Event

assets_watcher_init :: proc(path: string, allocator := context.allocator, cb: Assets_Watcher_Callback) -> Assets_Watcher {
	w, err := fsw.watch_dir_recursive(path, allocator)
	log.assertf(err == nil, "Failed to watch directory '%v'", path)
	return {w, path, cb}
}
assets_watcher_destroy :: proc(aw: Assets_Watcher) {
	fsw.destroy(aw.watcher)
}
assets_watcher_drain_and_run_callback :: proc(aw: ^Assets_Watcher, allocator := context.allocator) {
	events := fsw.get_events(&aw.watcher, allocator)
	for event in events {
		aw.cb(event)
	}
}
