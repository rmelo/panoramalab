//
//  PreviewView.swift
//  PanoramaLab
//
//  Created by Rodrigo Melo on 30/07/19.
//  Copyright © 2019 Rodrigo Melo. All rights reserved.
//

import UIKit
import AVFoundation

class PreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    /// Convenience wrapper to get layer as its statically known type.
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}
