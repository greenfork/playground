build:
	mkdir -p bin
	odin build . -out:bin/his_only_son -collection:myvendor=vendor/ -debug -define:DYNAMIC_ASSETS=true

build-release:
	mkdir -p bin
	odin build . -out:bin/his_only_son_release -collection:myvendor=vendor/ -o:speed

run: build
	./bin/his_only_son

run-gdb: build
	gdb ./bin/his_only_son

build-web:
	odin run karl2d/build_web -- . -collection:myvendor=vendor/

build-web-release:
	odin run karl2d/build_web -- . -collection:myvendor=vendor/ -o:size

server:
	python -m http.server -d bin/web

check:
	odin check . -collection:myvendor=vendor/ -strict-style

check-watch:
	fd -e odin . | entr -s "make check"

.PHONY: build build-release run run-gdb build-web build-web-release server check check-watch
.POSIX:
