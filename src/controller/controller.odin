package controller

Buttons :: bit_field u8 {
	a:      u8 | 1,
	b:      u8 | 1,
	select: u8 | 1,
	start:  u8 | 1,
	up:     u8 | 1,
	down:   u8 | 1,
	left:   u8 | 1,
	right:  u8 | 1,
}

Controller :: struct {
	strobe:         bool,
	status1:        Buttons,
	status2:        Buttons,
	current_input1: u16,
	current_input2: u16,
}


read_controller_one :: proc(controller: ^Controller) -> u8 {
	return read_controller(controller, controller.status1, &controller.current_input1)
}

read_controller_two :: proc(controller: ^Controller) -> u8 {
	return read_controller(controller, controller.status2, &controller.current_input2)
}


read_controller :: proc(controller: ^Controller, btn: Buttons, input: ^u16) -> u8 {
	if input^ > (1 << 7) {
		return 1
	}
	pressed := bool((transmute(u8)btn & u8(input^)) > 0)
	if !controller.strobe {
		input^ <<= 1
	}
	return u8(pressed)
}

write_to_controllers :: proc(controller: ^Controller, data: u8) {
	controller.strobe = transmute(bool)(data & 1)
	if controller.strobe {
		controller.current_input1 = 1
		controller.current_input2 = 1
	}
}
