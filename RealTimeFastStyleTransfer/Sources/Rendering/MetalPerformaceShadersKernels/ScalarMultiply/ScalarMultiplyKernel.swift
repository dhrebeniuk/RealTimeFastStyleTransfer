//
//  ScalarMultiplyKernel.swift
//  RealTimeFastStyleTransfer
//
//  Created by Hrebeniuk Dmytro on 20.05.2020.
//  Copyright © 2020 Hrebeniuk Dmytro. All rights reserved.
//

import Metal
import MetalPerformanceShaders

struct ScalarMultiplyUniforms {
    var multiply: Float
}

open class ScalarMultiplyKernel {
    
    let device: MTLDevice
    
    let name: String = "ScalarMultiply"
    
    var multiply: Float = 1.0

    private var scalarMultiplyComputePipelineState: MTLComputePipelineState?
    private var arrayScalarMultiplyComputePipelineState: MTLComputePipelineState?

    public init(device: MTLDevice, multiply: Float) {
        self.device = device
        self.multiply = multiply
        
        let defaultLibrary = device.makeDefaultLibrary()
        if let computeShader = defaultLibrary?.makeFunction(name: "scalar_multiply_kernel") {
            if let computePipelineState = try? self.device.makeComputePipelineState(function: computeShader) {
                self.scalarMultiplyComputePipelineState = computePipelineState
            }
        }
        
        if let computeShader = defaultLibrary?.makeFunction(name: "array_scalar_multiply_kernel") {
            if let computePipelineState = try? self.device.makeComputePipelineState(function: computeShader) {
                self.arrayScalarMultiplyComputePipelineState = computePipelineState
            }
        }
  }

    public func encode(commandBuffer: MTLCommandBuffer, sourceImage: MPSImage, destinationImage: MPSImage) {
        if let encoder = commandBuffer.makeComputeCommandEncoder() {
            encoder.pushDebugGroup(name)
            
            var computePipelineState: MTLComputePipelineState?
            if sourceImage.textureType == .type2DArray {
                computePipelineState = self.arrayScalarMultiplyComputePipelineState
            }
            else {
                computePipelineState = self.scalarMultiplyComputePipelineState
            }
                 
            computePipelineState.map { encoder.setComputePipelineState($0) }
            
            var scalarMultiplyUniform = ScalarMultiplyUniforms(multiply: multiply)
            let buffer = device.makeBuffer(bytes: &scalarMultiplyUniform, length: MemoryLayout<ScalarMultiplyUniforms>.size, options: [])
            encoder.setBuffer(buffer, offset: 0, index: 0)
            
            encoder.setTexture(sourceImage.texture, index: 0)
            encoder.setTexture(destinationImage.texture, index: 1)
            
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

    }
}
