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
    @IBOutlet weak var btnVideoCapture: UIButton!
    @IBOutlet weak var btnVideoCaptureBack: UIButton!
    @IBOutlet weak var btnCaptureMode: UIButton!
    
    var videoQueueOutput: DispatchQueue!
    
    var session: AVCaptureSession!
    var output: AVCaptureOutput!
    
    var lastPhoto: UIImage!
    
    func setupLivePreview() {
        self.previewView.videoPreviewLayer.session = self.session
        self.previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewView.videoPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        self.previewView.videoPreviewLayer.frame = self.previewView.bounds
    }
    
    func makeCircleButton(buttons: [UIButton] ){
        for button in buttons{
            button.layer.cornerRadius = button.frame.width / 2
        }
    }
    
    func setIsHidden(buttons: [UIButton], isHidden: Bool){
        for button in buttons {
            button.isHidden = isHidden
        }
    }
    
    func setDevice(session: AVCaptureSession){
        
        let videoDevice = AVCaptureDevice.default(for: .video)
        
        guard
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!),
            session.canAddInput(videoDeviceInput)
            else { return }
        
        session.addInput(videoDeviceInput)
    }
    
    func setPhotoSession(){
        
        self.session = AVCaptureSession()
        self.session.beginConfiguration()
        
        self.setDevice(session: self.session)
        
        self.output = AVCapturePhotoOutput()
        guard self.session.canAddOutput(self.output) else { return }
        
        self.session.sessionPreset = .hd1920x1080
        self.session.addOutput(self.output)
        self.session.commitConfiguration()
        
        self.setupLivePreview()
        
        self.btnCaptureMode.setTitle("Video", for: .normal)
        
        self.setIsHidden(buttons: [btnVideoCapture, btnVideoCaptureBack], isHidden: true)
        self.setIsHidden(buttons: [btnCapture, btnCaptureBack], isHidden: false)
    }
    
    func setVideoSession(){
        
        self.session = AVCaptureSession()
        self.session.beginConfiguration()
        
        self.setDevice(session: self.session)
        self.output = AVCaptureVideoDataOutput()
        
        self.session.sessionPreset = .vga640x480
        self.session.addOutput(self.output)
        self.session.commitConfiguration()

        self.setupLivePreview()
        
        self.btnCaptureMode.setTitle("Photo", for: .normal)
        
        self.setIsHidden(buttons: [btnVideoCapture, btnVideoCaptureBack], isHidden: false)
        self.setIsHidden(buttons: [btnCapture, btnCaptureBack], isHidden: true)
    }
    
    
    
    func changeMode(){
        
        self.stopSession()
        
        if(self.output is AVCapturePhotoOutput){
            self.setVideoSession()
        }else{
            self.setPhotoSession()
        }
        
        self.startSession()
    }
    
    func startSession(){
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
    
    func stopSession(){
        self.session.stopRunning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        makeCircleButton(buttons: [btnCapture, btnCaptureBack, btnVideoCapture, btnVideoCaptureBack])
        
        self.setPhotoSession()
        self.startSession()
    }

    @IBAction func onCaptureModeChange(_ sender: Any) {
        self.changeMode()
    }
    
    @IBAction func onCaptureTouchUp(_ sender: UIButton) {
        
        let settings = AVCapturePhotoSettings()
        settings.isAutoStillImageStabilizationEnabled = true;
    
        (self.output as? AVCapturePhotoOutput)?.capturePhoto(with: settings, delegate: self)
    }
    
    @IBAction func onCancelTouchUp(_ sender: UIButton) {
        
        self.lastPhoto = nil;
        self.photoPreview.image = nil;
        
    }
    
    @IBAction func onSaveTouchUp(_ sender: Any) {
        
        UIImageWriteToSavedPhotosAlbum(self.lastPhoto, nil, nil, nil);
        let alert = UIAlertController(title: "Saved", message: "Image saved to camera roll.", preferredStyle: .alert);
        self.present(alert, animated: true);
        self.dismiss(animated: true, completion: nil);
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

