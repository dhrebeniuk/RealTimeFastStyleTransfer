//
//  CVPixelBufferPoolExtensions.swift
//  RealTimeFastStyleTransfer
//
//  Created by Hrebeniuk Dmytro on 04.05.2020.
//  Copyright © 2020 Hrebeniuk Dmytro. All rights reserved.
//


import Metal
import CoreVideo

extension CVPixelBufferPool {
	
	class func createPixelBufferPool(width: Float, height: Float) -> CVPixelBufferPool? {
		let poolAttributes = NSMutableDictionary()
		poolAttributes[kCVPixelBufferPoolMinimumBufferCountKey] = NSNumber(value: Int32(6))
		let pixelBufferAttributes = NSMutableDictionary()
		pixelBufferAttributes[kCVPixelBufferWidthKey] = NSNumber(value: Int32(width))
		pixelBufferAttributes[kCVPixelBufferHeightKey] = NSNumber(value: Int32(height))
		pixelBufferAttributes[kCVPixelBufferPixelFormatTypeKey] = NSNumber(value: Int32(kCVPixelFormatType_32BGRA))
				
		let ioSurfaceProperties = NSMutableDictionary()
		ioSurfaceProperties["IOSurfaceIsGlobal"] = NSNumber(value: true)
		ioSurfaceProperties["IOSurfacePurgeWhenNotInUse"] = NSNumber(value: true)
		pixelBufferAttributes[kCVPixelBufferIOSurfacePropertiesKey] = ioSurfaceProperties
		pixelBufferAttributes["CacheMode"] = [1024, 0, 256, 512, 768, 1280]
		
		var pixelBufferPool: CVPixelBufferPool? = nil
		CVPixelBufferPoolCreate(nil, poolAttributes, pixelBufferAttributes, &pixelBufferPool)
		
		return pixelBufferPool
	}
}
