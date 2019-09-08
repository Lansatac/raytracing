import std.stdio;
import std.algorithm;
import std.range;

import gl3n.linalg;

import sphere;
import render;
import pixel;

import derelict.sdl2.sdl;
import derelict.sdl2.image;

enum uint width = 1920, height = 1080;
//enum uint width = 640, height = 480;
//enum uint width = 100, height = 100;
//enum uint width = 64, height = 64;
//enum uint width = 4, height = 4;

int main(string[] args)
{
    alias vec3 = gl3n.linalg.vec3;
    sphere[] spheres;
    // position, radius, surface color, reflectivity, transparency, emission color
    spheres ~= sphere.sphere(vec3(0.0, -10004, -20), 10000, vec3(0.20, 0.20,
            0.20), 0, 0.0, vec3(0.05));
    spheres ~= sphere.sphere(vec3(0.0, 0, -20), 4, vec3(1.00, 0.32, 0.36), 1, 0.5);
    spheres ~= sphere.sphere(vec3(5.0, -1, -15), 2, vec3(0.90, 0.76, 0.46), .6, 0.0);
    spheres ~= sphere.sphere(vec3(5.0, 0, -25), 3, vec3(0.65, 0.77, 0.97), .4, 0.0);
    spheres ~= sphere.sphere(vec3(-5.5, 0, -15), 3, vec3(0.90, 0.90, 0.90), .8, 0.0);
    spheres ~= sphere.sphere(vec3(-2.5, 3, -30), 3, vec3(0.00, 0.90, 0.20), 0, 0.0);
    // light
    spheres ~= sphere.sphere(vec3(0.0, 20, -30), 3, vec3(0.00, 0.00, 0.00), 0, 0.0, vec3(3));
    auto pixels = render.render(spheres, width, height);


    DerelictSDL2.load();

    // Load the SDL2_image library.
    DerelictSDL2Image.load();

    if (SDL_Init(SDL_INIT_VIDEO) != 0)
    {
        writefln("SDL_Init Error: %s", SDL_GetError());
        return 1;
    }
    scope(exit) SDL_Quit();

    SDL_Window* win = SDL_CreateWindow("raytracing", 100, 100, width, height, SDL_WINDOW_SHOWN);
    if (win == null){
        writefln("SDL_CreateWindow Error: %s", SDL_GetError());
        SDL_Quit();
        return 1;
    }
    scope(exit)SDL_DestroyWindow(win);

    SDL_Renderer* ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (ren == null){
        writefln("SDL_CreateRenderer Error: %s", SDL_GetError());
        return 1;
    }
    scope(exit) SDL_DestroyRenderer(ren);

    SDL_Surface* surface = SDL_CreateRGBSurfaceFrom(pixels.map!PackedPixelRGBA.array.ptr,
        width, height,
        32, width * uint.sizeof,
        0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF);
    if (surface == null)
    {
        writefln("SDL_LoadBMP Error: %s", SDL_GetError());
        return 1;
    }
    SDL_Texture* tex = SDL_CreateTextureFromSurface(ren, surface);
    SDL_FreeSurface(surface);
    if (tex == null){
        writefln("SDL_CreateTextureFromSurface Error: %s", SDL_GetError());
        return 1;
    }

    SDL_Event e;
    bool quit = false;
    while (!quit){
        while (SDL_PollEvent(&e)){
            if (e.type == SDL_QUIT){
                quit = true;
            }
            if (e.type == SDL_KEYDOWN){
                quit = true;
            }
            if (e.type == SDL_MOUSEBUTTONDOWN){
                quit = true;
            }
        }
        //First clear the renderer
        // SDL_RenderClear(ren);
        //Draw the texture
        SDL_RenderCopy(ren, tex, null, null);
        //Update the screen
        SDL_RenderPresent(ren);
        
        SDL_Delay(1);
    }
    return 0;
}
