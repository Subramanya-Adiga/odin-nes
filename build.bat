@echo off

odin build src -target-features:"avx2" -lld -debug -subsystem:windows -out:"build/odin-nes.exe"