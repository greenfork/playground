.POSIX:
.PHONY: run

run:
	mkdir -p build/
	odin build src/ -out:build/game
	./build/game

check:
	odin check src/ -vet
