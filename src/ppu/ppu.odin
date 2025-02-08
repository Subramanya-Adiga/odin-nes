package ppu

import cart "../cartridge"
import "core:math/rand"
import "vendor:sdl2"

PPU :: struct {
	bus:            PPUBus,
	cycles:         i16,
	scanlines:      i16,
	frame_complete: bool,
	screen:         ^sdl2.Surface,
	patter_images:  [2]^sdl2.Surface,
	pal_screen:     [64]sdl2.Color,
}

init_ppu :: proc(cartridge: ^cart.Cartridge) -> PPU {
	ret: PPU
	ret.bus.cartridge = cartridge
	ret.pal_screen = Palette

	ret.screen = sdl2.CreateRGBSurface(0, 256, 240, 32, 0, 0, 0, 0)
	ret.patter_images[0] = sdl2.CreateRGBSurface(0, 128, 128, 32, 0, 0, 0, 0)
	ret.patter_images[1] = sdl2.CreateRGBSurface(0, 128, 128, 32, 0, 0, 0, 0)

	return ret
}

deinit_ppu :: proc(ppu: ^PPU) {
	sdl2.FreeSurface(ppu.screen)
	sdl2.FreeSurface(ppu.patter_images[0])
	sdl2.FreeSurface(ppu.patter_images[1])
}


clock :: proc(ppu: ^PPU) {
	rect: sdl2.Rect = {1, 1, i32(ppu.cycles - 1), i32(ppu.scanlines)}
	sdl2.FillRect(
		ppu.screen,
		&rect,
		color_to_u32(ppu.screen.format, ppu.pal_screen[0x30 if rand.uint32() % 2 != 0 else 0x3F]),
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
}
