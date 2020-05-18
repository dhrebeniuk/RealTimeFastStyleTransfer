//
//  YUVImporterShaders.metal
//  RealTimeFastStyleTransfer
//
//  Created by Hrebeniuk Dmytro on 04.05.2020.
//  Copyright © 2020 Hrebeniuk Dmytro. All rights reserved.
//


#include <metal_stdlib>
using namespace metal;

kernel void yuvComputeKernel(texture2d<float, access::read> luminanceTexture [[ texture(0) ]],
							 texture2d<float, access::read> chrominanceTexture [[ texture(1) ]],
							 texture2d<float, access::write> destinationTexture [[ texture(2) ]],
							 uint2 coordinate [[ thread_position_in_grid ]]) {
    // BT.601 full range (ref: http://www.equasys.de/colorconversion.html)
    float3x3 BT601Matrix = float3x3(float3(1.0, 1.0, 1.0),
                               float3(0.0, -0.343, 1.765),
                               float3(1.4, -0.711, 0.0));
	
	float4 luminance = luminanceTexture.read(coordinate);
	float4 chrominance = chrominanceTexture.read(coordinate/2);
	
	float3 yuv = float3(luminance[0], chrominance[0] - 0.5, chrominance[1] - 0.5);
	float3 rgb = BT601Matrix*yuv;
	float4 rgba = float4(rgb[0], rgb[1], rgb[2], 1.0);
	
	destinationTexture.write(rgba, coordinate);
}
