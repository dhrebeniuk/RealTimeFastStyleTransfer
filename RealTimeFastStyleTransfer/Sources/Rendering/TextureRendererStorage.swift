//
//  TextureRendererStorage.swift
//  RealTimeFastStyleTransfer
//
//  Created by Hrebeniuk Dmytro on 04.05.2020.
//  Copyright © 2020 Hrebeniuk Dmytro. All rights reserved.
//


import Metal

protocol TextureRendererStorage {
	
	func requestRenderedTexture() -> MTLTexture?
	
}
