//
//  StyleTransferFilter.swift
//  RealTimeFastStyleTransfer
//
//  Created by Hrebeniuk Dmytro on 20.05.2020.
//  Copyright © 2020 Hrebeniuk Dmytro. All rights reserved.
//

import Metal
import MetalPerformanceShaders

class StyleTransferFilter {

    private let device: MTLDevice?
    private var resizeGraph: MPSNNGraph?
    
    init(device: MTLDevice?) {
        self.device = device
    }
    
    private let conv1Data = Convolution2dDataSource("style_conv1_weight", 3, 3, 3, 9, 1, 1)
    private let in1Data = Instance2DNormalizationDataSource("style_in1", 9)

    private let conv2Data = Convolution2dDataSource("style_conv2_weight", 3, 3, 9, 9, 2, 2)
    private let in2Data = Instance2DNormalizationDataSource("style_in2", 9)
    
    private let conv3Data = Convolution2dDataSource("style_conv3_weight", 3, 3, 9, 6, 2, 2)
    private let in3Data = Instance2DNormalizationDataSource("style_in3", 6)
    
    private let res1Data = ResDataSource(name: "style_res1", channels: 6)
    private let res2Data = ResDataSource(name: "style_res2", channels: 6)
    
    private let deconv1Data = Convolution2dDataSource("style_deconv1_weight", 3, 3, 6, 9, 1, 1)
    private let in4Data = Instance2DNormalizationDataSource("style_in4", 9)

    private let deconv2Data = Convolution2dDataSource("style_deconv2_weight", 3, 3, 9, 9, 1, 1)
    private let in5Data = Instance2DNormalizationDataSource("style_in5", 9)
    
    private let deconv3Data = Convolution2dDataSource("style_deconv3_weight", 3, 3, 9, 3, 1, 1)
    
    func applyEffect(inputTexture: MTLTexture, in commandBuffer: MTLCommandBuffer) -> MTLTexture? {
        var outImage: MPSImage? = MPSImage(texture: inputTexture, featureChannels: 3)
        
        outImage = outImage.flatMap { resizeImage(inputImage: $0, in: commandBuffer, width: Int(0.5*Double(inputTexture.width)), height: Int(0.5*Double(inputTexture.height)) ) }

        outImage = outImage.flatMap { applyConvLayer(inputImage: $0, convolutionData: conv1Data, in: commandBuffer) }
        outImage = outImage.flatMap { applyNormalization(inputImage: $0, data: in1Data, in: commandBuffer) }
        outImage = outImage.flatMap { applyRELU(inputImage: $0, in: commandBuffer) }

        outImage = outImage.flatMap { applyConvLayer(inputImage: $0, convolutionData: conv2Data, in: commandBuffer) }
        outImage = outImage.flatMap { applyNormalization(inputImage: $0, data: in2Data, in: commandBuffer) }
        outImage = outImage.flatMap { applyRELU(inputImage: $0, in: commandBuffer) }

        outImage = outImage.flatMap { applyConvLayer(inputImage: $0, convolutionData: conv3Data, in: commandBuffer) }
        outImage = outImage.flatMap { applyNormalization(inputImage: $0, data: in3Data, in: commandBuffer) }
        outImage = outImage.flatMap { applyRELU(inputImage: $0, in: commandBuffer) }

        outImage = outImage.flatMap { applyResidualLayer(inputImage: $0, resData: res1Data, in: commandBuffer) }
        outImage = outImage.flatMap { applyResidualLayer(inputImage: $0, resData: res2Data, in: commandBuffer) }

        outImage = outImage
            .flatMap { applyUpscaleConvLayer(inputImage: $0, upscale: 2, convolutionData: deconv1Data, in: commandBuffer) }

        outImage = outImage.flatMap { applyNormalization(inputImage: $0, data: in4Data, in: commandBuffer) }
        outImage = outImage.flatMap { applyRELU(inputImage: $0, in: commandBuffer) }

        outImage = outImage
            .flatMap { applyUpscaleConvLayer(inputImage: $0, upscale: 2, convolutionData: deconv2Data, in: commandBuffer) }

        outImage = outImage.flatMap { applyNormalization(inputImage: $0, data: in5Data, in: commandBuffer) }
        outImage = outImage.flatMap { applyRELU(inputImage: $0, in: commandBuffer) }

        outImage = outImage
            .flatMap { applyConvLayer(inputImage: $0, convolutionData: deconv3Data, in: commandBuffer) }

        outImage = outImage.flatMap { scalarMultiply(inputImage: $0, scalar: 1.0/255.0, in: commandBuffer) }
        
        return outImage?.texture
    }

}

extension StyleTransferFilter {
    
    private func resizeImage(inputImage: MPSImage, in commandBuffer: MTLCommandBuffer, width: Int, height: Int) -> MPSImage? {
        guard let metalDevice = self.device else {
            return nil
        }

        let inputImageNode = MPSNNImageNode(handle: nil)

        var graph: MPSNNGraph? = resizeGraph
        
        
        let scale = MPSNNLanczosScaleNode(source: inputImageNode, outputSize: MTLSize(width: width, height: height, depth: 3))
        
        if (graph == nil) {
            graph = MPSNNGraph(device: metalDevice, resultImage: scale.resultImage, resultImageIsNeeded: true)
            graph?.format = .float16
            self.resizeGraph = graph
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        
        var resultMPSImage: MPSImage?
        graph?.executeAsync(withSourceImages: [inputImage], completionHandler: { (resultImage, error) in
            resultMPSImage = resultImage
            semaphore.signal()
        })
        
        semaphore.wait()
        
        return resultMPSImage
    }
    
    private func applyConvLayer(inputImage: MPSImage, convolutionData: Convolution2dDataSource, in commandBuffer: MTLCommandBuffer) -> MPSImage? {
        let conv = device.map { MPSCNNConvolution(device: $0, weights: convolutionData) }
        conv?.padding = MPSNNDefaultPadding()
        conv?.accumulatorPrecisionOption = .half

        let outputDescriptor = MPSImageDescriptor(channelFormat: inputImage.featureChannelFormat, width: inputImage.width/convolutionData.strideX, height: inputImage.height/convolutionData.strideY, featureChannels: convolutionData.outputChannels, numberOfImages: inputImage.numberOfImages,  usage: [.shaderRead, .shaderWrite])
        
        let outputImage = device.map { MPSImage(device: $0, imageDescriptor: outputDescriptor) }

        outputImage.map { conv?.encode(commandBuffer: commandBuffer, sourceImage: inputImage, destinationImage: $0) }

        return outputImage
    }
    
    
    private func applyRELU(inputImage: MPSImage, in commandBuffer: MTLCommandBuffer, value: Float = Float(0.0)) -> MPSImage? {
        let relu = device.map { MPSCNNNeuron(device: $0, neuronDescriptor: .cnnNeuronDescriptor(with: .reLU, a: value, b: value, c: value)) }

        let reluOutputDescriptor = MPSImageDescriptor(channelFormat: inputImage.featureChannelFormat, width: inputImage.width, height: inputImage.height, featureChannels: inputImage.featureChannels, numberOfImages: inputImage.numberOfImages, usage: [.shaderRead, .shaderWrite])

        let reluOutputImage = device.map { MPSImage(device: $0, imageDescriptor: reluOutputDescriptor) }

        reluOutputImage.map { relu?.encode(commandBuffer: commandBuffer, sourceImage: inputImage, destinationImage: $0) }

        reluOutputImage.map { relu?.encode(commandBuffer: commandBuffer, sourceImage: inputImage, destinationImage: $0) }

        return reluOutputImage
    }
    
    private func applyNormalization(inputImage: MPSImage, data: Instance2DNormalizationDataSource, in commandBuffer: MTLCommandBuffer, userRelu: Bool = false) -> MPSImage? {
        let outputDescriptor = MPSImageDescriptor(channelFormat: .float16, width: inputImage.width, height: inputImage.height, featureChannels: inputImage.featureChannels, numberOfImages: inputImage.numberOfImages, usage: [.shaderRead, .shaderWrite])
        
        let outputImage = device.map { MPSImage(device: $0, imageDescriptor: outputDescriptor) }
        
        let instanceNormalization = device.map { MPSCNNInstanceNormalization(device: $0, dataSource: data) }
        
        outputImage.map {
            instanceNormalization?.encode(commandBuffer: commandBuffer, sourceImage: inputImage, destinationImage: $0)
        }

        return outputImage
    }

    private func applyResidualLayer(inputImage: MPSImage, resData: ResDataSource, in commandBuffer: MTLCommandBuffer) -> MPSImage? {
        
        var resultImage: MPSImage? = inputImage
        
        resultImage = applyConvLayer(inputImage: inputImage, convolutionData: resData.conv1Data, in: commandBuffer)

        resultImage = resultImage.flatMap { applyNormalization(inputImage: $0, data: resData.in1Data, in: commandBuffer) }

        resultImage = resultImage.flatMap { applyRELU(inputImage: $0, in: commandBuffer) }

        resultImage = resultImage.flatMap { applyConvLayer(inputImage: $0, convolutionData: resData.conv2Data, in: commandBuffer) }

        resultImage = resultImage.flatMap { applyNormalization(inputImage: $0, data: resData.in2Data, in: commandBuffer) }

        let cocantenateImageDescriptor = MPSImageDescriptor(channelFormat: inputImage.featureChannelFormat, width: inputImage.width, height: inputImage.height, featureChannels: inputImage.featureChannels, numberOfImages: inputImage.numberOfImages, usage: [.shaderRead, .shaderWrite])

        let cocantenateImage = device.map { MPSImage(device: $0, imageDescriptor: cocantenateImageDescriptor) }
        
        let cocantenateKernel = device.flatMap { device in resultImage.map { CocantenateKernel(device: device, additionImage: $0) } }
        
        cocantenateImage.map {
            cocantenateKernel?.encode(commandBuffer: commandBuffer, sourceImage: inputImage, destinationImage: $0)
        }
        
        return cocantenateImage
    }
    
    private func scalarMultiply(inputImage: MPSImage, scalar: Float, in commandBuffer: MTLCommandBuffer) -> MPSImage? {
        let scalarMultiplyImageDescriptor = MPSImageDescriptor(channelFormat: inputImage.featureChannelFormat, width: inputImage.width, height: inputImage.height, featureChannels: inputImage.featureChannels, numberOfImages: inputImage.numberOfImages, usage: [.shaderRead, .shaderWrite])

        let scalarMultipliedImage = device.map { MPSImage(device: $0, imageDescriptor: scalarMultiplyImageDescriptor) }
         
        let scalarMultiplyKernel = device.map { ScalarMultiplyKernel(device: $0, multiply: scalar) }
        
        scalarMultipliedImage.map {
            scalarMultiplyKernel?.encode(commandBuffer: commandBuffer, sourceImage: inputImage, destinationImage: $0)
        }

        return scalarMultipliedImage
    }
    
    private func applyUpscaleConvLayer(inputImage: MPSImage, upscale: Int, convolutionData: Convolution2dDataSource, in commandBuffer: MTLCommandBuffer) -> MPSImage? {
        guard let metalDevice = self.device else {
            return nil
        }
        
        let upscaleImageDescriptor = MPSImageDescriptor(channelFormat: inputImage.featureChannelFormat, width: inputImage.width*upscale, height: inputImage.height*upscale, featureChannels: inputImage.featureChannels, numberOfImages: inputImage.numberOfImages, usage: [.shaderRead, .shaderWrite])

        let upscaleImage = device.map { MPSImage(device: $0, imageDescriptor: upscaleImageDescriptor) }

        let upsampling = MPSCNNUpsamplingNearest(device: metalDevice, integerScaleFactorX: upscale, integerScaleFactorY: upscale)
        
        upscaleImage.map {
            upsampling.encode(commandBuffer: commandBuffer, sourceImage: inputImage, destinationImage: $0)
        }
                
        return upscaleImage.flatMap { applyConvLayer(inputImage: $0, convolutionData: convolutionData, in: commandBuffer) }
    }
    
}
