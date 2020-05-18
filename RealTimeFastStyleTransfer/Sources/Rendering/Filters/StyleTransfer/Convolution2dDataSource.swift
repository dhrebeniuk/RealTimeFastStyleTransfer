//
//  Convolution2dDataSource.swift
//  RealTimeFastStyleTransfer
//
//  Created by Hrebeniuk Dmytro on 18.05.2020.
//  Copyright © 2020 Hrebeniuk Dmytro. All rights reserved.
//

import Foundation
import Metal
import MetalPerformanceShaders

class Convolution2dDataSource: NSObject, MPSCNNConvolutionDataSource {
    
    let name: String
    let kernelWidth: Int
    let kernelHeight: Int
    let strideX: Int
    let strideY: Int
    let inputChannels: Int
    let outputChannels: Int
    
        
    private(set) var floatData = Array<Float32>()

    init(_ name: String,
         _ kernelWidth: Int, _ kernelHeight: Int,
         _ inputChannels: Int, _ outputChannels: Int,
         _ strideX: Int, _ strideY: Int) {
        self.name = name
        self.kernelWidth = kernelWidth
        self.kernelHeight = kernelHeight
        self.inputChannels = inputChannels
        self.outputChannels = outputChannels
        self.strideX = strideX
        self.strideY = strideY
        
        var data = Bundle.main.url(forResource: name, withExtension: "bin").flatMap { try? Data(contentsOf: $0) }
        
        let floatData = data?.withUnsafeMutableBytes { return Array($0.bindMemory(to: Float32.self)) } ?? [Float32]()
        
        var newFloatData = Array<Float32>(repeating: 0.0, count: floatData.count)
        
        let Cf = self.inputChannels
        let M = self.outputChannels
        let kH = self.kernelHeight
        let kW = self.kernelWidth
        for m in 0..<M {
            for c in 0..<Cf {
                for kh in 0..<kH {
                    for kw in 0..<kW {
                        newFloatData[m * kH * kW * Cf + kh * kW * Cf + kw * Cf + c] =
                            floatData[m * Cf * kH * kW + c * kH * kW + kh * kW + kw]
                    }
                }
            }
        }
        
        self.floatData = newFloatData
    }
    
    func descriptor() -> MPSCNNConvolutionDescriptor {
        let desc = MPSCNNConvolutionDescriptor(kernelWidth: kernelWidth,
            kernelHeight: kernelHeight, inputFeatureChannels: inputChannels,
            outputFeatureChannels: outputChannels)
        desc.strideInPixelsX = strideX
        desc.strideInPixelsY = strideY

        return desc
    }
    
    func weights() -> UnsafeMutableRawPointer {
        return floatData.withUnsafeMutableBytes { ($0.baseAddress ?? UnsafeMutableRawPointer.allocate(byteCount: 0, alignment: 0)) }
    }
    
    func biasTerms() -> UnsafeMutablePointer<Float>? {
        return nil
    }

    
    func load() -> Bool {
        return true
    }
    
    func purge() {

    }
    
    func label() -> String? {
        return name
    }

    func dataType() -> MPSDataType {
        return .float32
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        fatalError("copyWithZone not implemented")
    }
    
}
