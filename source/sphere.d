module sphere;

import std.typecons;
import std.math;

import gl3n.linalg;

class Sphere
{
    vec3 center;
    float radius;
    float radiusSquared;
    vec3 surfaceColor;
    vec3 emissionColor;
    float transparency;
    float reflection;
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
        radiusSquared = r * r;
        surfaceColor = sc;
        emissionColor = ec;
        transparency = transp;
        reflection = refl;
    }
}

struct IntersectionInfo
{
    this(float t0, float t1)
    {
        if(t0 < 0)
        {
            distance = t1;
        }
        else
        {
            distance = t0;
        }
    }

    private float distance; //first intersection
    @property public bool Hit(){return !distance.isNaN;}
    @property public float Distance(){return distance;}
}

IntersectionInfo intersect(vec3 origin, vec3 direction, const Sphere sphere)
{
    import std.math : sqrt;
    
    vec3 l = sphere.center - origin;
    float tca = l.dot(direction);
    if (tca < 0)
    {
        return IntersectionInfo.init;
    }
    float d2 = l.dot(l) - tca * tca;
    if (d2 > sphere.radiusSquared)
    {
        return IntersectionInfo.init;
    }
    float thc = sqrt(sphere.radiusSquared - d2);
    float t0 = tca - thc;
    float t1 = tca + thc;

    return IntersectionInfo(t0, t1);
}