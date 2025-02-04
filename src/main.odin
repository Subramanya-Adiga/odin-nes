package main

import im "../thirdparty/imgui"
import "../thirdparty/imgui/imgui_impl_opengl3"
import "../thirdparty/imgui/imgui_impl_sdl2"
import "core:fmt"
import "cpu"
import gl "vendor:OpenGL"
import "vendor:sdl2"

main :: proc() {
	bus: cpu.NesBus = {}
	cpu.load_cartridge(&bus, "nestest.nes")

	nes_cpu := cpu.init_cpu(&bus)
	cpu.reset(&nes_cpu)

	sdl_ctx := init_sdl()
	defer deinit_sdl(&sdl_ctx)

	init_open_gl(&sdl_ctx)

	io := init_imgui(&sdl_ctx)
	defer deinit_imgui(&sdl_ctx)

	done := false

	for !done {
		event: sdl2.Event
		for sdl2.PollEvent(&event) {
			imgui_impl_sdl2.ProcessEvent(&event)
			if event.type == sdl2.EventType.QUIT {
				done = true
			}
		}

		imgui_impl_opengl3.NewFrame()
		imgui_impl_sdl2.NewFrame()
		im.NewFrame()

		im.ShowDemoWindow()

		im.Render()
		gl.Viewport(0, 0, i32(io.DisplaySize.x), i32(io.DisplaySize.y))
		gl.ClearColor(0.556, 0.629, 0.830, 255.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		imgui_impl_opengl3.RenderDrawData(im.GetDrawData())

		sdl2.GL_SwapWindow(sdl_ctx.window)
	}


}
