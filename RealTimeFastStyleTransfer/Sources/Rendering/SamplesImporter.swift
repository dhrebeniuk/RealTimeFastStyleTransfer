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

	private let device: MTLDevice?
	private let commandQueue: MTLCommandQueue?
	private let yuvImporter: YUVImporter
    private let styleTransferFilter: StyleTransferFilter
    
	init(device: MTLDevice?, commandQueue: MTLCommandQueue?) {
		self.device = device
		self.commandQueue = commandQueue
		self.yuvImporter = YUVImporterMetal(device: device)
        self.styleTransferFilter = StyleTransferFilter(device: device)
	}
	
	func setup() {
		self.yuvImporter.setup()
	}
	
	func fetch(imageBuffer: CVPixelBuffer, waitUntilCompleted: Bool = false) -> MTLTexture?  {
		var resultTexture: MTLTexture? = nil
		
		if let commandBuffer = self.commandQueue?.makeCommandBuffer() {
			let texture = self.yuvImporter.performImport(imageBuffer: imageBuffer, in: commandBuffer)
			
			resultTexture = texture.flatMap { styleTransferFilter.applyEffect(inputTexture: $0, in: commandBuffer) }  ?? texture
			
			commandBuffer.commit()
			
			if waitUntilCompleted {
				commandBuffer.waitUntilCompleted()
			}
		}

		return resultTexture
	}
    
	func fetch(sampleBuffer: CMSampleBuffer) -> MTLTexture?  {
		guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
			return nil
		}
		
		return self.fetch(imageBuffer: imageBuffer)
	}
	
}
