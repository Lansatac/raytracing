

import gl3n.linalg;

import sphere;
import render;
import sdl;


//enum uint width = 1920, height = 1080;
enum uint width = 640, height = 480;
//enum uint width = 100, height = 100;
//enum uint width = 64, height = 64;
//enum uint width = 16, height = 16;
//enum uint width = 8, height = 8;
//enum uint width = 4, height = 4;

int main(string[] args)
{
    alias vec3 = gl3n.linalg.vec3;
    sphere[] spheres;
    // position, radius, surface color, reflectivity, transparency, emission color
    spheres ~= sphere.sphere(vec3(0.0, -10004, -20), 10000, vec3(0.20, 0.20,
            0.20), 0, 0, vec3(0.01));

    spheres ~= sphere.sphere(vec3(0.0, 0, -20), 4, vec3(1.00, 0.32, 0.36), 0, 0.5);
    spheres ~= sphere.sphere(vec3(5.0, -1, -15), 2, vec3(0.90, 0.76, 0.46), 0, 0.0);
    spheres ~= sphere.sphere(vec3(5.0, 0, -25), 3, vec3(0.65, 0.77, 0.97), 0, 0.0);
    spheres ~= sphere.sphere(vec3(-5.5, 0, -15), 3, vec3(0.90, 0.90, 0.90), 0, 0.0);
    spheres ~= sphere.sphere(vec3(-2.5, 3, -30), 3, vec3(0.00, 0.90, 0.20), 0, 0.0);

    // light
    spheres ~= sphere.sphere(vec3(0.0, 20, -30), 3, vec3(0.00, 0.00, 0.00), 0, 0.0, vec3(3));
    //auto pixels = render.render(spheres, width, height);



    return run(width, height, ()=>render.render(spheres, width, height));
    //return 0;
}
