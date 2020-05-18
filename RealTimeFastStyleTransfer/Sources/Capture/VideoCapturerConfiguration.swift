//
//  VideoCapturerConfiguration.swift
//  RealTimeFastStyleTransfer
//
//  Created by Dmytro Hrebeniuk on 1/21/20.
//  Copyright © 2020 dmytro. All rights reserved.
//

import AVFoundation

struct VideoCapturerConfiguration {
	
	var cameraPosition: AVCaptureDevice.Position = .back
	var captureSessionPreset: String = AVCaptureSession.Preset.hd4K3840x2160.rawValue
}
