package main

import "cpu"
import "vendor:raylib"

main :: proc() {
	bus: cpu.NesBus = {}
	cpu.load_cartridge(&bus, "nestest.nes")

	nes_cpu := cpu.init_cpu(&bus)
	cpu.reset(&nes_cpu)

}
