package cartridge

import "core:/io"
import "core:os"

Cartridge :: struct {
	valid_image: bool,
	prog_banks:  u8,
	char_banks:  u8,
	mapper_type: u8,
	prog_rom:    [dynamic]u8,
	char_rom:    [dynamic]u8,
	_stream:     ^io.Stream,
}

cartridge_init :: proc(file_stream: ^io.Stream) -> Cartridge {
	ret: Cartridge = {
		_stream = file_stream,
	}
	return ret
}

cartridge_deinit :: proc(cart: ^Cartridge) {
	delete(cart.prog_rom)
	delete(cart.char_rom)
}


read_cartridge :: proc(cart: ^Cartridge) {}
