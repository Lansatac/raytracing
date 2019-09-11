import std.stdio;
import std.algorithm;
import std.range;
import std.datetime.stopwatch;

import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.ttf;


import render;
import pixel;

int run(GetPixels)(int width, int height, GetPixels getPixels)
{
    DerelictSDL2.load();

    // Load the SDL2_image library.
    DerelictSDL2Image.load();

    if (SDL_Init(SDL_INIT_VIDEO) != 0)
    {
        writefln("SDL_Init Error: %s", SDL_GetError());
        return 1;
    }
    scope (exit)
        SDL_Quit();

    SDL_Window* win = SDL_CreateWindow("raytracing", 100, 100, width, height, SDL_WINDOW_SHOWN);
    if (win == null)
    {
        writefln("SDL_CreateWindow Error: %s", SDL_GetError());
        SDL_Quit();
        return 1;
    }
    scope (exit)
        SDL_DestroyWindow(win);

    SDL_Renderer* ren = SDL_CreateRenderer(win, -1,
            SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (ren == null)
    {
        writefln("SDL_CreateRenderer Error: %s", SDL_GetError());
        return 1;
    }
    scope (exit)
        SDL_DestroyRenderer(ren);

    auto frameTimer = StopWatch(AutoStart.no);

    RenderOptions options;

    SDL_Event e;
    bool quit = false;
    while (!quit)
    {
        while (SDL_PollEvent(&e))
        {
            if (e.type == SDL_QUIT)
            {
                quit = true;
            }
            if (e.type == SDL_KEYDOWN)
            {
                switch( e.key.keysym.sym )
                {
                case SDLK_ESCAPE:
                    quit = true;
                    break;
                case SDLK_l:
                    options.lighting = !options.lighting;
                    break;
                case  SDLK_r:
                    options.reflections = !options.reflections;
                    break;
                case SDLK_t:
                    options.transparency = !options.transparency;
                    break;
                    default: break;
                }
            }
        }
        frameTimer.start;
        auto pixelData = getPixels(options).map!PackedPixelRGBA.array.ptr;
        writefln("pixel time = %s", frameTimer.peek);
        SDL_Surface* surface = SDL_CreateRGBSurfaceFrom(pixelData,
                width, height, 32, cast(int)(width * uint.sizeof), 0xFF000000,
                0x00FF0000, 0x0000FF00, 0x000000FF);
        if (surface == null)
        {
            writefln("SDL_CreateRGBSurfaceFrom Error: %s", SDL_GetError());
            return 1;
        }
        SDL_Texture* tex = SDL_CreateTextureFromSurface(ren, surface);
        SDL_FreeSurface(surface);
        if (tex == null)
        {
            writefln("SDL_CreateTextureFromSurface Error: %s", SDL_GetError());
            return 1;
        }

        //Draw the texture
        SDL_RenderCopy(ren, tex, null, null);
        //Update the screen
        SDL_RenderPresent(ren);

        frameTimer.stop;
        writefln("frame time = %s", frameTimer.peek);
        frameTimer.reset;

        SDL_Delay(1);
    }
    return 0;
}
