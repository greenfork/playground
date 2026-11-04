#!/usr/bin/env sh
set -uexo pipefail

git submodule add --depth 1 https://git.musl-libc.org/git/musl || true
cd musl
CFLAGS="--target=amd64-unknown-linux-musl" RANLIB=llvm-ranlib AR=llvm-ar CC=clang ./configure -- target=amd64 --disable-shared
make -j16
cd ..

mkdir -p build/
rm build/*
odin build . -out:build/static -target:linux_amd64 -build-mode:object -o:speed
ld.lld build/* musl/lib/libc.a musl/lib/crt1.o -o build/static
ldd build/static || true
./build/static
