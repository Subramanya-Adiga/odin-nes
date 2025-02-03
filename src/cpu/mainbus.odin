package cpu
import "../cartridge"
import "core:fmt"
import "core:io"
import "core:os"

NesBus :: struct {
	memory: [2048]u8,
	irq:    bool,
	nmi:    bool,
	cart:   cartridge.Cartridge,
}

deinit :: proc(bus: ^NesBus) {
	cartridge.deinit(&bus.cart)
}

read :: proc(bus: ^NesBus, addr: u16) -> u8 {
	switch (addr) {
	case 0 ..= 0x1FFF:
		return bus.memory[addr & 0x7FF]
	case 0x2000 ..= 0x3FFF:
		fmt.print("PPU Not Implemented")
	case 0x4020 ..= 0xFFFF:
		return cartridge.read_cpu(&bus.cart, addr)
	}
	return 0
}

write :: proc(bus: ^NesBus, addr: u16, data: u8) {
	switch (addr) {
	case 0 ..= 0x1FFF:
		bus.memory[addr & 0x7FF] = data
	case 0x2000 ..= 0x3FFF:
		fmt.print("PPU Not Implemented")
	case 0x4020 ..= 0xFFFF:
		cartridge.write_cpu(&bus.cart, addr, data)
	}
}

load_cartridge :: proc(bus: ^NesBus, path: string) {
	file_handle, err := os.open(path, os.O_RDONLY)
	defer os.close(file_handle)
	assert(err == nil)

	file_stream := os.stream_from_handle(file_handle)
	defer io.close(file_stream)

	bus.cart = cartridge.init(&file_stream)
	cartridge.load(&bus.cart)
	_ = cartridge.read_cpu(&bus.cart, 0)
}
