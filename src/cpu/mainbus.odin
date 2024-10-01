package cpu

NesBus :: struct {
	memory: [2048]u8,
	irq:    bool,
	nmi:    bool,
}

read :: proc(bus: ^NesBus, addr: u16) -> u8 {
	switch (addr) {
	case 0 ..= 0x1FFF:
		return bus.memory[addr & 0x7FF]
	}
	return 0
}

write :: proc(bus: ^NesBus, addr: u16, data: u8) {
	switch (addr) {
	case 0 ..= 0x1FFF:
		bus.memory[addr & 0x7FF] = data
	}
}
