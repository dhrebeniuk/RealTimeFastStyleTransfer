//
//  SamplesImporter.swift
//  RealTimeFastStyleTransfer
//
//  Created by Hrebeniuk Dmytro on 04.05.2020.
//  Copyright © 2020 Hrebeniuk Dmytro. All rights reserved.
//


import Metal
import CoreMedia

protocol SamplesImporter {
	
	func setup()
		
	func fetch(sampleBuffer: CMSampleBuffer) -> MTLTexture?
    
}

class SamplesMetalImporter: SamplesImporter {

	private var device: MTLDevice? = MTLCreateSystemDefaultDevice()
	private var commandQueue: MTLCommandQueue?
	private let yuvImporter: YUVImporter
    
	init(device: MTLDevice?, commandQueue: MTLCommandQueue?) {
		self.device = device
		self.commandQueue = commandQueue
		self.yuvImporter = YUVImporterMetal(device: device)
	}
	
	func setup() {
		self.yuvImporter.setup()
	}
	
	func fetch(imageBuffer: CVPixelBuffer, waitUntilCompleted: Bool = false) -> MTLTexture?  {
		var resultTexture: MTLTexture? = nil
		
		if let commandBuffer = self.commandQueue?.makeCommandBuffer() {
			let texture = self.yuvImporter.performImport(imageBuffer: imageBuffer, in: commandBuffer)
			
			resultTexture = self.applyFilters(for: texture, imageBuffer: imageBuffer, in: commandBuffer)
			
			commandBuffer.commit()
			
			if waitUntilCompleted {
				commandBuffer.waitUntilCompleted()
			}
		}

		return resultTexture
	}
	
	private func applyFilters(for texture: MTLTexture?, imageBuffer: CVPixelBuffer?, in commandBuffer: MTLCommandBuffer?) -> MTLTexture? {
        
        // TODO: Need implement
		
		return texture
	}
	
	func fetch(sampleBuffer: CMSampleBuffer) -> MTLTexture?  {
		guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
			return nil
		}
		
		return self.fetch(imageBuffer: imageBuffer)
	}
	
}
