package cpu
import "../cartridge"
import "../controller"
import "../ppu"
import "core:fmt"
import "core:io"
import "core:os"

NesBus :: struct {
	memory:        [2048]u8,
	irq:           bool,
	nmi:           bool,
	clock_counter: u32,
	ppu:           ^ppu.PPU,
	cart:          ^cartridge.Cartridge,
	controller:    ^controller.Controller,
	dma_transfer:  bool,
	dma_wait:      bool,
	dma_page:      u8,
	dma_data:      u8,
	dma_addr:      u8,
}

read :: proc(bus: ^NesBus, addr: u16) -> u8 {
	switch (addr) {
	case 0 ..= 0x1FFF:
		return bus.memory[addr & 0x7FF]
	case 0x2000 ..= 0x3FFF:
		return ppu.cpu_read(bus.ppu, addr & 0x0007)
	case 0x4016:
		return controller.read_controller_one(bus.controller)
	case 0x4017:
		return controller.read_controller_two(bus.controller)
	case 0x4020 ..= 0xFFFF:
		return cartridge.read_cpu(bus.cart, addr)
	}
	return 0
}

write :: proc(bus: ^NesBus, addr: u16, data: u8) {
	switch (addr) {
	case 0 ..= 0x1FFF:
		bus.memory[addr & 0x7FF] = data
	case 0x2000 ..= 0x3FFF:
		ppu.cpu_write(bus.ppu, addr & 0x0007, data)
	case 0x4014:
		{
			bus.dma_transfer = true
			bus.dma_addr = 0x00
			bus.dma_page = data
		}
	case 0x4016:
		controller.write_to_controllers(bus.controller, data)
	case 0x4020 ..= 0xFFFF:
		cartridge.write_cpu(bus.cart, addr, data)
	}
}

reset_bus :: proc(bus: ^NesBus) {
	bus.clock_counter = 0
	bus.nmi = false
	bus.irq = false
	bus.dma_transfer = false
	bus.dma_wait = true
	bus.dma_page = 0
	bus.dma_data = 0
	bus.dma_addr = 0
}

clock_bus :: proc(bus: ^NesBus) {
	if (bus.clock_counter % 3 == 0) {
		if (bus.dma_transfer) {
			if (bus.dma_wait) {
				if (bus.clock_counter % 2 == 1) {
					bus.dma_wait = false
				}
			} else {
				if (bus.clock_counter % 2 == 0) {
					bus.dma_data = read(bus, u16(bus.dma_page) << 8 | u16(bus.dma_addr))
				} else {
					bus.ppu.oam_buffer[bus.dma_addr] = bus.dma_data
					ppu.cpu_write(bus.ppu, 4, bus.dma_data)
					bus.dma_addr += 1
					if (bus.dma_addr == 0x00) {
						bus.dma_transfer = false
						bus.dma_wait = true
					}
				}
			}
		}
	}
	if (bus.ppu.nmi) {
		bus.nmi = true
		bus.ppu.nmi = false
	}
	bus.clock_counter += 1
}
