//
//  VideoController.swift
//  PanoramaLab
//
//  Created by Rodrigo Melo on 01/08/19.
//  Copyright © 2019 Rodrigo Melo. All rights reserved.
//

import UIKit
import AVFoundation

class VideoController: UIViewController{
    
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var photoPreview: UIImageView!
    @IBOutlet weak var btnCapture: UIButton!
    @IBOutlet weak var btnCaptureBack: UIButton!
    
    var captureSession: AVCaptureSession!
    var videoOutput: AVCaptureVideoDataOutput!
    var videoDataOutputQueue: DispatchQueue!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidAppear(_ animated: Bool) {
    }
}
