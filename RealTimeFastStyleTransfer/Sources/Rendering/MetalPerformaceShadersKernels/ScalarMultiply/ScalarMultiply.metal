//
//  ScalarMultiplyFilter.metal
//  RealTimeFastStyleTransfer
//
//  Created by Hrebeniuk Dmytro on 23.04.2020.
//  Copyright © 2020 Dmytro Hrebeniuk. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct ScalarMultiplyUniforms {
    float multiply;
};

kernel void scalar_multiply_kernel(texture2d<float, access::read> inputTexture [[ texture(0) ]],
                      texture2d<float, access::write> outputTexture [[ texture(1) ]],
                      constant ScalarMultiplyUniforms &params [[buffer(0)]],
                      uint2 coordinate [[ thread_position_in_grid ]]) {
    
    float4 color = inputTexture.read(coordinate);
    
    float4 adjustedColor = color*params.multiply;

    outputTexture.write(adjustedColor, coordinate);
}

kernel void array_scalar_multiply_kernel(texture2d_array<float, access::read> inputTexture [[ texture(0) ]],
                      texture2d_array<float, access::write> outputTexture [[ texture(1) ]],
                      constant ScalarMultiplyUniforms &params [[buffer(0)]],
                      uint2 coordinate [[ thread_position_in_grid ]]) {
    
    for (unsigned int textureIndex=0; textureIndex < inputTexture.get_array_size(); textureIndex++) {
        float4 color = inputTexture.read(coordinate, textureIndex);

        float4 adjustedColor = float4(color.r, color.g, color.b, color.a)*params.multiply;

        outputTexture.write(adjustedColor, coordinate, textureIndex);
    }
}
