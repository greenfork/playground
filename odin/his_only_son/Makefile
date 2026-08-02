build:
	mkdir -p bin
	odin build . -out:bin/his_only_son -collection:myvendor=vendor/ -debug

build-debug:
	mkdir -p bin
	odin build . -out:bin/his_only_son -collection:myvendor=vendor/ -debug -o:none

run: build
	./bin/his_only_son

run-debug: build-debug
	gdb ./bin/his_only_son

web:
	odin run karl2d/build_web -- . -o:size -collection:myvendor=vendor/

server:
	python -m http.server -d bin/web

.PHONY: build build-debug run run-debug web server
.POSIX:
