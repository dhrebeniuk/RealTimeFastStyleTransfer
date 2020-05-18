//
//  CVPixelBufferExtensions.swift
//  RealTimeFastStyleTransfer
//
//  Created by Hrebeniuk Dmytro on 04.05.2020.
//  Copyright © 2020 Hrebeniuk Dmytro. All rights reserved.
//


import Metal
import CoreVideo

extension CVPixelBuffer {
	
	class func createPixelBuffer(in pool: CVPixelBufferPool) -> CVPixelBuffer? {
		
		var pixelBuffer: CVPixelBuffer? = nil
		
		_ = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
        pixelBuffer.map {
			CVBufferSetAttachment($0, kCVImageBufferColorPrimariesKey, kCVImageBufferColorPrimaries_ITU_R_709_2, .shouldPropagate)
			CVBufferSetAttachment($0, kCVImageBufferYCbCrMatrixKey, kCVImageBufferYCbCrMatrix_ITU_R_601_4, .shouldPropagate)
			CVBufferSetAttachment($0, kCVImageBufferTransferFunctionKey, kCVImageBufferTransferFunction_ITU_R_709_2, .shouldPropagate)
		}
		
		return pixelBuffer
	}
}
