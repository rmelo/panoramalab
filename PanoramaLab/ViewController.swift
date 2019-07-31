//
//  ViewController.swift
//  PanoramaLab
//
//  Created by Rodrigo Melo on 29/07/19.
//  Copyright © 2019 Rodrigo Melo. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController{
 
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var photoPreview: UIImageView!
    @IBOutlet weak var btnCapture: UIButton!
    @IBOutlet weak var btnCaptureBack: UIButton!
    
    var captureSession: AVCaptureSession!
    var photoOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var lastPhoto: UIImage!
    
    func setupLivePreview(preview: PreviewView, capture: AVCaptureSession) {
        
        preview.videoPreviewLayer.session = capture
        
        preview.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        preview.videoPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        
        preview.videoPreviewLayer.frame = self.previewView.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.btnCapture.layer.cornerRadius = self.btnCapture.frame.width / 2
        
        self.btnCaptureBack.layer.cornerRadius = self.btnCaptureBack.frame.width / 2
        
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        
        let videoDevice = AVCaptureDevice.default(for: .video)
        guard
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!),
            captureSession.canAddInput(videoDeviceInput)
            else { return }
        captureSession.addInput(videoDeviceInput)
        
        photoOutput = AVCapturePhotoOutput()
        guard captureSession.canAddOutput(photoOutput) else { return }

        captureSession.sessionPreset = .hd1920x1080
        captureSession.addOutput(photoOutput)
        captureSession.commitConfiguration()
        
        self.setupLivePreview(preview: self.previewView, capture: self.captureSession)
    
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
        
    }
    
    @IBAction func onCaptureTouchUp(_ sender: UIButton) {
        
        let settings = AVCapturePhotoSettings()
        settings.isAutoStillImageStabilizationEnabled = true;
        
        self.photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @IBAction func onCancelTouchUp(_ sender: UIButton) {
        
        self.lastPhoto = nil;
        self.photoPreview.image = nil;
        
    }
}

extension ViewController: AVCapturePhotoCaptureDelegate{
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {

        self.btnCapture.isHidden = true;
        self.btnCaptureBack.isHidden = true;
        
        DispatchQueue.main.async {
            
            guard let imageData = photo.fileDataRepresentation() else {
                print("Fail to convert pixel buffer")
                return
            }
            
            let currentPhoto = UIImage(data: imageData)
            
            if self.lastPhoto != nil {
                self.lastPhoto = OpenCVWrapper.stitch(self.lastPhoto, currentPhoto)
            }else{
                self.lastPhoto = currentPhoto
            }
            
            self.photoPreview.image = self.lastPhoto
        
            self.btnCapture.isHidden = false;
            self.btnCaptureBack.isHidden = false;
        }
    }
    
}

