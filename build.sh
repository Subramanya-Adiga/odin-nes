#!/bin/bash

odin build src -linker=lld -target-features="avx2" -o=none -debug -out="build/odin-nes"