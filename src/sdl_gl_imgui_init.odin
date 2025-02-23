package main

import im "../vendor/imgui"
import "../vendor/imgui/imgui_impl_opengl3"
import "../vendor/imgui/imgui_impl_sdl2"
import "core:fmt"
import gl "vendor:OpenGL"
import sdl "vendor:sdl2"

SDLContext :: struct {
	initialized: bool,
	window:      ^sdl.Window,
	gl_context:  sdl.GLContext,
}

init_sdl :: proc() -> SDLContext {
	ctx: SDLContext

	//Initialize SDL
	init_val := sdl.Init(
		sdl.INIT_AUDIO | sdl.INIT_VIDEO | sdl.INIT_EVENTS | sdl.INIT_GAMECONTROLLER,
	)
	if init_val != 0 {
		fmt.printf("sdl Failed To Initialize {}\n", sdl.GetError())
	} else {
		ctx.initialized = true
	}

	//Initialize Window
	ctx.window = sdl.CreateWindow(
		"Odin-Nes",
		sdl.WINDOWPOS_CENTERED,
		sdl.WINDOWPOS_CENTERED,
		1280,
		720,
		sdl.WINDOW_ALLOW_HIGHDPI | sdl.WINDOW_OPENGL | sdl.WINDOW_RESIZABLE,
	)
	if ctx.window == nil {
		ctx.initialized = false
		fmt.printf("sdl Failed To Create Window {}\n", sdl.GetError())
	}

	return ctx
}

deinit_sdl :: proc(ctx: ^SDLContext) {
	if ctx.initialized {
		sdl.GL_DeleteContext(ctx.gl_context)
		sdl.DestroyWindow(ctx.window)
		sdl.Quit()
	}
}

init_open_gl :: proc(ctx: ^SDLContext) {
	if ctx.initialized {
		sdl.GL_SetAttribute(.CONTEXT_FLAGS, 0)
		sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, 3)
		sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, 0)
		sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, 1)
		sdl.GL_SetAttribute(.DOUBLEBUFFER, 1)
		sdl.GL_SetAttribute(.DEPTH_SIZE, 24)
		sdl.GL_SetAttribute(.STENCIL_SIZE, 8)

		ctx.gl_context = sdl.GL_CreateContext(ctx.window)
		if ctx.gl_context == nil {
			fmt.printf("Failed To Create GL Context {}\n", sdl.GetError())
		}

		sdl.GL_MakeCurrent(ctx.window, ctx.gl_context)

		gl.load_up_to(3, 0, sdl.gl_set_proc_address)
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

imgui_flush_frame :: proc(window: ^sdl.Window) {
	io := im.GetIO()

	im.Render()
	gl.Viewport(0, 0, i32(io.DisplaySize.x), i32(io.DisplaySize.y))
	gl.ClearColor(0.556, 0.629, 0.830, 255.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	imgui_impl_opengl3.RenderDrawData(im.GetDrawData())

	imgui_update_viewports()

	sdl.GL_SwapWindow(window)
}

imgui_update_viewports :: proc() {
	backup_window := sdl.GL_GetCurrentWindow()
	backup_context := sdl.GL_GetCurrentContext()
	im.UpdatePlatformWindows()
	im.RenderPlatformWindowsDefault()
	sdl.GL_MakeCurrent(backup_window, backup_context)
}

deinit_imgui :: proc(ctx: ^SDLContext) {
	imgui_impl_sdl2.Shutdown()
	imgui_impl_opengl3.Shutdown()
	im.DestroyContext()
}

create_texture :: proc() -> u32 {
	tex_id: u32
	gl.GenTextures(1, &tex_id)
	gl.BindTexture(gl.TEXTURE_2D, tex_id)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP)

	gl.BindTexture(gl.TEXTURE_2D, 0)

	return tex_id
}

update_texture :: proc(id: u32, width: i32, height: i32, data: rawptr) {
	gl.BindTexture(gl.TEXTURE_2D, id)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA8, width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, data)
	gl.BindTexture(gl.TEXTURE_2D, 0)
}
