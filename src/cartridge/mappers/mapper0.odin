package mappers

Mapper0Data :: struct {
	prog_banks: u8,
	char_banks: u8,
}

mapper_0_cpu_read :: proc(mapper0: ^Mapper0Data, addr: u16) -> (u32, u8) {
	if (addr >= 0x8000) && (addr <= 0xFFFF) {
		return u32(addr & (0x7FFF if mapper0.prog_banks > 1 else 0x3FFF)), 0
	}
	return 0, 0
}

mapper_0_cpu_write :: proc(mapper0: ^Mapper0Data, addr: u16, data: u8) -> (u32, u8) {
	if (addr >= 0x8000) && (addr <= 0xFFFF) {
		return u32(addr & 0x7FFF if mapper0.prog_banks > 1 else 0x3FFF), 0
	}
	return 0, 0
}

mapper_0_ppu_read :: proc(mapper0: ^Mapper0Data, addr: u16) -> u32 {
	if (addr >= 0x0000) && (addr <= 0x1FFF) {
		return u32(addr)
	}
	return 0
}
mapper_0_ppu_write :: proc(mapper0: ^Mapper0Data, addr: u16) -> u32 {
	if (addr >= 0x0000) && (addr <= 0x1FFF) {
		if mapper0.char_banks == 0 {
			return u32(addr)
		}
	}
	return 0
}
