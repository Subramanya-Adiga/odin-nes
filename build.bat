@echo off

odin build src -target-features:"avx2" -debug -o:"none" -out:"build/odin-nes.exe"