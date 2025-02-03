package main

import "core:fmt"
import "cpu"
import gl "vendor:OpenGL"
import "vendor:sdl2"

main :: proc() {
	bus: cpu.NesBus = {}
	cpu.load_cartridge(&bus, "nestest.nes")

	nes_cpu := cpu.init_cpu(&bus)
	cpu.reset(&nes_cpu)

	//Initialize SDL
	init_val := sdl2.Init(
		sdl2.INIT_AUDIO | sdl2.INIT_VIDEO | sdl2.INIT_EVENTS | sdl2.INIT_GAMECONTROLLER,
	)
	if init_val != 0 {
		fmt.printf("SDL2 Failed To Initialize {}\n", sdl2.GetError())
	}
	defer sdl2.Quit()

	//Initialize Window
	window := sdl2.CreateWindow(
		"Odin-Nes",
		sdl2.WINDOWPOS_CENTERED,
		sdl2.WINDOWPOS_CENTERED,
		1280,
		720,
		sdl2.WINDOW_ALLOW_HIGHDPI | sdl2.WINDOW_OPENGL | sdl2.WINDOW_RESIZABLE,
	)
	if window == nil {
		fmt.printf("SDL2 Failed To Create Window {}\n", sdl2.GetError())
	}
	defer sdl2.DestroyWindow(window)

	sdl2.GL_SetAttribute(.CONTEXT_FLAGS, 0)
	sdl2.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, 3)
	sdl2.GL_SetAttribute(.CONTEXT_MINOR_VERSION, 0)
	sdl2.GL_SetAttribute(.CONTEXT_PROFILE_MASK, 1)
	sdl2.GL_SetAttribute(.DOUBLEBUFFER, 1)
	sdl2.GL_SetAttribute(.DEPTH_SIZE, 24)
	sdl2.GL_SetAttribute(.STENCIL_SIZE, 8)

	sdl2.GL_SetSwapInterval(1)

	gl_context := sdl2.GL_CreateContext(window)
	if gl_context == nil {
		fmt.printf("Failed To Create GL Context {}\n", sdl2.GetError())
	}
	defer sdl2.GL_DeleteContext(gl_context)


	sdl2.GL_MakeCurrent(window, gl_context)

	gl.load_up_to(3, 0, sdl2.gl_set_proc_address)

	done := false

	for !done {
		event: sdl2.Event
		for sdl2.PollEvent(&event) {
			if event.type == sdl2.EventType.QUIT {
				done = true
			}
		}

		x: i32
		y: i32
		sdl2.GetWindowSize(window, &x, &y)

		gl.Viewport(0, 0, x, y)
		gl.ClearColor(0.556, 0.629, 0.830, 255.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		sdl2.GL_SwapWindow(window)
	}


}
