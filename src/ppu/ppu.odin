package ppu

import cart "../cartridge"
import "core:math/rand"
import "vendor:sdl2"

PPU :: struct {
	bus:            PPUBus,
	nmi:            bool,
	cycles:         i16,
	scanlines:      i16,
	frame_complete: bool,
	screen:         ^sdl2.Surface,
	patter_images:  [2]^sdl2.Surface,
	pal_screen:     [64]sdl2.Color,
	write_toggle:   bool,
	fine_x:         u8,
	buffered_data:  u8,
	ctrl_reg:       ControlRegister,
	mask_reg:       MaskRegister,
	stat_reg:       StatusRegister,
	vram_addr:      LoopyRegister,
	tram_addr:      LoopyRegister,
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
	rect: sdl2.Rect = {i32(ppu.cycles - 1), i32(ppu.scanlines), 1, 1}
	sdl2.FillRect(
		ppu.screen,
		&rect,
		color_to_u32(ppu.screen.format, ppu.pal_screen[0x30 if rand.uint32() % 2 != 0 else 0x3F]),
	)

	if ppu.scanlines >= 241 && ppu.scanlines < 261 {
		if ppu.cycles == 241 && ppu.cycles == 1 {
			ppu.stat_reg.flags.v_blank = 1
			if ppu.ctrl_reg.flags.v_blank_nmi == 1 {
				ppu.nmi = true
			}
		}
	}

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
}
