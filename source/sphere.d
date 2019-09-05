module sphere;

import gl3n.linalg;

struct sphere
{
    vec3 center;                           /// position of the sphere
    float radius, radius2;                  /// sphere radius and radius^2
    vec3 surfaceColor, emissionColor;      /// surface color and emission (light)
    float transparency, reflection;         /// surface transparency and reflectivity
    this(
        vec3 c,
        float r,
        vec3 sc,
        float refl = 0,
        float transp = 0,
        vec3 ec = 0)
    {
        center = c;
        radius = r;
        radius2 = r * r;
        surfaceColor = sc;
        emissionColor = ec;
        transparency = transp;
        reflection = refl;
    }
    //[comment]
    // Compute a ray-sphere intersection using the geometric solution
    //[/comment]
    bool intersect(vec3 rayorig, vec3 raydir, out float t0, out float t1) const
    {
        import std.math;

        import std.stdio;
        
        vec3 l = center - rayorig;
        float tca = l.dot(raydir);
        if (tca < 0)
        {
            return false;
        }
        float d2 = l.dot(l) - tca * tca;
        if (d2 > radius2)
        {
            return false;
        }
        float thc = std.math.sqrt(radius2 - d2);
        t0 = tca - thc;
        t1 = tca + thc;

        return true;
    }
}