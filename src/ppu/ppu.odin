package ppu

import cart "../cartridge"
import "core:fmt"
import "core:math/rand"
import "vendor:sdl2"

PPU :: struct {
	bus:                   PPUBus,
	nmi:                   bool,
	cycles:                i16,
	scanlines:             i16,
	frame_complete:        bool,
	screen:                ^sdl2.Surface,
	patter_images:         [2]^sdl2.Surface,
	pal_screen:            [64]sdl2.Color,
	write_toggle:          bool,
	fine_x:                u8,
	buffered_data:         u8,
	ctrl_reg:              ControlRegister,
	mask_reg:              MaskRegister,
	stat_reg:              StatusRegister,
	vram_addr:             LoopyRegister,
	tram_addr:             LoopyRegister,
	bg_next_tile_id:       u8,
	bg_next_tile_attrib:   u8,
	bg_next_tile_lsb:      u8,
	bg_next_tile_msb:      u8,
	bg_shifter_pattern_lo: u16,
	bg_shifter_pattern_hi: u16,
	bg_shifter_attrib_lo:  u16,
	bg_shifter_attrib_hi:  u16,
}

init_ppu :: proc(cartridge: ^cart.Cartridge) -> PPU {
	ret: PPU
	ret.bus.cartridge = cartridge
	ret.pal_screen = Palette

	ret.screen = sdl2.CreateRGBSurface(0, 256, 240, 24, 0, 0, 0, 0)
	ret.patter_images[0] = sdl2.CreateRGBSurface(0, 128, 128, 24, 0, 0, 0, 0)
	ret.patter_images[1] = sdl2.CreateRGBSurface(0, 128, 128, 24, 0, 0, 0, 0)

	return ret
}

deinit_ppu :: proc(ppu: ^PPU) {
	sdl2.FreeSurface(ppu.screen)
	sdl2.FreeSurface(ppu.patter_images[0])
	sdl2.FreeSurface(ppu.patter_images[1])
}


clock :: proc(ppu: ^PPU) {
	if ppu.scanlines >= -1 && ppu.scanlines < 240 {

		if ppu.scanlines == -1 && ppu.cycles == 0 {
			ppu.cycles = 1
		}

		if ppu.scanlines == -1 && ppu.cycles == 1 {
			ppu.stat_reg.flags.v_blank = 0
		}

		if ((ppu.cycles >= 2) && (ppu.cycles < 258)) ||
		   ((ppu.cycles >= 321) && (ppu.cycles < 336)) {
			update_shifters(ppu)
			switch ((ppu.cycles - 1) % 8) {
			case 0:
				{
					load_shifters(ppu)
					ppu.bg_next_tile_id = ppu_read(
						&ppu.bus,
						0x2000 | (ppu.vram_addr.register & 0x0FFF),
					)
				}
			case 2:
				{
					ppu.bg_next_tile_attrib = ppu_read(
						&ppu.bus,
						0x23C0 |
						(ppu.vram_addr.flags.nametable_y << 11) |
						(ppu.vram_addr.flags.nametable_x << 10) |
						((ppu.vram_addr.flags.coarse_y >> 2) << 3) |
						(ppu.vram_addr.flags.coarse_x >> 2),
					)

					if (ppu.vram_addr.flags.coarse_y & 0x02) != 0 {
						ppu.bg_next_tile_attrib >>= 4
					}

					if ((ppu.vram_addr.flags.coarse_x & 0x02) != 0) {
						ppu.bg_next_tile_attrib >>= 2
					}

					ppu.bg_next_tile_attrib &= 0x03
				}
			case 4:
				{
					ppu.bg_next_tile_lsb = ppu_read(
						&ppu.bus,
						(u16(ppu.ctrl_reg.flags.background_pattern) << 12) +
						(u16(ppu.bg_next_tile_id) << 4) +
						ppu.vram_addr.flags.fine_y +
						0,
					)
				}
			case 6:
				{
					ppu.bg_next_tile_msb = ppu_read(
						&ppu.bus,
						(u16(ppu.ctrl_reg.flags.background_pattern) << 12) +
						(u16(ppu.bg_next_tile_id) << 4) +
						ppu.vram_addr.flags.fine_y +
						8,
					)
				}
			case 7:
				{
					increment_x(ppu)
				}
			}
		}
		if ppu.cycles == 256 {
			increment_y(ppu)
		}
		if ppu.cycles == 257 {
			load_shifters(ppu)
			transfer_x(ppu)
		}
		if ppu.cycles == 338 || ppu.cycles == 340 {
			ppu.bg_next_tile_id = ppu_read(&ppu.bus, 0x2000 | (ppu.vram_addr.register & 0x0FFF))
		}
		if ppu.scanlines == -1 && ppu.cycles >= 280 && ppu.cycles < 305 {
			transfer_y(ppu)
		}
	}

	if ppu.scanlines >= 241 && ppu.scanlines < 261 {
		if ppu.scanlines == 241 && ppu.cycles == 1 {
			ppu.stat_reg.flags.v_blank = 1
			if ppu.ctrl_reg.flags.v_blank_nmi == 1 {
				fmt.print("nmi_set")
				ppu.nmi = true
			}
		}
	}

	bg_pixel: u8 = 0
	bg_palette: u8 = 0

	if background_show(ppu) {
		bit_mux := 0x8000 >> ppu.fine_x

		p0 := 1 if (u16(ppu.bg_shifter_pattern_lo) & u16(bit_mux) > 0) else 0
		p1 := 1 if (u16(ppu.bg_shifter_pattern_hi) & u16(bit_mux) > 0) else 0
		bg_pixel = u8(p1 << 1) | u8(p0)

		b0 := 1 if (u16(ppu.bg_shifter_attrib_lo) & u16(bit_mux) > 0) else 0
		b1 := 1 if (u16(ppu.bg_shifter_attrib_hi) & u16(bit_mux) > 0) else 0
		bg_palette = u8(b1 << 1) | u8(b0)
	}

	rect: sdl2.Rect = {i32(ppu.cycles - 1), i32(ppu.scanlines), 1, 1}
	sdl2.FillRect(
		ppu.screen,
		&rect,
		color_to_u32(ppu.screen.format, get_color_from_palette(ppu, bg_palette, bg_pixel)),
	)

	ppu.cycles += 1
	if ppu.cycles >= 341 {
		ppu.cycles = 0
		ppu.scanlines += 1
		if ppu.scanlines >= 261 {
			ppu.scanlines = -1
			ppu.frame_complete = true
		}

	}
}

reset :: proc(ppu: ^PPU) {
	ppu.frame_complete = false
	ppu.scanlines = 0
	ppu.cycles = 0
	ppu.write_toggle = false
	ppu.fine_x = 0
	ppu.buffered_data = 0
	ppu.ctrl_reg.register = 0
	ppu.stat_reg.register = 0
	ppu.mask_reg.register = 0
	ppu.vram_addr.register = 0
	ppu.tram_addr.register = 0
	ppu.bg_next_tile_id = 0
	ppu.bg_next_tile_attrib = 0
	ppu.bg_next_tile_lsb = 0
	ppu.bg_next_tile_msb = 0
	ppu.bg_shifter_pattern_lo = 0
	ppu.bg_shifter_pattern_hi = 0
	ppu.bg_shifter_attrib_lo = 0
	ppu.bg_shifter_attrib_hi = 0
}

update_shifters :: proc(ppu: ^PPU) {
	if background_show(ppu) {
		ppu.bg_shifter_pattern_lo <<= 1
		ppu.bg_shifter_pattern_hi <<= 1
		ppu.bg_shifter_attrib_lo <<= 1
		ppu.bg_shifter_attrib_hi <<= 1
	}
}

load_shifters :: proc(ppu: ^PPU) {
	ppu.bg_shifter_pattern_lo = (ppu.bg_shifter_pattern_lo & 0xFF00) | u16(ppu.bg_next_tile_lsb)
	ppu.bg_shifter_pattern_hi = (ppu.bg_shifter_pattern_hi & 0xFF00) | u16(ppu.bg_next_tile_msb)

	new_attrib_lo: u16 = ppu.bg_next_tile_attrib & 0b01 != 0 ? 0xFF : 0x00
	ppu.bg_shifter_attrib_lo = (ppu.bg_shifter_attrib_lo & 0xFF00) | new_attrib_lo
	new_attrib_hi: u16 = ppu.bg_next_tile_attrib & 0b10 != 0 ? 0xFF : 0x00
	ppu.bg_shifter_attrib_hi = (ppu.bg_shifter_attrib_hi & 0xFF00) | new_attrib_hi
}

increment_x :: proc(ppu: ^PPU) {
	if background_show(ppu) || sprite_show(ppu) {
		if ppu.vram_addr.flags.coarse_x == 31 {
			ppu.vram_addr.flags.coarse_x = 0
			ppu.vram_addr.flags.nametable_x = ~ppu.vram_addr.flags.nametable_x
		} else {
			ppu.vram_addr.flags.coarse_x += 1
		}
	}
}

increment_y :: proc(ppu: ^PPU) {
	if background_show(ppu) || sprite_show(ppu) {
		if ppu.vram_addr.flags.fine_y < 7 {
			ppu.vram_addr.flags.fine_y += 1
		} else {
			ppu.vram_addr.flags.fine_y = 0
			if ppu.vram_addr.flags.coarse_y == 29 {
				ppu.vram_addr.flags.coarse_y = 0
				ppu.vram_addr.flags.nametable_y = ~ppu.vram_addr.flags.nametable_y
			} else if ppu.vram_addr.flags.coarse_y == 31 {
				ppu.vram_addr.flags.coarse_y = 0
			} else {
				ppu.vram_addr.flags.coarse_y += 1
			}
		}
	}
}

transfer_x :: proc(ppu: ^PPU) {
	if background_show(ppu) || sprite_show(ppu) {
		ppu.vram_addr.flags.nametable_x = ppu.tram_addr.flags.nametable_x
		ppu.vram_addr.flags.coarse_x = ppu.tram_addr.flags.coarse_x
	}
}

transfer_y :: proc(ppu: ^PPU) {
	if background_show(ppu) || sprite_show(ppu) {
		ppu.vram_addr.flags.fine_y = ppu.tram_addr.flags.fine_y
		ppu.vram_addr.flags.nametable_y = ppu.tram_addr.flags.nametable_y
		ppu.vram_addr.flags.coarse_y = ppu.tram_addr.flags.coarse_y
	}
}
