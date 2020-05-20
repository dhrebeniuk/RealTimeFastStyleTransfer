//
//  CocantenateKernel.swift
//  RealTimeFastStyleTransfer
//
//  Created by Hrebeniuk Dmytro on 11.05.2020.
//  Copyright © 2020 Dmytro Hrebeniuk. All rights reserved.
//

import Metal
import MetalPerformanceShaders

open class CocantenateKernel {
    
    let device: MTLDevice
    
    let name: String = "Cocantenate"
    let additionImage: MPSImage

    private var cocantenatePipelineState: MTLComputePipelineState?
    private var arrayCocantenatePipelineState: MTLComputePipelineState?

    public init(device: MTLDevice, additionImage: MPSImage) {
        self.device = device
        self.additionImage = additionImage
    
        let defaultLibrary = device.makeDefaultLibrary()
        if let computeShader = defaultLibrary?.makeFunction(name: "cocantenate_textures") {
            if let computePipelineState = try? self.device.makeComputePipelineState(function: computeShader) {
                self.cocantenatePipelineState = computePipelineState
            }
        }
        
        if let computeShader = defaultLibrary?.makeFunction(name: "cocantenate_textures_narray") {
            if let computePipelineState = try? self.device.makeComputePipelineState(function: computeShader) {
                self.arrayCocantenatePipelineState = computePipelineState
            }
        }
  }

    public func encode(commandBuffer: MTLCommandBuffer, sourceImage: MPSImage, destinationImage: MPSImage) {
        if let encoder = commandBuffer.makeComputeCommandEncoder() {
            encoder.pushDebugGroup(name)
            
            var computePipelineState: MTLComputePipelineState?
            if sourceImage.textureType == .type2DArray {
                computePipelineState = self.arrayCocantenatePipelineState
            }
            else {
                computePipelineState = self.cocantenatePipelineState
            }
                 
            computePipelineState.map { encoder.setComputePipelineState($0) }
            
            encoder.setTexture(sourceImage.texture, index: 0)
            encoder.setTexture(additionImage.texture, index: 1)
            encoder.setTexture(destinationImage.texture, index: 2)
            
            let threadGroupSize = MTLSize(width: 32, height: 32, depth: 1)
            let groupsCount = MTLSize(width: sourceImage.width/threadGroupSize.width+1,
                                      height: sourceImage.height/threadGroupSize.height+1,
                                      depth: 1)
            encoder.dispatchThreadgroups(threadGroupSize, threadsPerThreadgroup: groupsCount)

            encoder.popDebugGroup()
            encoder.endEncoding()
        }

        // Let Metal know the temporary image can be recycled.
        if let image = sourceImage as? MPSTemporaryImage {
            image.readCount -= 1
        }

        if let image = additionImage as? MPSTemporaryImage {
            image.readCount -= 1
        }
    
    }
}
