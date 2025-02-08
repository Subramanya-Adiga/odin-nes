package ppu

import "vendor:sdl2"

color_to_u32 :: proc(format: ^sdl2.PixelFormat, color: sdl2.Color) -> u32 {
	return sdl2.MapRGBA(format, color.r, color.g, color.b, color.a)
}
