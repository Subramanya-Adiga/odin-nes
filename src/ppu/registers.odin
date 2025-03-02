package ppu

MaskRegister :: struct #raw_union {
	using flags: bit_field u8 {
		graysacle:            u8 | 1,
		show_left_background: u8 | 1,
		show_left_sprite:     u8 | 1,
		show_background:      u8 | 1,
		show_sprite:          u8 | 1,
		red:                  u8 | 1,
		green:                u8 | 1,
		blue:                 u8 | 1,
	},
	register:    u8,
}

ControlRegister :: struct #raw_union {
	using flags: bit_field u8 {
		name_table_x:        u8 | 1,
		name_table_y:        u8 | 1,
		increment_mode:      u8 | 1,
		sprite_pattern:      u8 | 1,
		background_pattern:  u8 | 1,
		sprite_size:         u8 | 1,
		master_slave_select: u8 | 1,
		v_blank_nmi:         u8 | 1,
	},
	register:    u8,
}

StatusRegister :: struct #raw_union {
	using flags: bit_field u8 {
		open_bus:        u8 | 5,
		sprite_overflow: u8 | 1,
		sprite_hit:      u8 | 1,
		v_blank:         u8 | 1,
	},
	register:    u8,
}

LoopyRegister :: struct #raw_union {
	using flags: bit_field u16 {
		coarse_x:    u16 | 5,
		coarse_y:    u16 | 5,
		nametable_x: u16 | 1,
		nametable_y: u16 | 1,
		fine_y:      u16 | 3,
		unused:      u16 | 1,
	},
	register:    u16,
}

ObjectAttributeMemory :: struct {
	y:         u8,
	id:        u8,
	attribute: u8,
	x:         u8,
}

increment_addr :: proc(ppu: ^PPU) {
	inc: u16 = 32 if ppu.ctrl_reg.increment_mode == 1 else 1
	ppu.vram_addr.register += inc
}

background_show :: proc(ppu: ^PPU) -> bool {
	return ppu.mask_reg.show_background == 1
}

sprite_show :: proc(ppu: ^PPU) -> bool {
	return ppu.mask_reg.show_sprite == 1
}

render_enabled :: proc(ppu: ^PPU) -> bool {
	return background_show(ppu) || sprite_show(ppu)
}

write_to_oam_address :: proc(ppu: ^PPU, data: u8) {
	ppu.oam_address = data
}

write_to_oam_data :: proc(ppu: ^PPU, data: u8) {
	wrapper_idx := ppu.oam_address & 0x3F

	switch (ppu.oam_address % 4) {
	case 0:
		ppu.oam[wrapper_idx].y = data
	case 1:
		ppu.oam[wrapper_idx].id = data
	case 2:
		ppu.oam[wrapper_idx].attribute = data
	case 3:
		ppu.oam[wrapper_idx].x = data
	}

	ppu.oam_write_counter += 1

	if (ppu.oam_write_counter >= 4) {
		ppu.oam_address += 1
		ppu.oam_write_counter = 0
	}
}

read_from_oam_data :: proc(ppu: ^PPU) -> u8 {
	wrapper_idx := ppu.oam_address & 0x3F

	switch (ppu.oam_address % 4) {
	case 0:
		return ppu.oam[wrapper_idx].y
	case 1:
		return ppu.oam[wrapper_idx].id
	case 2:
		return ppu.oam[wrapper_idx].attribute
	case 3:
		return ppu.oam[wrapper_idx].x
	}
	return 0
}


write_to_mask_register :: proc(ppu: ^PPU, data: u8) {
	ppu.mask_reg.register = data
}

write_to_control_register :: proc(ppu: ^PPU, data: u8) {
	ppu.ctrl_reg.register = data
	ppu.tram_addr.nametable_x = u16(ppu.ctrl_reg.name_table_x)
	ppu.tram_addr.nametable_y = u16(ppu.ctrl_reg.name_table_y)
}

write_to_address_register :: proc(ppu: ^PPU, data: u8) {
	if !ppu.write_toggle {
		write_data := u16(data & 0x3F) << 8 | (ppu.tram_addr.register & 0x00FF)
		ppu.tram_addr.register = write_data
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
		ppu.tram_addr.coarse_x = u16(data) >> 3
	} else {
		ppu.tram_addr.fine_y = u16(data) & 0x07
		ppu.tram_addr.coarse_y = u16(data) >> 3
	}
	ppu.write_toggle = !ppu.write_toggle
}

read_from_status_register :: proc(ppu: ^PPU) -> u8 {
	data := (ppu.stat_reg.register & 0xE0) | (ppu.buffered_data & 0x1F)
	ppu.stat_reg.v_blank = 0
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

cpu_write :: proc(ppu: ^PPU, addr: u16, data: u8) {
	switch (addr) {
	case 0:
		{ 	//Control
			write_to_control_register(ppu, data)
		}
	case 1:
		{ 	//Mask
			write_to_mask_register(ppu, data)
		}
	case 2: //Status
	case 3:
		{ 	//OAMAddress
			write_to_oam_address(ppu, data)
		}
	case 4:
		{ 	//OAMData
			write_to_oam_data(ppu, data)
		}
	case 5:
		{ 	//Scroll
			write_to_scroll_register(ppu, data)
		}
	case 6:
		{ 	//PPUAddress
			write_to_address_register(ppu, data)
		}
	case 7:
		{ 	//PPUData
			write_to_data_register(ppu, data)
		}
	}
}

cpu_read :: proc(ppu: ^PPU, addr: u16) -> u8 {
	switch (addr) {
	case 0: //Control
	case 1: //Mask
	case 2:
		{ 	//Status
			return read_from_status_register(ppu)
		}
	case 3: //OAMAddress
	case 4:
		{ 	//OAMData
			return read_from_oam_data(ppu)
		}
	case 5: //Scroll
	case 6: //PPUAddress
	case 7:
		{ 	//PPUData
			return read_from_data_register(ppu)
		}
	}
	return 0
}
