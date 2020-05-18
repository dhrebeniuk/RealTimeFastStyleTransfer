//
//  VideoCapturer.swift
//  RealTimeFastStyleTransfer
//
//  Created by Dmytro Hrebeniuk on 1/21/20.
//  Copyright © 2020 dmytro. All rights reserved.
//

import AVFoundation

class VideoCapturer {

	private let session: AVCaptureSession
	
	private var currentCaptureInput: AVCaptureDeviceInput?
	private(set) var configuration = VideoCapturerConfiguration()
	
	var captureSessionPreset: String = AVCaptureSession.Preset.photo.rawValue
	
	init (_ captureSession: AVCaptureSession) {
		self.session = captureSession
	}
	
	deinit {
		if self.currentCaptureInput != nil {
			self.session.removeInput(self.currentCaptureInput!)
		}
	}
	
	func setupCaptureSession() throws -> Void	{
		if self.currentCaptureInput == nil {
			let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video)
            videoCaptureDevice.map { self.configureVideoCaptureDevice($0) }
			
            let videoInput = videoCaptureDevice.flatMap { try? AVCaptureDeviceInput(device: $0) }
			self.currentCaptureInput = videoInput
			
			if self.session.canSetSessionPreset(AVCaptureSession.Preset(rawValue: self.captureSessionPreset)) {
				self.session.sessionPreset = AVCaptureSession.Preset(rawValue: captureSessionPreset)
			}
			else if self.session.canSetSessionPreset(AVCaptureSession.Preset.hd4K3840x2160) {
				self.session.sessionPreset = AVCaptureSession.Preset.hd4K3840x2160
			}
			else if self.session.canSetSessionPreset(AVCaptureSession.Preset.hd1920x1080) {
				self.session.sessionPreset = AVCaptureSession.Preset.hd1920x1080
			}
			else if self.session.canSetSessionPreset(AVCaptureSession.Preset.hd1280x720) {
				self.session.sessionPreset = AVCaptureSession.Preset.hd1280x720
			}
			
            videoInput.map { self.session.addInput($0) }
		}
	}

	private func configureVideoCaptureDevice(_ videoCaptureDevice: AVCaptureDevice) {
		try! videoCaptureDevice.lockForConfiguration()
        videoCaptureDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 25)
		if videoCaptureDevice.isFocusModeSupported(.continuousAutoFocus) {
			videoCaptureDevice.focusMode = .continuousAutoFocus
		}
		if videoCaptureDevice.isExposureModeSupported(.continuousAutoExposure) {
			videoCaptureDevice.exposureMode = .continuousAutoExposure
		}
		if videoCaptureDevice.isLowLightBoostSupported {
			videoCaptureDevice.automaticallyEnablesLowLightBoostWhenAvailable = false
		}
		videoCaptureDevice.unlockForConfiguration()
	}
	
	func configure(_ videoCapturingConfiguration: VideoCapturerConfiguration) throws -> Void {
		self.session.beginConfiguration()
		
		try self.setupCameraPosition(videoCapturingConfiguration.cameraPosition)
		if self.session.canSetSessionPreset(AVCaptureSession.Preset(rawValue: videoCapturingConfiguration.captureSessionPreset)) {
			self.session.sessionPreset = AVCaptureSession.Preset(rawValue: videoCapturingConfiguration.captureSessionPreset)
		}
		self.session.commitConfiguration()
	}
	
	func setupCameraPosition(_ cameraPosition: AVCaptureDevice.Position) throws -> Void {
		guard self.currentCaptureInput?.device.position != cameraPosition else { return }
		
		if self.currentCaptureInput != nil {
			self.session.removeInput(self.currentCaptureInput!)
		}
		
		let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: cameraPosition)
		
		_ = try? discoverySession.devices.filter { device -> Bool in
			return device.position == cameraPosition }.first.map() { captureDevice in
				
				self.configureVideoCaptureDevice(captureDevice)
				
				let videoInput = try AVCaptureDeviceInput(device: captureDevice)
				self.currentCaptureInput = videoInput
				
				self.session.addInput(videoInput)
			}
	}
}
