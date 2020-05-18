//
//  YUVImporter.swift
//  RealTimeFastStyleTransfer
//
//  Created by Hrebeniuk Dmytro on 04.05.2020.
//  Copyright © 2020 Hrebeniuk Dmytro. All rights reserved.
//

import Metal
import CoreMedia
import UIKit

protocol YUVImporter {
	func setup()
	
	func performImport(imageBuffer: CVPixelBuffer, in commandBuffer: MTLCommandBuffer?) -> MTLTexture?
    
    func fetch() -> MTLTexture?
}

class YUVImporterMetal: YUVImporter {
	
	private var device: MTLDevice?
	
	init(device: MTLDevice?) {
		self.device = device
	}
	
	private var computePipelineState: MTLComputePipelineState?
	
	func setup() {
        let bundle = Bundle(for: Self.self)
        let defaultLibrary = try? self.device?.makeDefaultLibrary(bundle: bundle)
        let computeShader = defaultLibrary?.makeFunction(name: "yuvComputeKernel")
		computeShader.map() { shader in
			do {
				self.computePipelineState = try self.device?.makeComputePipelineState(function: shader)
			}
			catch {
			}
		}
	}
    
    func fetch() -> MTLTexture? {
        return outTexture
    }

	private var pixelBufferPool: CVPixelBufferPool?
	private var pixelBuffer: CVPixelBuffer?
	private var outTexture: MTLTexture?
	
	private var textureWidth: Int = 0
	private var textureHeight: Int = 0
	
	private var textureCache: CVMetalTextureCache?

	func performImport(imageBuffer: CVPixelBuffer, in commandBuffer: MTLCommandBuffer?) -> MTLTexture? {
		guard let metalDevice = self.device else {
			return nil
		}


        if self.textureWidth != CVPixelBufferGetWidth(imageBuffer), self.textureHeight != CVPixelBufferGetHeight(imageBuffer) {
			self.pixelBufferPool = nil
			self.textureCache = nil
		}
		
		if textureCache == nil {
			guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice, nil, &textureCache) == kCVReturnSuccess
				else {
					return nil
			}
		}
		
		self.textureWidth = CVPixelBufferGetWidth(imageBuffer)
		self.textureHeight = CVPixelBufferGetHeight(imageBuffer)
		
		guard let luminanceTexture = self.createLuminanceTexture(from: imageBuffer, textureCache: textureCache) else {
			return nil
		}
		
		guard let chrominanceTexture = self.createChrominanceTexture(from: imageBuffer, textureCache: textureCache) else {
			return nil
		}
		
		guard let computePipelineState = self.computePipelineState else {
			return nil
		}
		
		if self.pixelBufferPool == nil {
			self.pixelBufferPool = CVPixelBufferPool.createPixelBufferPool(width: Float(CVPixelBufferGetWidth(imageBuffer)), height: Float(CVPixelBufferGetHeight(imageBuffer)))
			
			self.pixelBuffer = CVPixelBuffer.createPixelBuffer(in: self.pixelBufferPool!)
			
            self.outTexture = self.device?.createTexture(from: self.pixelBuffer!, textureCache: textureCache)
		}
		
		guard let compute = commandBuffer?.makeComputeCommandEncoder() else {
			return nil
		}
		
		compute.setComputePipelineState(computePipelineState)
		compute.setTexture(luminanceTexture, index: 0)
		compute.setTexture(chrominanceTexture, index: 1)
		compute.setTexture(self.outTexture, index: 2)
		
		let viewWidth = Int(luminanceTexture.width)
		let viewHeight = Int(luminanceTexture.height)
		
		let threadGroupSize = MTLSize(width: 8, height: 8, depth: 1)
		let groupsCount = MTLSize(width: viewWidth/threadGroupSize.width+1,
								  height: viewHeight/threadGroupSize.height+1,
								  depth: 1)
		
		compute.dispatchThreadgroups(groupsCount, threadsPerThreadgroup: threadGroupSize)
		
		compute.endEncoding()

        return self.outTexture
	}

	private func createLuminanceTexture(from imageBuffer: CVImageBuffer, textureCache: CVMetalTextureCache?) -> MTLTexture? {
		let width = CVPixelBufferGetWidth(imageBuffer)
		let height = CVPixelBufferGetHeight(imageBuffer)
        
        let correctedWidth = (width%2 == 0) ? width : width - 1
        let correctedHeight = (height%2 == 0) ? height : height - 1

		var imageTexture: CVMetalTexture?
		let result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache!, imageBuffer, nil, .r8Unorm, correctedWidth, correctedHeight, 0, &imageTexture)
		
		guard
			let unwrappedImageTexture = imageTexture,
			let texture = CVMetalTextureGetTexture(unwrappedImageTexture),
			result == kCVReturnSuccess
			else {
				return nil
		}
		
		return texture
	}
	
	private func createChrominanceTexture(from imageBuffer: CVImageBuffer, textureCache: CVMetalTextureCache?) -> MTLTexture? {
		let width = CVPixelBufferGetWidth(imageBuffer)/2
		let halfOfWidth = (width%2 == 0) ? width : width - 1
		
		let height = CVPixelBufferGetHeight(imageBuffer)/2
		let halfOfHeight = (height%2 == 0) ? height : height - 1
		
		var imageTexture: CVMetalTexture?
		let result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache!, imageBuffer, nil, .bgrg422, halfOfWidth, halfOfHeight, 1, &imageTexture)
		
		guard
			let unwrappedImageTexture = imageTexture,
			let texture = CVMetalTextureGetTexture(unwrappedImageTexture),
			result == kCVReturnSuccess
			else {
				return nil
		}
		
		return texture
	}
	
}


