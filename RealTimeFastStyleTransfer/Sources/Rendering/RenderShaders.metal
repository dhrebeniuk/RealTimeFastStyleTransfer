//
//  Shaders.metal
//  RealTimeFastStyleTransfer
//
//  Created by Hrebeniuk Dmytro on 04.05.2020.
//  Copyright © 2020 Hrebeniuk Dmytro. All rights reserved.
//


#include <metal_stdlib>
using namespace metal;

typedef struct {
	float4 renderedCoordinate [[position]];
	float2 textureCoordinate;
} TextureMappingVertex;

vertex TextureMappingVertex mapTexture(unsigned int vertex_id [[ vertex_id ]]) {
	float4x4 renderedCoordinates = float4x4(float4( -1.0, -1.0, 0.0, 1.0 ),	  /// (x, y, depth, W)
											float4(  1.0, -1.0, 0.0, 1.0 ),
											float4( -1.0,  1.0, 0.0, 1.0 ),
											float4(  1.0,  1.0, 0.0, 1.0 ));
	
	float4x2 textureCoordinates = float4x2(float2( 0.0, 1.0 ), /// (x, y)
										   float2( 1.0, 1.0 ),
										   float2( 0.0, 0.0 ),
										   float2( 1.0, 0.0 ));
	TextureMappingVertex outVertex;
	outVertex.renderedCoordinate = renderedCoordinates[vertex_id];
	outVertex.textureCoordinate = textureCoordinates[vertex_id];
	
	return outVertex;
}

fragment half4 displayBackTexture(TextureMappingVertex mappingVertex [[ stage_in ]],
							  texture2d<float, access::sample> luminanceTexture [[ texture(0) ]]) {
	constexpr sampler s(address::clamp_to_edge, filter::linear);

	
	float4 luminance = luminanceTexture.sample(s, mappingVertex.textureCoordinate);
	
	
	return half4(luminance);
}

