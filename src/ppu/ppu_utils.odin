package ppu

import "vendor:sdl2"

color_to_u32 :: proc(format: ^sdl2.PixelFormat, color: sdl2.Color) -> u32 {
	return sdl2.MapRGB(format, color.r, color.g, color.b)
}

get_color_from_palette :: proc(ppu: ^PPU, palette: u8, color: u8) -> sdl2.Color {
	return ppu.pal_screen[ppu_read(&ppu.bus, u16(0x3F00) + u16(palette << 2) + u16(color)) & 0x3F]

}

get_pattern_table :: proc(ppu: ^PPU, index: u8, palette: u8) -> ^sdl2.Surface {
	for tile_y in 0 ..< 16 {
		for tile_x in 0 ..< 16 {
			offset: u16 = u16(tile_y * 256) + u16(tile_x * 16)

			for row in 0 ..< 8 {

				loc := u16(index) * 0x1000 + offset + u16(row)
				tile_lsb := ppu_read(&ppu.bus, loc)
				tile_msb := ppu_read(&ppu.bus, loc + 8)

				for col in 0 ..< 8 {
					pixel := (tile_lsb & 0x1) << 1 | (tile_msb & 0x01)
					tile_lsb >>= 1
					tile_msb >>= 1

					rect := sdl2.Rect{i32((tile_x * 8) + (7 - col)), i32((tile_y * 8) + row), 1, 1}

					sdl2.FillRect(
						ppu.patter_images[index],
						&rect,
						color_to_u32(
							ppu.patter_images[index].format,
							get_color_from_palette(ppu, palette, pixel),
						),
					)
				}
			}
		}
	}
	return ppu.patter_images[index]
}
