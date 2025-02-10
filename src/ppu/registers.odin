package ppu

MaskRegister :: struct #raw_union {
	flags:    bit_field u8 {
		graysacle:            u8 | 1,
		show_left_background: u8 | 1,
		show_left_sprite:     u8 | 1,
		show_background:      u8 | 1,
		show_sprite:          u8 | 1,
		red:                  u8 | 1,
		green:                u8 | 1,
		blue:                 u8 | 1,
	},
	register: u8,
}

ControlRegister :: struct #raw_union {
	flags:    bit_field u8 {
		name_table_x:        u8 | 1,
		name_table_y:        u8 | 1,
		increment_mode:      u8 | 1,
		sprite_pattern:      u8 | 1,
		background_pattern:  u8 | 1,
		master_slave_select: u8 | 1,
		v_blank_nmi:         u8 | 1,
	},
	register: u8,
}

StatusRegister :: struct #raw_union {
	flags:    bit_field u8 {
		open_bus:        u8 | 5,
		sprite_overflow: u8 | 1,
		sprite_hit:      u8 | 1,
		v_blank:         u8 | 1,
	},
	register: u8,
}

LoopyRegister :: struct #raw_union {
	flags:    bit_field u16 {
		coarse_x:    u16 | 5,
		coarse_y:    u16 | 5,
		nametable_x: u16 | 1,
		nametable_y: u16 | 1,
		fine_y:      u16 | 3,
	},
	register: u16,
}

increment_addr :: proc(ppu: ^PPU) {
	inc: u16 = 32 if ppu.ctrl_reg.flags.increment_mode == 1 else 1
	ppu.vram_addr.register += inc
}

background_show :: proc(ppu: ^PPU) -> bool {
	return ppu.mask_reg.flags.show_background != 0
}

sprite_show :: proc(ppu: ^PPU) -> bool {
	return ppu.mask_reg.flags.show_sprite != 0
}


write_to_mask_register :: proc(ppu: ^PPU, data: u8) {
	ppu.mask_reg.register = data
}

write_to_control_register :: proc(ppu: ^PPU, data: u8) {
	ppu.ctrl_reg.register = data
	ppu.tram_addr.flags.nametable_x = u16(ppu.ctrl_reg.flags.name_table_x)
	ppu.tram_addr.flags.nametable_y = u16(ppu.ctrl_reg.flags.name_table_y)
}

write_to_address_register :: proc(ppu: ^PPU, data: u8) {
	if !ppu.write_toggle {
		ppu.tram_addr.register = u16(data & 0x3F) << 8 | (ppu.tram_addr.register & 0x00FF)
	} else {
		ppu.tram_addr.register = (ppu.tram_addr.register & 0xFF00) | u16(data)
		ppu.vram_addr = ppu.tram_addr
	}
	ppu.write_toggle = !ppu.write_toggle
}

write_to_data_register :: proc(ppu: ^PPU, data: u8) {
	ppu_write(&ppu.bus, ppu.vram_addr.register, data)
	increment_addr(ppu)
}

write_to_scroll_register :: proc(ppu: ^PPU, data: u8) {
	if !ppu.write_toggle {
		ppu.fine_x = data & 0x07
		ppu.tram_addr.flags.coarse_x = u16(data) >> 3
	} else {
		ppu.tram_addr.flags.fine_y = u16(data) & 0x07
		ppu.tram_addr.flags.coarse_y = u16(data) >> 3
	}
	ppu.write_toggle = !ppu.write_toggle
}

read_from_status_register :: proc(ppu: ^PPU) -> u8 {
	data := (ppu.stat_reg.register & 0xE0) | (ppu.buffered_data & 0x1F)
	ppu.stat_reg.flags.v_blank = 0
	ppu.write_toggle = false
	return data
}

read_from_data_register :: proc(ppu: ^PPU) -> u8 {
	data := ppu.buffered_data
	ppu.buffered_data = ppu_read(&ppu.bus, ppu.vram_addr.register)
	if ppu.vram_addr.register >= 0x3F00 {
		data = ppu.buffered_data
	}
	increment_addr(ppu)
	return data
}
