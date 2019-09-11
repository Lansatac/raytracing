module render;

import std.stdio;

import std.typecons;
import std.math;
import std.algorithm;
import std.range;

import gl3n.linalg;

import sphere;

//[comment]
// This variable controls the maximum recursion depth
//[/comment]
enum MAX_RAY_DEPTH = 2;

float mix(const float a, const float b, const float mix)
{
    return b * mix + a * (1 - mix);
}

struct RenderOptions
{
    bool lighting;
    bool reflections;
    bool transparency;
}

vec3 trace(const RenderOptions options, const vec3 rayorig, const vec3 raydir, const Sphere[] spheres, const int depth)
{
    import std.functional : partial;

    alias calculateIntersection = partial!(partial!(intersect, rayorig), raydir);

    auto intersections = spheres.map!(s => rebindable(s), s => calculateIntersection(s))
        .filter!(intersection => intersection[1].Hit);

    if (intersections.empty)
    {
        return vec3(0.4, 0.4, 1);
    }

    auto firstIntersection = intersections.minElement!(intersection => intersection[1].Distance);

    const Sphere sphere = firstIntersection[0];
    float tnear = intersections.front[1].Distance;

    vec3 surfaceColor = vec3(0f, 0f, 0f); // color of the ray/surfaceof the object intersected by the ray
    vec3 phit = rayorig + raydir * tnear; // point of intersection
    vec3 nhit = phit - sphere.center; // normal at the intersection point
    nhit.normalize(); // normalize normal direction

    // If the normal and the view direction are not opposite to each other
    // reverse the normal direction. That also means we are inside the sphere so set
    // the inside bool to true. Finally reverse the sign of IdotN which we want
    // positive.
    float bias = 1e-4; // add some bias to the point from which we will be tracing
    bool inside = false;
    if (raydir.dot(nhit) > 0)
    {
        nhit = -nhit;
        inside = true;
    }
    if (((sphere.transparency > 0 && options.transparency) || (sphere.reflection > 0 && options.reflections)) && depth < MAX_RAY_DEPTH)
    {
        float facingratio = -raydir.dot(nhit);
        // change the mix value to tweak the effect
        float fresneleffect = mix(pow(1 - facingratio, 3), 1, 0.1);
        // compute reflection direction (not need to normalize because all vectors
        // are already normalized)
        vec3 refldir = raydir - (nhit * 2).scale(raydir.dot(nhit));
        refldir.normalize();
        vec3 reflection = trace(options, phit + nhit * bias, refldir, spheres, depth + 1);
        vec3 refraction = 0;
        // if the sphere is also transparent compute refraction ray (transmission)
        if (sphere.transparency && options.transparency)
        {
            float ior = 1.1, eta = (inside) ? ior : 1 / ior; // are we inside or outside the surface?
            float cosi = -nhit.dot(raydir);
            float k = 1 - eta * eta * (1 - cosi * cosi);
            vec3 refrdir = raydir * eta + nhit.scale(eta * cosi - sqrt(k));
            refrdir.normalize();
            refraction = trace(options,phit - nhit * bias, refrdir, spheres, depth + 1);
        }
        // the result is a mix of reflection and refraction (if the sphere is transparent)
        vec3 fresnel = reflection.scale(fresneleffect);
        vec3 inverseFresnel = (1 - fresneleffect);
        vec3 translucence = refraction.scale(inverseFresnel).scale(vec3(sphere.transparency));
        vec3 finalTranslucence = (fresnel + translucence);
        vec3 finalColor = finalTranslucence.scale(sphere.surfaceColor);
        surfaceColor = finalColor;
    }
    else if(options.lighting)
    {
         // it's a diffuse object, no need to raytrace any further

        auto sphereLights = spheres.filter!(s=>s.emissionColor.x > 0);
        foreach(light; sphereLights)
        {
            vec3 transmission = vec3(1, 1, 1);
            vec3 lightDirection = light.center - phit;
            lightDirection.normalize();
            for (uint j = 0; j < spheres.length; ++j)
            {
                if (light != spheres[j])
                {
                    float t0, t1;
                    auto intersection = intersect(phit + nhit * bias,
                            lightDirection, spheres[j]);
                    if (intersection.Hit)
                    {
                        transmission = vec3(0, 0, 0);
                        break;
                    }
                }
            }

            if (transmission.length_squared > 0)
            {
                auto calculatedColor = sphere.surfaceColor.scale(std.math.fmax(0,
                        nhit.dot(lightDirection))).scale(light.emissionColor);
                surfaceColor += calculatedColor;
            }
        }
     }
     else
     {
         surfaceColor = sphere.surfaceColor;
     }

    surfaceColor = surfaceColor.clamp01();
    return surfaceColor + sphere.emissionColor;
}

vec3 clamp01(vec3 clamped)
{
    return vec3(clamped.x.clamp(0, 1), clamped.y.clamp(0, 1), clamped.z.clamp(0, 1));
}

vec3 scale(vec3 lhs, vec3 rhs)
{
    return vec3(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z);
}

vec3 scale(vec3 lhs, float rhs)
{
    return lhs * rhs;
}

//[comment]
// Main rendering function. We compute a camera ray for each pixel of the image
// trace it and return a color. If the ray hits a sphere, we return the color of the
// sphere at the intersection point, else we return the background color.
//[/comment]
vec3[] render(Spheres)(const RenderOptions options, const Spheres spheres, uint width, uint height)
{
    import std.parallelism;
    import std.algorithm;
    import std.range;

    immutable float invWidth = 1f / cast(float)(width);
    immutable float invHeight = 1f / cast(float)(height);
    immutable float fov = 30f;
    immutable float aspectratio = width / cast(float)(height);
    immutable float angle = tan(PI * 0.5f * fov / 180f);

    import std.functional;

    alias getRay = partial!(partial!(partial!(partial!(partial!(getRayForCoordinate,
            width), invWidth), invHeight), aspectratio), angle);

    auto rays = coordinates(width, height).map!(getRay)
        .map!(r => tuple(r.Index, trace(options, vec3(0), r.Ray, spheres, 0)));

    vec3[] image = new vec3[width * height];
    foreach (raycast; (rays))
    {
        image[raycast[0]] = raycast[1];
    }
    return image;
}

auto getRayForCoordinate(int width, float invWidth, float invHeight,
        float aspectratio, float angle, vec2i coord)
{
    int x = coord.x;
    int y = coord.y;
    float xx = (2 * ((x + 0.5) * invWidth) - 1) * angle * aspectratio;
    float yy = (1 - 2 * ((y + 0.5) * invHeight)) * angle;
    vec3 raydir = vec3(xx, yy, -1);
    raydir.normalize();
    return tuple!("Index", "Ray")(x + y * width, raydir);
}

unittest
{
    import std.range : array;
    import std.format : format;

    vec2i[] coords = coordinates(2, 2).array;
    vec2i[] expected = [vec2i(0, 0), vec2i(1, 0), vec2i(0, 1), vec2i(1, 1)];
    assert(coords == expected, format("Expected %s but got %s instead.", expected, coords));
}

auto coordinates(uint width, uint height)
{
    import std.algorithm : map, joiner;
    import std.range : iota;

    return iota(height).map!(y => iota(width).map!(x => vec2i(x, y))).joiner();
}
