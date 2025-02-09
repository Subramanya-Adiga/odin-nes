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
		name_table_addr:     u8 | 2,
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
	inc: u16 = 32 if ppu.ctrl_reg.flags.increment_mode != 0 else 1
	ppu.vram_addr.register += inc
}

background_show :: proc(ppu: ^PPU) -> bool {
	return ppu.mask_reg.flags.show_background != 0
}

sprite_show :: proc(ppu: ^PPU) -> bool {
	return ppu.mask_reg.flags.show_sprite != 0
}
