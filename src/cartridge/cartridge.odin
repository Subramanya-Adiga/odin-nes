package cartridge

import "core:/io"
import "core:fmt"
import "core:os"
Cartridge :: struct {
	valid_image: bool,
	prog_banks:  u8,
	char_banks:  u8,
	mapper_type: u8,
	mirror:      MirrorMode,
	_state:      CartridgeState,
}

MirrorMode :: enum {
	Vertical,
	Horizontal,
	Onscreen_LO,
	OneScreen_HI,
}

@(private)
CartridgeState :: struct {
	prog_rom: [dynamic]u8,
	stream:   ^io.Stream,
	char_rom: [dynamic]u8,
	mapper:   Mapper,
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
	map_addr, map_data := mapper_cpu_read(&cart._state.mapper, addr)
	if map_addr == 0xFFFFFFFF {
		return map_data
	} else {
		return cart._state.prog_rom[map_addr]
	}
}

write_cpu :: proc(cart: ^Cartridge, addr: u16, data: u8) {
	map_addr, map_data := mapper_cpu_write(&cart._state.mapper, addr, data)
	if map_addr != 0xFFFFFFFF {
		cart._state.prog_rom[map_addr] = data
	}
}

read_ppu :: proc(cart: ^Cartridge, addr: u16) -> u8 {
	map_addr := mapper_ppu_read(&cart._state.mapper, addr)
	if map_addr != 0 {
		return cart._state.char_rom[map_addr]
	}
	return 0
}

write_ppu :: proc(cart: ^Cartridge, addr: u16, data: u8) {
	map_addr := mapper_ppu_write(&cart._state.mapper, addr)
	if map_addr != 0 {
		cart._state.char_rom[map_addr] = data
	}
}


load :: proc(cart: ^Cartridge) {
	buffer := [4]u8{}
	io.read(cart._state.stream^, buffer[:])
	numeric_header := transmute(u32)buffer
	assert(numeric_header == 441664846, "Not NES Rom")

	cart.prog_banks, _ = io.read_byte(cart._state.stream^)
	cart.char_banks, _ = io.read_byte(cart._state.stream^)

	mapper1, _ := io.read_byte(cart._state.stream^)
	mapper2, _ := io.read_byte(cart._state.stream^)
	cart.mirror = .Vertical if (mapper1 & 0x01) != 0 else .Horizontal

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
		cart._state.mapper = mapper_init(cart)
	}
}
