import std.stdio;

import gl3n.linalg;
import imaged;

import sphere;
import render;


int main(string[] args)
{
    enum uint width = 1024, height = 768;
    //enum uint width = 100, height = 100;
    //enum uint width = 4, height = 4;

    sphere[] spheres;
    // position, radius, surface color, reflectivity, transparency, emission color
    spheres ~= sphere.sphere(vec3( 0.0, -10004, -20), 10000, vec3(0.20, 0.20, 0.20), 0, 0.0, vec3(0.05));
    spheres ~= sphere.sphere(vec3( 0.0,      0, -20),     4, vec3(1.00, 0.32, 0.36), 1, 0.5);
    spheres ~= sphere.sphere(vec3( 5.0,     -1, -15),     2, vec3(0.90, 0.76, 0.46), .6, 0.0);
    spheres ~= sphere.sphere(vec3( 5.0,      0, -25),     3, vec3(0.65, 0.77, 0.97), .4, 0.0);
    spheres ~= sphere.sphere(vec3(-5.5,      0, -15),     3, vec3(0.90, 0.90, 0.90), .8, 0.0);
    spheres ~= sphere.sphere(vec3(-2.5,      3, -30),     3, vec3(0.00, 0.90, 0.20), 0, 0.0);
    // light
    spheres ~= sphere.sphere(vec3( 0.0,     20, -30),     3, vec3(0.00, 0.00, 0.00), 0, 0.0, vec3(3));
    auto pixels = render.render(spheres, width, height);


    Image img = new Img!(Px.R8G8B8)(width, height);

    foreach(i, pixel; pixels)
    {
        import std.conv;
        //writefln("r=%s g=%s b=%s", pixel.r, pixel.g, pixel.b);
        img.setPixel(i % width, i / width, Pixel(to!int(pixel.r * 255), to!int(pixel.g * 255), to!int(pixel.b * 255)));
    }
    img.write("image.png");

    return 0;
}