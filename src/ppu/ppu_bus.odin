package ppu

import cart "../cartridge"

PPUBus :: struct {
	cartridge:   ^cart.Cartridge,
	name_table:  [2][1024]u8,
	palette_tbl: [32]u8,
}

get_palette_index :: proc(addr: u16) -> u8 {
	index := addr & 0x001F
	switch (index) {
	case 0x10, 0x14, 0x18, 0x1C:
		return u8(index - 0x10)
	case:
		return u8(index)
	}
	assert(true, "Palette Address Out Of Bound")
	return 0
}

ppu_read :: proc(bus: ^PPUBus, addr: u16) -> u8 {
	wrapper_addr := addr & 0x3FFF
	switch (wrapper_addr) {
	case 0 ..= 0x1FFF:
		{
			return cart.read_ppu(bus.cartridge, wrapper_addr)
		}
	case 0x2000 ..= 0x3EFF:
		{
			addr_wrap := wrapper_addr & 0x0FFF
			if bus.cartridge.mirror == .Vertical {
				switch (addr_wrap) {
				case 0 ..= 0x03FF:
					return bus.name_table[0][addr_wrap & 0x03FF]
				case 0x0400 ..= 0x07FF:
					return bus.name_table[1][addr_wrap & 0x03FF]
				case 0x0800 ..= 0x0BFF:
					return bus.name_table[0][addr_wrap & 0x03FF]
				case 0x0C00 ..= 0x0FFF:
					return bus.name_table[1][addr_wrap & 0x03FF]
				}
			} else if (bus.cartridge.mirror == .Horizontal) {
				switch (addr_wrap) {
				case 0 ..< 0x03FF:
					return bus.name_table[0][addr_wrap & 0x03FF]
				case 0x0400 ..= 0x07FF:
					return bus.name_table[0][addr_wrap & 0x03FF]
				case 0x0800 ..= 0x0BFF:
					return bus.name_table[1][addr_wrap & 0x03FF]
				case 0x0C00 ..= 0x0FFF:
					return bus.name_table[1][addr_wrap & 0x03FF]
				}
			}
		}
	case 0x3F00 ..= 0x3FFF:
		{
			return bus.palette_tbl[get_palette_index(wrapper_addr)]
		}
	}
	assert(true, "PPU Read Out Of Bound")
	return 0
}

ppu_write :: proc(bus: ^PPUBus, addr: u16, data: u8) {
	wrapper_addr := addr & 0x3FFF
	switch (wrapper_addr) {
	case 0 ..= 0x1FFF:
		{
			cart.write_ppu(bus.cartridge, wrapper_addr, data)
		}
	case 0x2000 ..= 0x3EFF:
		{
			addr_wrap := wrapper_addr & 0x0FFF
			if bus.cartridge.mirror == .Vertical {
				switch (addr_wrap) {
				case 0 ..= 0x03FF:
					bus.name_table[0][addr_wrap & 0x03FF] = data
				case 0x0400 ..= 0x07FF:
					bus.name_table[1][addr_wrap & 0x03FF] = data
				case 0x0800 ..= 0x0BFF:
					bus.name_table[0][addr_wrap & 0x03FF] = data
				case 0x0C00 ..= 0x0FFF:
					bus.name_table[1][addr_wrap & 0x03FF] = data
				}
			} else if (bus.cartridge.mirror == .Horizontal) {
				switch (addr_wrap) {
				case 0 ..= 0x03FF:
					bus.name_table[0][addr_wrap & 0x03FF] = data
				case 0x0400 ..= 0x07FF:
					bus.name_table[0][addr_wrap & 0x03FF] = data
				case 0x0800 ..= 0x0BFF:
					bus.name_table[1][addr_wrap & 0x03FF] = data
				case 0x0C00 ..= 0x0FFF:
					bus.name_table[1][addr_wrap & 0x03FF] = data
				}
			}
		}
	case 0x3F00 ..= 0x3FFF:
		{
			bus.palette_tbl[get_palette_index(wrapper_addr)] = data
		}
	}
	assert(true, "PPU Write Out Of Bound")
}
