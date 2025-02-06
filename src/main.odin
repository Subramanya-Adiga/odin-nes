package main

import im "../thirdparty/imgui"
import "../thirdparty/imgui/imgui_impl_opengl3"
import "../thirdparty/imgui/imgui_impl_sdl2"
import "core:fmt"
import "cpu"
import "vendor:sdl2"

main :: proc() {
	bus: cpu.NesBus = {}
	cpu.load_cartridge(&bus, "nestest.nes")

	nes_cpu := cpu.init_cpu(&bus)
	cpu.reset(&nes_cpu)

	sdl_ctx := init_sdl()
	defer deinit_sdl(&sdl_ctx)

	init_open_gl(&sdl_ctx)

	init_imgui(&sdl_ctx)
	defer deinit_imgui(&sdl_ctx)

	io := im.GetIO()

	disassm := cpu.disassemble(&nes_cpu, 0x0000, 0xFFFF)
	shrink(&disassm)

	done := false

	for !done {
		event: sdl2.Event
		for sdl2.PollEvent(&event) {
			imgui_impl_sdl2.ProcessEvent(&event)
			if event.type == sdl2.EventType.QUIT {
				done = true
			}
		}

		imgui_new_frame()

		im.ShowDemoWindow()
		cpu_display(&nes_cpu, disassm, i32(cap(disassm)))

		imgui_flush_frame(sdl_ctx.window)

	}

}
