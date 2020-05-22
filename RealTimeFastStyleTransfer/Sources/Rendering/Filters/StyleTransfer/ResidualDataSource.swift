//
//  ResidualDataSource.swift
//  RealTimeFastStyleTransfer
//
//  Created by Hrebeniuk Dmytro on 20.05.2020.
//  Copyright © 2020 Hrebeniuk Dmytro. All rights reserved.
//

import Foundation

class ResDataSource {
    
    let conv1Data: Convolution2dDataSource
    let in1Data: Instance2DNormalizationDataSource

    let conv2Data: Convolution2dDataSource
    
    let in2Data: Instance2DNormalizationDataSource
    
    init(name: String, channels: Int, kernelSize: Int = 3, stride: Int = 1) {
        conv1Data = Convolution2dDataSource("\(name)_conv1_weight", kernelSize, kernelSize, channels, channels, stride, stride)
        in1Data = Instance2DNormalizationDataSource("\(name)_in1", channels)
        
        conv2Data = Convolution2dDataSource("\(name)_conv2_weight", 3, 3, channels, channels, 1, 1)
        in2Data = Instance2DNormalizationDataSource("\(name)_in2", channels)
    }
}
