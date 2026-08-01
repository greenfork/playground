build:
	odin build . -out:bin/zimawoods -collection:myvendor=vendor/

build-debug:
	odin build . -out:bin/zimawoods -collection:myvendor=vendor/ -debug -o:none

run: build
	./bin/zimawoods

run-debug: build-debug
	gdb ./bin/zimawoods

web:
	odin run karl2d/build_web -- . -o:size -collection:myvendor=vendor/

server:
	python -m http.server -d bin/web

.PHONY: build build-debug run run-debug web server
.POSIX:
