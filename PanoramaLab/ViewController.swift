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
    @IBOutlet weak var btnCaptureMode: UISegmentedControl!
    @IBOutlet weak var cannyThresholdSlider: UISlider!
    
    var session: AVCaptureSession!
    var output: AVCaptureOutput!
    var videoDataOutputQueue: DispatchQueue!
    var lastPhoto: UIImage!
    var isRecording: Bool! = false
    var frameCount: Int! = 0
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        var croppedImageView = UIImageView()
        var cropImageRect = CGRect()
        var cropImageRectCorner = UIRectCorner()


        makeCircleButton(buttons: [btnCapture, btnCaptureBack, btnVideoCapture, btnVideoCaptureBack])
        
        self.setVideoSession()
        self.startSession()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
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
        
        self.setIsHidden(buttons: [btnVideoCapture, btnVideoCaptureBack], isHidden: true)
        self.setIsHidden(buttons: [btnCapture, btnCaptureBack], isHidden: false)
    }
    
    func setVideoSession(){
        
        self.session = AVCaptureSession()
        self.session.beginConfiguration()
        
        self.setDevice(session: self.session)
        
        self.videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: self.videoDataOutputQueue)
        
        self.output = output
        
        self.session.sessionPreset = .hd1920x1080
        self.session.addOutput(self.output)
        self.session.commitConfiguration()

        self.setupLivePreview()
        
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
    
    @IBAction func onCaptureModeChange(_ sender: UISegmentedControl) {
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
        
        UIApplication.shared.open(URL(string:"photos-redirect://")!)
    }
    
    @IBAction func onCaptureVideoBegin(_ sender: UIButton) {
        self.isRecording = true
        self.btnVideoCapture.alpha = 0
    }
    
    @IBAction func onCaptureVideoEnd(_ sender: UIButton) {
        self.isRecording = false
        self.btnVideoCapture.alpha = 1
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
            
//            self.lastPhoto = OpenCVWrapper.detectEdges(currentPhoto, Double(self.cannyThresholdSlider.value))
            
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

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
     func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if(self.isRecording){

            self.frameCount+=1

            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return  }
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)

            let context = CIContext()
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return  }

            let image = UIImage(cgImage: cgImage)

//            self.lastPhoto = OpenCVWrapper.detectEdges(image, Double(self.cannyThresholdSlider.value))
            
            if self.lastPhoto != nil {
                self.lastPhoto = OpenCVWrapper.stitch(self.lastPhoto, image)
            }else{
                self.lastPhoto = image
            }
            
            DispatchQueue.main.async {
                self.photoPreview.image = self.lastPhoto
            }
            
        }
    }
}

