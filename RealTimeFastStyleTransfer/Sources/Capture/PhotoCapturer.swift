//
//  PhotoCapturer.swift
//  RealTimeFastStyleTransfer
//
//  Created by Dmytro Hrebeniuk on 1/21/20.
//  Copyright © 2020 Dmytro Hrebeniuk. All rights reserved.
//

import AVFoundation

typealias PhotoSamplerHandler = (_ pixelBuffer: CVPixelBuffer) -> Void

class PhotoCapturer: NSObject, AVCapturePhotoCaptureDelegate {

	private let session: AVCaptureSession
	private var videoCapturer: VideoCapturer?
	private let videoSampler: VideoSampler?
	private var cameraOutput: AVCapturePhotoOutput!

	private var photoSamplerHandler: PhotoSamplerHandler?
	
    var videoOrientation: AVCaptureVideoOrientation = .portrait

	var videoCapturerConfiguration: VideoCapturerConfiguration = {
		var videoCapturerConfiguration = VideoCapturerConfiguration()
		videoCapturerConfiguration.captureSessionPreset = AVCaptureSession.Preset.photo.rawValue
		return videoCapturerConfiguration
	}()
	
	convenience override init() {
		self.init(AVCaptureSession())
	}
	
	init(_ captureSession: AVCaptureSession) {
		self.session = captureSession
		
		self.videoCapturer = VideoCapturer(captureSession)
		self.videoSampler = VideoSampler(captureSession)
	}
	
	var cameraPosition: AVCaptureDevice.Position = .back {
		didSet {
			guard oldValue != self.cameraPosition else {
				return
			}
			
			self.stopCaptureSession()
			self.videoSampler?.unSetupOutput()
			
			try? self.videoCapturer?.setupCameraPosition(self.cameraPosition)
			if self.cameraPosition == .back {
				self.videoSampler?.isFrontCamera = false
			}
			else {
				self.videoSampler?.isFrontCamera = true
			}
		
			self.videoSampler?.setupOutput()
			self.startCaptureSession()
		}
	}
	
	open func setup(videoHandler: @escaping VideoSamplerHandler) throws -> Void {
		try? self.videoCapturer?.setupCaptureSession()

		try? self.videoCapturer?.configure(self.videoCapturerConfiguration)

		self.cameraOutput = AVCapturePhotoOutput()
		self.cameraOutput.isHighResolutionCaptureEnabled = true
		
		if (self.session.canAddOutput(self.cameraOutput)) {
			self.session.addOutput(self.cameraOutput)
		}
		
		self.videoSampler?.videoOrientation = self.videoOrientation
		self.videoSampler?.videoSamplerOutputHandler = videoHandler
		self.videoSampler?.setupOutput()

		self.startCaptureSession()
	}

	open func startCaptureSession() -> Void {
		if !self.session.isRunning {
			self.session.startRunning()
		}
	}
	
	open func stopCaptureSession() -> Void {
		if self.session.isRunning {
			self.session.stopRunning()
		}
	}
	
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		
		guard let pixelBuffer = photo.pixelBuffer else {
			return
		}
		
		self.photoSamplerHandler?(pixelBuffer)
	}
}

extension PhotoCapturer {
	
	func requestAccess(completion: ((_ isAuthorized: Bool)-> ())? = nil) {
		AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (isAuthorized) in
			DispatchQueue.main.async {
				completion?(isAuthorized)
			}
		})
	}
	
}
