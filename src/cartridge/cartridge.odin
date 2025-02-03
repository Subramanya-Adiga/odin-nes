package cartridge

import "core:/io"
import "core:fmt"
import "core:os"
Cartridge :: struct {
	valid_image: bool,
	prog_banks:  u8,
	char_banks:  u8,
	mapper_type: u8,
	_state:      CartridgeState,
}

@(private)
CartridgeState :: struct {
	prog_rom: [dynamic]u8,
	stream:   ^io.Stream,
	char_rom: [dynamic]u8,
}

init :: proc(file_stream: ^io.Stream) -> Cartridge {
	ret: CartridgeState = {
		stream = file_stream,
	}
	return {valid_image = false, _state = ret}
}

deinit :: proc(cart: ^Cartridge) {
	delete(cart._state.prog_rom)
	delete(cart._state.char_rom)
}

read_cpu :: proc(cart: ^Cartridge, addr: u16) -> u8 {
	return 0
}

write_cpu :: proc(cart: ^Cartridge, addr: u16, data: u8) {}

read_ppu :: proc(cart: ^Cartridge, addr: u16) -> u8 {return 0}

write_ppu :: proc(cart: ^Cartridge, addr: u16, data: u8) {}


load :: proc(cart: ^Cartridge) {
	buffer := [4]u8{}
	io.read(cart._state.stream^, buffer[:])
	numeric_header := transmute(u32)buffer
	assert(numeric_header == 441664846, "Not NES Rom")

	cart.prog_banks, _ = io.read_byte(cart._state.stream^)
	cart.char_banks, _ = io.read_byte(cart._state.stream^)

	mapper1, _ := io.read_byte(cart._state.stream^)
	mapper2, _ := io.read_byte(cart._state.stream^)

	io.seek(cart._state.stream^, 8, io.Seek_From.Current)
	if mapper1 & 0x04 != 0 {
		io.seek(cart._state.stream^, 512, io.Seek_From.Current)
	}

	cart.mapper_type = ((mapper2 >> 4) << 4) | (mapper1 >> 4)
	cart._state.prog_rom, _ = make([dynamic]u8, u64(cart.prog_banks) * 0x4000)
	cart._state.char_rom, _ = make([dynamic]u8, u64(cart.char_banks) * 0x2000)

	_, err_prg := io.read_full(cart._state.stream^, cart._state.prog_rom[:])
	_, err_chr := io.read_full(cart._state.stream^, cart._state.char_rom[:])

	if err_prg == nil && err_chr == nil {
		cart.valid_image = true
	}
}
