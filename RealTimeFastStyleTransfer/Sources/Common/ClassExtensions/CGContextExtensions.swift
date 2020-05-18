//
//  CGContextExtensions.swift
//  RealTimeFastStyleTransfer
//
//  Created by Hrebeniuk Dmytro on 04.05.2020.
//  Copyright © 2020 Hrebeniuk Dmytro. All rights reserved.
//

import Foundation
import CoreGraphics
import CoreGraphics
import Metal

extension CGContext {
  
    func createTexture(device: MTLDevice, pixelFormat: MTLPixelFormat = MTLPixelFormat.rgba8Unorm) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: self.width, height: self.height, mipmapped: false)
        
        let texture = device.makeTexture(descriptor: textureDescriptor)
        
        self.data.map() {
            texture?.replace(region: MTLRegionMake2D(0, 0, self.width, self.height), mipmapLevel: 0, withBytes: $0, bytesPerRow: self.bytesPerRow)
        }
        
        return texture
    }
}
