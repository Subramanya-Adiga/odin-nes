package main

import im "../thirdparty/imgui"
import "../thirdparty/imgui/imgui_impl_opengl3"
import "../thirdparty/imgui/imgui_impl_sdl2"
import "core:fmt"
import gl "vendor:OpenGL"
import "vendor:sdl2"

SDLContext :: struct {
	initialized: bool,
	window:      ^sdl2.Window,
	gl_context:  sdl2.GLContext,
}

init_sdl :: proc() -> SDLContext {
	ctx: SDLContext

	//Initialize SDL
	init_val := sdl2.Init(
		sdl2.INIT_AUDIO | sdl2.INIT_VIDEO | sdl2.INIT_EVENTS | sdl2.INIT_GAMECONTROLLER,
	)
	if init_val != 0 {
		fmt.printf("SDL2 Failed To Initialize {}\n", sdl2.GetError())
	} else {
		ctx.initialized = true
	}

	//Initialize Window
	ctx.window = sdl2.CreateWindow(
		"Odin-Nes",
		sdl2.WINDOWPOS_CENTERED,
		sdl2.WINDOWPOS_CENTERED,
		1280,
		720,
		sdl2.WINDOW_ALLOW_HIGHDPI | sdl2.WINDOW_OPENGL | sdl2.WINDOW_RESIZABLE,
	)
	if ctx.window == nil {
		ctx.initialized = false
		fmt.printf("SDL2 Failed To Create Window {}\n", sdl2.GetError())
	}

	return ctx
}

deinit_sdl :: proc(ctx: ^SDLContext) {
	if ctx.initialized {
		sdl2.GL_DeleteContext(ctx.gl_context)
		sdl2.DestroyWindow(ctx.window)
		sdl2.Quit()
	}
}

init_open_gl :: proc(ctx: ^SDLContext) {
	if ctx.initialized {
		sdl2.GL_SetAttribute(.CONTEXT_FLAGS, 0)
		sdl2.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, 3)
		sdl2.GL_SetAttribute(.CONTEXT_MINOR_VERSION, 0)
		sdl2.GL_SetAttribute(.CONTEXT_PROFILE_MASK, 1)
		sdl2.GL_SetAttribute(.DOUBLEBUFFER, 1)
		sdl2.GL_SetAttribute(.DEPTH_SIZE, 24)
		sdl2.GL_SetAttribute(.STENCIL_SIZE, 8)

		ctx.gl_context = sdl2.GL_CreateContext(ctx.window)
		if ctx.gl_context == nil {
			fmt.printf("Failed To Create GL Context {}\n", sdl2.GetError())
		}

		sdl2.GL_MakeCurrent(ctx.window, ctx.gl_context)

		gl.load_up_to(3, 0, sdl2.gl_set_proc_address)
	}
}

init_imgui :: proc(ctx: ^SDLContext) {
	im.CHECKVERSION()
	im.CreateContext()
	io := im.GetIO()
	io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad, .DockingEnable, .ViewportsEnable}

	im.StyleColorsDark()
	styles := im.GetStyle()
	styles.WindowRounding = 0.0
	styles.Colors[im.Col.WindowBg].w = 1.0

	imgui_impl_sdl2.InitForOpenGL(ctx.window, ctx.gl_context)
	imgui_impl_opengl3.Init("#version 130")

}

imgui_new_frame :: proc() {
	imgui_impl_opengl3.NewFrame()
	imgui_impl_sdl2.NewFrame()
	im.NewFrame()
}

imgui_flush_frame :: proc(window: ^sdl2.Window) {
	io := im.GetIO()

	im.Render()
	gl.Viewport(0, 0, i32(io.DisplaySize.x), i32(io.DisplaySize.y))
	gl.ClearColor(0.556, 0.629, 0.830, 255.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	imgui_impl_opengl3.RenderDrawData(im.GetDrawData())

	imgui_update_viewports()

	sdl2.GL_SwapWindow(window)
}

imgui_update_viewports :: proc() {
	backup_window := sdl2.GL_GetCurrentWindow()
	backup_context := sdl2.GL_GetCurrentContext()
	im.UpdatePlatformWindows()
	im.RenderPlatformWindowsDefault()
	sdl2.GL_MakeCurrent(backup_window, backup_context)
}

deinit_imgui :: proc(ctx: ^SDLContext) {
	imgui_impl_sdl2.Shutdown()
	imgui_impl_opengl3.Shutdown()
	im.DestroyContext()
}
