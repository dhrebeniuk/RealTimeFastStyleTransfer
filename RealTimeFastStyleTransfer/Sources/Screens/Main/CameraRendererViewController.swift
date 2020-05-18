//
//  CameraRendererViewController.swift
//  RealTimeFastStyleTransfer
//
//  Created by Hrebeniuk Dmytro on 04.05.2020.
//  Copyright © 2020 Hrebeniuk Dmytro. All rights reserved.
//

import UIKit
import MetalKit

protocol CameraRendererView: class {
    
    var viewSize: CGSize { get }
    
    func requestRendering()
    
}

class CameraRendererViewController: UIViewController {

    private var metalView: MTKView?

    var presenterInput: CameraRendererPresenterInput?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.presenterInput?.setup()
        
        self.initializeMetalView()
        
        let presenter = CameraRendererPresenter()
        presenter.view = self
        presenter.setup()
        self.presenterInput = presenter
    }

    private func initializeMetalView() {
        let metalView = MTKView(frame: self.view.bounds, device: MTLCreateSystemDefaultDevice())
        metalView.delegate = self
        metalView.framebufferOnly = false
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.contentScaleFactor = UIScreen.main.scale
        metalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        metalView.preferredFramesPerSecond = 30
        metalView.enableSetNeedsDisplay = true
        view.insertSubview(metalView, at: 0)
        
        self.metalView = metalView
    }
}

extension CameraRendererViewController: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let currentRenderPassDescriptor = view.currentRenderPassDescriptor,
            let currentDrawable = view.currentDrawable
            else {
                return
        }
        
        self.presenterInput?.render(with: currentRenderPassDescriptor, drawable: currentDrawable)
    }
}

extension CameraRendererViewController: CameraRendererView {

    var viewSize: CGSize {
        return self.view.bounds.size
    }
    
    func requestRendering() {
        self.metalView?.setNeedsDisplay()
    }

}

