
import gl3n.linalg;

unittest
{
    import std.format : format;

    assert(PackedPixelRGBA(vec3(0,0,1)) == 0x0000FFFF,
        format("Expected %#X, but it was %#X", 0x0000FFFF, PackedPixelRGBA(vec3(0,0,1))));
    assert(PackedPixelRGBA(vec3(0,1,0)) == 0x00FF00FF);
    assert(PackedPixelRGBA(vec3(1,0,0)) == 0xFF0000FF);
    assert(PackedPixelRGBA(vec3(1,1,1)) == 0xFFFFFFFF);
    assert(PackedPixelRGBA(vec3(0,0,0)) == 0x000000FF);
}

//Packs a vector3 into an ARGB int
uint PackedPixelRGBA(vec3 color)
{
    return PackedPixelRGBA(vec4(color.r, color.g, color.b, 1f));
}

uint PackedPixelRGBA(vec4 color)
{
    uint red = cast(ubyte)(color.r * (ubyte.max));
    uint green = cast(ubyte)(color.g * (ubyte.max));
    uint blue = cast(ubyte)(color.b * (ubyte.max));
    uint alpha = cast(ubyte)(color.a * (ubyte.max));
    
    return (alpha << 0) | (blue << 8) | (green << 16) | (red << 24);
}