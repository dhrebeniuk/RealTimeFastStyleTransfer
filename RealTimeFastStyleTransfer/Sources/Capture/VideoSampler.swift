//
//  VideoSampler.swift
//  RealTimeFastStyleTransfer
//
//  Created by Hrebeniuk Dmytro on 04.05.2020.
//  Copyright © 2020 Hrebeniuk Dmytro. All rights reserved.
//


import AVFoundation
import CoreMedia
import UIKit

public typealias VideoSamplerHandler = (_ sampleBuffer: CMSampleBuffer, _ timeStamp: Int64) -> Void

class VideoSampler: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

	private let session: AVCaptureSession
	private var videoOutput: AVCaptureVideoDataOutput!
	
	var videoSamplerOutputHandler: VideoSamplerHandler?
	var isFrontCamera: Bool?
	var videoOrientation: AVCaptureVideoOrientation = .portrait

	init(_ captureSession: AVCaptureSession) {
		self.session = captureSession
	}
	
	func setupOutput() {
		guard self.videoOutput == nil else { return }
		
		self.videoOutput = AVCaptureVideoDataOutput()
		let queue = DispatchQueue(label: "RealTimeFastStyleTransfer.SampleBufferQueue", attributes: []);
		self.videoOutput.setSampleBufferDelegate(self, queue: queue)
		self.videoOutput.alwaysDiscardsLateVideoFrames = true
		
		self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:NSNumber(value:Int32(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange))
		]

		if self.session.canAddOutput(self.videoOutput) {
			self.session.addOutput(self.videoOutput)
		}
		
		self.refreshOutput()
	}
	
	func refreshOutput() {
		for captureConnection in self.videoOutput.connections {
			captureConnection.videoOrientation = self.videoOrientation
			let mirror = isFrontCamera ?? false
			if mirror {
				captureConnection.isVideoMirrored = true
			} else {
				captureConnection.isVideoMirrored = false
			}
		}
	}
	
	func unSetupOutput() {
		guard self.videoOutput != nil else { return }

		self.session.removeOutput(self.videoOutput)
		self.videoOutput = nil
	}
	
	// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
	
	func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		if let handler = self.videoSamplerOutputHandler {
			let presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
			
			let timeStamp = (1000 * presentationTimeStamp.value) / Int64(presentationTimeStamp.timescale);
						
			handler(sampleBuffer, timeStamp)
		}
	}
}
