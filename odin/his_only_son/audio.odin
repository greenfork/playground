package his_only_son

import "core:log"
import k2 "karl2d"

Audio :: struct {
	streams: [1]k2.Audio_Stream,
	current_stream_idx: int,
	playing: bool,

	sounds: [Sound_Kind]k2.Sound,

	// Must play some time after init, otherwise music starts with significant delay.
	first_time_inited: bool,
}
Sound_Kind :: enum { Chest_Open, Male_Pain }

audio_load :: proc() {
	w.audio.streams = {
		k2.load_audio_stream_from_bytes(#load("assets/christian_pop_n_dance/christian_dance_lowres.ogg")),
	}
	for stream in w.audio.streams {
		k2.set_audio_stream_loop(stream, true)
	}

	w.audio.sounds = {
		.Chest_Open = k2.load_sound_from_bytes(#load("assets/sounds/sfx_wooden_object_open.wav")),
		.Male_Pain = k2.load_sound_from_bytes(#load("assets/sounds/grunt_pain_male.wav")),
	}
	if debug_audio { log.debug("Audio files loaded") }
}
audio_destroy :: proc() {
	for audio_stream in w.audio.streams {
		k2.destroy_audio_stream(audio_stream)
	}
	for sound in w.audio.sounds {
		k2.destroy_sound(sound)
	}
}

audio_play :: proc() {
	stream := w.audio.streams[w.audio.current_stream_idx]
	k2.play_audio_stream(stream)
	w.audio.playing = true
}

audio_pause :: proc() {
	stream := w.audio.streams[w.audio.current_stream_idx]
	k2.pause_audio_stream(stream)
	w.audio.playing = false
}

audio_update :: proc() {
	stream := w.audio.streams[w.audio.current_stream_idx]
	k2.update_audio_stream(stream)
}

sound_play :: proc(kind: Sound_Kind) {
	sound := w.audio.sounds[kind]
	k2.play_sound(sound)
	if debug_audio { log.debugf("Played sound: %v", sound) }
}