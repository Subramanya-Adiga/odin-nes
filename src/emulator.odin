package main

import "cartridge"
import "core:io"
import "core:os"
import Nes "cpu"
import "ppu"

Emulator :: struct {
	cpu:  Nes.NesCpu,
	bus:  Nes.NesBus,
	ppu:  ppu.PPU,
	cart: cartridge.Cartridge,
}

init :: proc(emu: ^Emulator) {
	emu.bus.cart = &emu.cart
	emu.ppu = ppu.init_ppu(&emu.cart)
	emu.bus.ppu = &emu.ppu
	emu.cpu = Nes.init_cpu(&emu.bus)
}

deinit :: proc(emu: ^Emulator) {
	cartridge.deinit(&emu.cart)
}

reset :: proc(emu: ^Emulator) {
	Nes.reset(&emu.cpu)
	ppu.reset(&emu.ppu)
}

load_cartridge :: proc(emu: ^Emulator, path: string) {
	file_handle, err := os.open(path, os.O_RDONLY)
	defer os.close(file_handle)
	assert(err == nil)

	file_stream := os.stream_from_handle(file_handle)
	defer io.close(file_stream)

	emu.cart = cartridge.init(&file_stream)
	cartridge.load(&emu.cart)
}
