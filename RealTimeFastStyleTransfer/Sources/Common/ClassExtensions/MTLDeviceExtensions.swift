//
//  MTLDeviceExtensions.swift
//  RealTimeFastStyleTransfer
//
//  Created by Hrebeniuk Dmytro on 04.05.2020.
//  Copyright © 2020 Hrebeniuk Dmytro. All rights reserved.
//



import Metal
import CoreVideo

extension MTLDevice {
	
	func createTexture(from pixelBuffer: CVPixelBuffer, textureCache: CVMetalTextureCache? = nil, format: MTLPixelFormat = .bgra8Unorm) -> MTLTexture? {
		let width = CVPixelBufferGetWidth(pixelBuffer)
		let height = CVPixelBufferGetHeight(pixelBuffer)
				
		var cvMetalTexture: CVMetalTexture?
		
		var currentTextureCache: CVMetalTextureCache? = textureCache
		
		if currentTextureCache == nil {
			guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, self, nil, &currentTextureCache) == kCVReturnSuccess
				else {
					return nil
			}
		}
		
		guard let metalTextureCache = currentTextureCache else {
			return nil
		}
		
		let status = CVMetalTextureCacheCreateTextureFromImage(nil,
															   metalTextureCache, pixelBuffer, nil, format, width, height, 0, &cvMetalTexture)
		
		var texture: MTLTexture?
		if(status == kCVReturnSuccess) {
			texture = CVMetalTextureGetTexture(cvMetalTexture!)
		}
		
		return texture
	}
    
    
    public func createFloatTexture(from bytes: UnsafeRawPointer, width: Int, height: Int) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba32Float, width: width, height: height, mipmapped: false)

        let texture = self.makeTexture(descriptor: textureDescriptor)
        texture?.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: bytes, bytesPerRow: MemoryLayout<Float32>.stride*width*height*4)

        return texture
    }
    
}
