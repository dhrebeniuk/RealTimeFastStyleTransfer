//
//  CameraRendererPresenter.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 12/8/17.
//  Copyright © 2017 dmytro. All rights reserved.
//

import Metal

protocol CameraRendererPresenterInput {
	
	func setup()
		
	func render(with renderPassDescriptor: MTLRenderPassDescriptor, drawable: MTLDrawable)
	
}

class CameraRendererPresenter: CameraRendererPresenterInput {

	weak var view: CameraRendererView?
		
    var samplesRenderer: SamplesMetalRenderer?
    var photoCapturer: PhotoCapturer?
        
	// MARK: - CameraRendererPresenterInput
	
	func setup() {
        let device = MTLCreateSystemDefaultDevice()
        let commandQueue = device?.makeCommandQueue(maxCommandBufferCount: 1)
        
        let samplesImporter = SamplesMetalImporter(device: device, commandQueue: commandQueue)
        samplesImporter.setup()
        
        samplesRenderer = SamplesMetalRenderer(device: device, commandQueue: commandQueue, samplesImporter: samplesImporter)
        samplesRenderer?.setup()
        
        photoCapturer = PhotoCapturer()
        photoCapturer?.requestAccess(completion: { [weak self] isSuccess in
            if isSuccess {
                try? self?.photoCapturer?.setup(videoHandler: { [weak self] (sampleBuffer, _) in
                   self?.samplesRenderer?.send(sampleBuffer: sampleBuffer)
                    
                    DispatchQueue.main.async {
                        self?.view?.requestRendering()
                    }
                })
            }
        })
    }
	
	func render(with renderPassDescriptor: MTLRenderPassDescriptor, drawable: MTLDrawable) {
        samplesRenderer?.render(with: renderPassDescriptor, drawable: drawable)
	}

}
