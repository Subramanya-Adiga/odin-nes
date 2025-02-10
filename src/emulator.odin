package main

import "cartridge"
import "controller"
import "core:io"
import "core:os"
import Nes "cpu"
import "ppu"

Emulator :: struct {
	cpu:        Nes.NesCpu,
	bus:        Nes.NesBus,
	ppu:        ppu.PPU,
	cart:       cartridge.Cartridge,
	controller: controller.Controller,
	counter:    u32,
}

init :: proc(emu: ^Emulator) {
	emu.bus.cart = &emu.cart
	emu.bus.controller = &emu.controller
	emu.ppu = ppu.init_ppu(&emu.cart)
	emu.bus.ppu = &emu.ppu
	emu.cpu = Nes.init_cpu(&emu.bus)
}

deinit :: proc(emu: ^Emulator) {
	cartridge.deinit(&emu.cart)
}

clock :: proc(emu: ^Emulator) {
	ppu.clock(&emu.ppu)
	if emu.counter % 3 == 0 {
		Nes.clock(&emu.cpu)
	}
	if emu.ppu.nmi {
		emu.ppu.nmi = false
		emu.bus.nmi = true
	}
	emu.counter += 1
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

set_controller_one_status :: proc(emu: ^Emulator, Status: controller.Buttons) {
	emu.controller.status1 = Status
}

set_controller_two_status :: proc(emu: ^Emulator, Status: controller.Buttons) {
	emu.controller.status2 = Status
}
