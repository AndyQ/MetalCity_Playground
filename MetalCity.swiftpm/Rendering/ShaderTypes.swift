//
//  ShaderTypes.h
//  MetalSample
//
//  Created by Andy Qua on 28/06/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import simd

//
//  Contains types and enum constants shared between Metal shaders and Swift/ObjC source

struct Vertex {
    var position: SIMD4<Float>
    var normal: SIMD4<Float>
    var color: SIMD4<Float>
    var texCoords: SIMD2<Float>
}


struct Uniforms
{
    var viewProjectionMatrix : simd_float4x4
}

struct PerInstanceUniforms
{
    var modelMatrix : simd_float4x4
    var normalMatrix : simd_float3x3
    var r : Float = 0
    var g : Float = 0
    var b : Float = 0
    var a : Float = 0
    var textureNr : Int32 = 0
}


