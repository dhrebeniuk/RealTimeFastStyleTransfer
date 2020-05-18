//
//  TextureCacheManager.swift
//  RealTimeFastStyleTransfer
//
//  Created by Hrebeniuk Dmytro on 04.05.2020.
//  Copyright © 2020 Hrebeniuk Dmytro. All rights reserved.
//


import Metal
import CoreMedia
import CoreVideo

class TextureCacheManager {
	private var textureCache: CVMetalTextureCache?
	private let device: MTLDevice
	
	init?(device: MTLDevice) {
		self.device = device
	guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache) == kCVReturnSuccess
		else {
			return nil
        }
	}

	func createOutputTexture(width: Int, height: Int, format: MTLPixelFormat = .bgra8Unorm) -> MTLTexture? {
		
		let pixelBufferPool = CVPixelBufferPool.createPixelBufferPool(width: Float(width), height: Float(height))
		
		let result = pixelBufferPool.flatMap() {
            CVPixelBuffer.createPixelBuffer(in: $0).flatMap() { createTexture(from: $0, format: format) }
		}
		
		return result
	}
	
	private func createTexture(from pixelBuffer: CVPixelBuffer, format: MTLPixelFormat = .bgra8Unorm) -> MTLTexture? {
        return self.device.createTexture(from: pixelBuffer, textureCache: textureCache, format: format)
	}
    
    func createOutputTextureArray(width: Int, height: Int, arrayLength: Int) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor()

        textureDescriptor.textureType = .type2DArray
        textureDescriptor.pixelFormat = .bgra8Unorm
        textureDescriptor.width = width
        textureDescriptor.height = height
        textureDescriptor.arrayLength = arrayLength
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        
        let arrayTexture = device.makeTexture(descriptor: textureDescriptor)
        
//        for index in 0..<arrayLength {
//            if let texture = createOutputTexture(width: width, height: height), let bytes = texture.buffer?.contents() {
//                let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: width, height: height, depth: 4))
//                arrayTexture?.replace(region: region, mipmapLevel: 0, slice: index, withBytes: bytes, bytesPerRow: texture.bufferBytesPerRow, bytesPerImage: texture.bufferBytesPerRow*height)
//            }
//        }
//        func append(_ texture: MTLTexture) -> Bool {
//            if let bytes = texture.buffer?.contents() {
//                let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: width, height: height, depth: 4))
//
//                arrayTexture?.replace(region: region, mipmapLevel: 0, withBytes: bytes, bytesPerRow: texture.bufferBytesPerRow)
//
//                return true
//            }
//
//            return false
//        }
        
        return arrayTexture

    }
}
