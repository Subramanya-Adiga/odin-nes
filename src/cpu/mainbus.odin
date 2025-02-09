package cpu
import "../cartridge"
import "../ppu"
import "core:fmt"
import "core:io"
import "core:os"

NesBus :: struct {
	memory: [2048]u8,
	irq:    bool,
	nmi:    bool,
	ppu:    ^ppu.PPU,
	cart:   ^cartridge.Cartridge,
}

read :: proc(bus: ^NesBus, addr: u16) -> u8 {
	switch (addr) {
	case 0 ..= 0x1FFF:
		return bus.memory[addr & 0x7FF]
	case 0x2000 ..= 0x3FFF:
		{
			switch (addr & 0x0007) {
			case 0x0000:
			case 0x0001:
			case 0x0002:
				return ppu.read_from_status_register(bus.ppu)
			case 0x0003:
			case 0x0004:
			case 0x0005:
			case 0x0006:
			case 0x0007:
				return ppu.read_from_data_register(bus.ppu)
			}
		}
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
		{
			switch (addr & 0x0007) {
			case 0x0000:
				ppu.write_to_control_register(bus.ppu, data)
			case 0x0001:
				ppu.write_to_mask_register(bus.ppu, data)
			case 0x0002:
			case 0x0003:
			case 0x0004:
			case 0x0005:
				ppu.write_to_scroll_register(bus.ppu, data)
			case 0x0006:
				ppu.write_to_address_register(bus.ppu, data)
			case 0x0007:
				ppu.write_to_data_register(bus.ppu, data)

			}
		}
	case 0x4020 ..= 0xFFFF:
		cartridge.write_cpu(bus.cart, addr, data)
	}
}
