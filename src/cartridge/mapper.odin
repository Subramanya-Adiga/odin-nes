package cartridge

import "mappers"

MapperType :: enum {
	Mapper0,
	Mapper1,
}

MapperData :: union {
	mappers.Mapper0Data,
}

Mapper :: struct {
	mapper_type: MapperType,
	mapper_data: MapperData,
}

mapper_init :: proc(cart: ^Cartridge) -> (mapper: Mapper) {
	switch (cart.mapper_type) {
	case 0:
		{
			mapper.mapper_type = MapperType.Mapper0
			data: mappers.Mapper0Data
			data.prog_banks = cart.prog_banks
			data.char_banks = cart.char_banks
			mapper.mapper_data = data
		}
	case:
		{}
	}
	return mapper
}

mapper_cpu_read :: proc(mapper: ^Mapper, addr: u16) -> (u32, u8) {
	switch (mapper.mapper_type) {
	case .Mapper0:
		{
			return mappers.mapper_0_cpu_read(&mapper.mapper_data.(mappers.Mapper0Data), addr)
		}
	case .Mapper1:
		{
			return 0, 0
		}
	}
	return 0, 0
}

mapper_cpu_write :: proc(mapper: ^Mapper, addr: u16, data: u8) -> (u32, u8) {
	switch (mapper.mapper_type) {
	case .Mapper0:
		{
			return mappers.mapper_0_cpu_write(
				&mapper.mapper_data.(mappers.Mapper0Data),
				addr,
				data,
			)
		}
	case .Mapper1:
		{
			return 0, 0
		}
	}
	return 0, 0

}

mapper_ppu_read :: proc(mapper: ^Mapper, addr: u16) -> u32 {
	switch (mapper.mapper_type) {
	case .Mapper0:
		{
			return mappers.mapper_0_ppu_read(&mapper.mapper_data.(mappers.Mapper0Data), addr)
		}
	case .Mapper1:
		{
			return 0
		}
	}
	return 0
}

mapper_ppu_write :: proc(mapper: ^Mapper, addr: u16) -> u32 {
	switch (mapper.mapper_type) {
	case .Mapper0:
		{
			return mappers.mapper_0_ppu_write(&mapper.mapper_data.(mappers.Mapper0Data), addr)
		}
	case .Mapper1:
		{
			return 0
		}
	}
	return 0
}
