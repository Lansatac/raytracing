module render;

import std.stdio;

import std.typecons;
import std.math;

import gl3n.linalg;

import sphere;

//[comment]
// This variable controls the maximum recursion depth
//[/comment]
enum MAX_RAY_DEPTH = 5;

float mix(const float a, const float b, const float mix)
{
    return b * mix + a * (1 - mix);
}

//[comment]
// This is the main trace function. It takes a ray as argument (defined by its origin
// and direction). We test if this ray intersects any of the geometry in the scene.
// If the ray intersects an object, we compute the intersection point, the normal
// at the intersection point, and shade this point using this information.
// Shading depends on the surface property (is it transparent, reflective, diffuse).
// The function returns a color for the ray. If the ray intersects an object that
// is the color of the object at the intersection point, otherwise it returns
// the background color.
//[/comment]
vec3 trace(
    const vec3 rayorig,
    const vec3 raydir,
    const sphere[] spheres,
    const int depth)
{
    import std.typecons;

    //if (raydir.length() != 1) std::cerr << "Error " << raydir << std::endl;
    float tnear = float.infinity;
    Nullable!sphere sphere;
    // find intersection of this ray with the sphere in the scene
    for (uint i = 0; i < spheres.length; ++i) {
        float t0 = float.infinity, t1 = float.infinity;
        if (spheres[i].intersect(rayorig, raydir, t0, t1))
        {
            if (t0 < 0) t0 = t1;
            if (t0 < tnear) {
                tnear = t0;
                sphere = spheres[i];
            }
        }
    }
    // if there's no intersection return black or background color
    if (sphere.isNull)
    	return vec3(0.4, 0.4, 1);

    vec3 surfaceColor = vec3(0f,0f,0f); // color of the ray/surfaceof the object intersected by the ray
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
    if ((sphere.transparency > 0 || sphere.reflection > 0) && depth < MAX_RAY_DEPTH) {
        float facingratio = -raydir.dot(nhit);
        // change the mix value to tweak the effect
        float fresneleffect = mix(pow(1 - facingratio, 3), 1, 0.1);
        // compute reflection direction (not need to normalize because all vectors
        // are already normalized)
        vec3 refldir = raydir - (nhit * 2).scale(raydir.dot(nhit));
        refldir.normalize();
        vec3 reflection = trace(phit + nhit * bias, refldir, spheres, depth + 1);
        vec3 refraction = 0;
        // if the sphere is also transparent compute refraction ray (transmission)
        if (sphere.transparency) {
            float ior = 1.1, eta = (inside) ? ior : 1 / ior; // are we inside or outside the surface?
            float cosi = -nhit.dot(raydir);
            float k = 1 - eta * eta * (1 - cosi * cosi);
            vec3 refrdir = raydir * eta + nhit.scale(eta *  cosi - sqrt(k));
            refrdir.normalize();
            refraction = trace(phit - nhit * bias, refrdir, spheres, depth + 1);
        }
        // the result is a mix of reflection and refraction (if the sphere is transparent)
        vec3 fresnel = reflection.scale(fresneleffect);
        //debug writeln(fresnel);
        vec3 inverseFresnel = (1 - fresneleffect);
        //debug writefln("refraction=%s",refraction);
        vec3 translucence = refraction.scale(inverseFresnel).scale(vec3(sphere.transparency));
        //debug writefln("translucence=%s",translucence);
        vec3 finalTranslucence = (fresnel + translucence);
        //debug writefln("final translucence=%s fresnel=%s translucence=%s",finalTranslucence, fresnel, translucence);
        vec3 finalColor = finalTranslucence.scale(sphere.surfaceColor);
        //debug writefln("final color=%s",finalColor);
        surfaceColor = finalColor;
        //surfaceColor = refraction * vec3(sphere.transparency) + sphere.surfaceColor;
    }
    else {
        // it's a diffuse object, no need to raytrace any further
        for (uint i = 0; i < spheres.length; ++i) {
            if (spheres[i].emissionColor.x > 0) {
                // this is a light
                vec3 transmission = vec3(1, 1, 1);
                vec3 lightDirection = spheres[i].center - phit;
                lightDirection.normalize();
                for (uint j = 0; j < spheres.length; ++j) {
                    if (i != j) {
                        float t0, t1;
                        if (spheres[j].intersect(phit + nhit * bias, lightDirection, t0, t1)) {
                            transmission = vec3(0,0,0);
                            break;
                        }
                    }
                }
                surfaceColor += sphere.surfaceColor.scale(transmission).scale(
                std.math.fmax(0, nhit.dot(lightDirection))).scale(spheres[i].emissionColor);
            }
        }
    }

    return surfaceColor + sphere.emissionColor;
}

vec3 scale(vec3 lhs, vec3 rhs)
{
    return vec3(
        lhs.x * rhs.x,
        lhs.y * rhs.y,
        lhs.z * rhs.z
        );
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
vec3[] render(const sphere[] spheres, uint width, uint height)
{
    import std.parallelism;
    import std.algorithm;

    float invWidth = 1f / cast(float)(width);
    float invHeight = 1f / cast(float)(height);
    float fov = 30f;
    float aspectratio = width / cast(float)(height);
    float angle = tan(PI * 0.5f * fov / 180f);

    Tuple!(uint, "Index", vec3, "Ray")[] rays;
    // Trace rays
    uint i = 0;
    for (uint y = 0; y < height; ++y) {
        for (uint x = 0; x < width; ++x, ++i) {
            float xx = (2 * ((x + 0.5) * invWidth) - 1) * angle * aspectratio;
            float yy = (1 - 2 * ((y + 0.5) * invHeight)) * angle;
            vec3 raydir = vec3(xx, yy, -1);
            raydir.normalize();
            rays ~= tuple!("Index", "Ray")(i, raydir);
        }
    }
    auto rayCats = std.algorithm.map!(r=>tuple(r.Index, trace(vec3(0), r.Ray, spheres, 0)))(rays);

    vec3[] image = new vec3[width * height];
    foreach(raycast; parallel(rayCats))
    {
        image[raycast[0]] = raycast[1];
    }
    return image;
}