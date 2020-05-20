//
//  CocantenateKernel.metal
//  RealTimeFastStyleTransfer
//
//  Created by Hrebeniuk Dmytro on 02.03.2020.
//  Copyright © 2020 Dmytro Hrebeniuk. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void cocantenate_textures(texture2d<half, access::read> inputTexture1 [[ texture(0) ]],
                                    texture2d<half, access::read> inputTexture2 [[ texture(1) ]],
                                    texture2d<half, access::write> outputTexture [[ texture(2) ]],
                                    uint2 coordinate [[ thread_position_in_grid ]]) {
    
    half4 color1 = inputTexture1.read(coordinate);
    half4 color2 = inputTexture2.read(coordinate);

    half4 adjustedColor = color1 + color2;

    outputTexture.write(adjustedColor, coordinate);
}

kernel void cocantenate_textures_narray(texture2d_array<half, access::read> inputTexture1 [[ texture(0) ]],
                                    texture2d_array<half, access::read> inputTexture2 [[ texture(1) ]],
                                    texture2d_array<half, access::write> outputTexture [[ texture(2) ]],
                                    uint2 coordinate [[ thread_position_in_grid ]]) {
    
    for (unsigned int textureIndex=0; textureIndex < inputTexture1.get_array_size(); textureIndex++) {
        half4 color1 = inputTexture1.read(coordinate, textureIndex);
        half4 color2 = inputTexture2.read(coordinate, textureIndex);

        half4 adjustedColor = color1 + color2;

        outputTexture.write(adjustedColor, coordinate, textureIndex);
    }
}

