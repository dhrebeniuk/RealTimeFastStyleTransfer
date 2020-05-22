//
//  Instance2DNormalizationDataSource.swift
//  RealTimeFastStyleTransfer
//
//  Created by Hrebeniuk Dmytro on 20.05.2020.
//  Copyright © 2020 Hrebeniuk Dmytro. All rights reserved.
//

import MetalPerformanceShaders

class Instance2DNormalizationDataSource: NSObject, MPSCNNInstanceNormalizationDataSource  {
    
    let name: String
    let featuresCount: Int

    var gammaData: Data?
    var betaData: Data?

    init(_ name: String, _ featuresCount: Int) {
        self.name = name
        self.featuresCount = featuresCount
        
        gammaData = Bundle.main.url(forResource: "\(name)_gamma", withExtension: "bin").flatMap { try? Data(contentsOf: $0) }
        betaData = Bundle.main.url(forResource: "\(name)_beta", withExtension: "bin").flatMap { try? Data(contentsOf: $0) }
    }
    
    func load() -> Bool {
        return true
    }
    
    func purge() {
        
    }
    
    func gamma() -> UnsafeMutablePointer<Float>? {
        return gammaData?.withUnsafeMutableBytes { return $0.bindMemory(to: Float.self).baseAddress }
    }
    
    func beta() -> UnsafeMutablePointer<Float>? {
        return betaData?.withUnsafeMutableBytes { return $0.bindMemory(to: Float.self).baseAddress }
    }
    
    func mean() -> UnsafeMutablePointer<Float>? {
        return nil
    }
    
    func variance() -> UnsafeMutablePointer<Float>? {
        return nil
    }
    
    func epsilon() -> Float {
        return 1e-3;
    }
    
    var numberOfFeatureChannels: Int {
        return featuresCount
    }
    
    func dataType() -> MPSDataType {
        return .float32
    }

    func label() -> String? {
        name
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("copyWithZone not implemented")
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        fatalError("copyWithZone not implemented")
    }
    
}
