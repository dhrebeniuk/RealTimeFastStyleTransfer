//
//  SamplesRenderer.swift
//  RealTimeFastStyleTransfer
//
//  Created by Hrebeniuk Dmytro on 04.05.2020.
//  Copyright © 2020 Hrebeniuk Dmytro. All rights reserved.
//


import Metal
import CoreMedia

class SamplesMetalRenderer {

	private var device: MTLDevice?
	private var commandQueue: MTLCommandQueue?
	private var samplesImporter: SamplesImporter?
	
	init(device: MTLDevice?, commandQueue: MTLCommandQueue?, samplesImporter: SamplesImporter?) {
		self.device = device
		self.commandQueue = commandQueue
		self.samplesImporter = samplesImporter
	}
	
	private var renderPipelineState: MTLRenderPipelineState?
	private var lastTexture: MTLTexture?
	private var commandBuffer: MTLCommandBuffer?
	
	func setup() {
		self.commandQueue = self.device?.makeCommandQueue(maxCommandBufferCount: 1)
		self.initializeRenderPipelineState()
		self.samplesImporter?.setup()
	}
	
	private func initializeRenderPipelineState() {
		guard let device = self.device,
			let library = device.makeDefaultLibrary() else {
				return
		}
		
		let pipelineDescriptor = MTLRenderPipelineDescriptor()
		pipelineDescriptor.sampleCount = 1
		pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
		pipelineDescriptor.depthAttachmentPixelFormat = .invalid
		
		pipelineDescriptor.vertexFunction = library.makeFunction(name: "mapTexture")
		pipelineDescriptor.fragmentFunction = library.makeFunction(name: "displayBackTexture")
		
		do {
			try self.renderPipelineState = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
		}
		catch {
			assertionFailure("Failed creating a render state pipeline. Can't render the texture without one.")
			return
		}
	}
	
	func render(with renderPassDescriptor: MTLRenderPassDescriptor, drawable: MTLDrawable) {
		guard let texture = self.lastTexture else {
			return
		}
		
		guard let renderPipelineState = self.renderPipelineState
			else {
				return
		}
		
		guard let commandBuffer = self.commandQueue?.makeCommandBuffer() else {
			return
		}

		let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
		encoder?.pushDebugGroup("RenderFrame")
		encoder?.setRenderPipelineState(renderPipelineState)
		encoder?.setFragmentTexture(texture, index: 0)
		encoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
		encoder?.popDebugGroup()
		encoder?.endEncoding()
		
		commandBuffer.present(drawable)
		commandBuffer.commit()
	}
	
	func send(sampleBuffer: CMSampleBuffer) {
        let texture = self.samplesImporter?.fetch(sampleBuffer: sampleBuffer)
		self.lastTexture = texture
	}
	
	func requestRenderedTexture() -> MTLTexture? {
		return self.lastTexture
	}
	
}
