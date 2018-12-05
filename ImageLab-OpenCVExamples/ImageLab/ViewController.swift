//
//  ViewController.swift
//  ImageLab
//
//  Created by Eric Larson
//  Copyright © 2016 Eric Larson. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController   {
    //MARK: Class Properties
    
    var filters : [CIFilter]! = nil
    var videoManager:VideoAnalgesic! = nil
    let pinchFilterIndex = 2
    var detector:CIDetector! = nil
    let bridge = OpenCVBridge()
    var fGlobal:[CIFaceFeature] = [];
    var retImageGlobal:CIImage = CIImage()

    @IBAction func actuallyCapture(_ sender: Any) {
        self.bridge.setTransforms(self.videoManager.transform)
        let faceImage = self.bridge.capture(retImageGlobal,
                                             withBounds: fGlobal[0].bounds, // the first face bounds
            andContext: self.videoManager.getCIContext())
        
        if(faceImage != nil) {
            print("face image is not null")
            
            DispatchQueue.main.async {
                let ciContext = CIContext()
                let cgImage = ciContext.createCGImage(faceImage!, from: faceImage!.extent)
                self.testImage.image = UIImage.init(cgImage: cgImage!)
                let copyImage = self.testImage.image
                let copyImageData:NSData = UIImagePNGRepresentation(copyImage!)! as NSData
                let strBase64 = copyImageData.base64EncodedString(options: .lineLength64Characters)
                print(strBase64)
            }
        }
    }
    @IBOutlet var imageCapture: UIView!
    @IBOutlet weak var testImage: UIImageView!
    //MARK: Outlets in view
    @IBOutlet weak var flashSlider: UISlider!
    @IBOutlet weak var stageLabel: UILabel!
    
    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = nil
        self.setupFilters()
        
        self.videoManager = VideoAnalgesic.sharedInstance
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.front)
        
        // create dictionary for face detection
        // HINT: you need to manipulate these proerties for better face detection efficiency
        let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyLow,CIDetectorTracking:true] as [String : Any]
        
        // setup a face detector in swift
        self.detector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: self.videoManager.getCIContext(), // perform on the GPU is possible
            options: (optsDetector as [String : AnyObject]))
        
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImage)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
    }
    
    //MARK: Process image output
    //LOOK INTO MAKING RETIMAGE AND F INTO GLOBAL VARIABLES AND THAT WAY IT CAN BE MOVED INTO AN IBACTION
    //ALSO VIEWCONTROLLER,OPENCVBRIDGE.HH,AND OPENCVBRIDGE.MM WERE MODIFIED TO MAKE THIS WORK
    func processImage(inputImage:CIImage) -> CIImage{
        // detect faces
        let f = getFaces(img: inputImage)
        // if no faces, just return original image
        print("number of faces", f.count)   
        if f.count == 0 { return inputImage }
        
        fGlobal = f
        
        var retImage = inputImage
        retImageGlobal = retImage
        self.bridge.processType = 1;
        self.bridge.setTransforms(self.videoManager.transform)
        
        for feature in f {
            self.bridge.setImage(retImage,
                                 withBounds: feature.bounds, // the first face bounds
                andContext: self.videoManager.getCIContext())
            self.bridge.processImage()
            retImage = self.bridge.getImageComposite()
        self.bridge.setImage(retImage,
                             withBounds: feature.bounds, // the first face bounds
            andContext: self.videoManager.getCIContext())
        
        self.bridge.processImage()
        retImage = self.bridge.getImageComposite() // get back opencv processed part of the image (overlayed on original)
     }
        return retImage
    }
    
    //MARK: Setup filtering
    func setupFilters(){
        print("setting up filters")
        filters = []
        
        let filterPinch = CIFilter(name:"CIBumpDistortion")!
        filterPinch.setValue(-0.5, forKey: "inputScale")
        filterPinch.setValue(75, forKey: "inputRadius")
        filters.append(filterPinch)
        
    }
    
    //MARK: Apply filters and apply feature detectors
    func applyFiltersToFaces(inputImage:CIImage,features:[CIFaceFeature])->CIImage{
        var retImage = inputImage
        var filterCenter = CGPoint()
//        globalFeatures = features
        print("HELLO HELLO HELLO")
        print("features: ", features)
        for f in features {
            //set where to apply filter
            filterCenter.x = f.bounds.midX
            filterCenter.y = f.bounds.midY
            
            //do for each filter (assumes all filters have property, "inputCenter")
            for filt in filters{
                filt.setValue(retImage, forKey: kCIInputImageKey)
                filt.setValue(CIVector(cgPoint: filterCenter), forKey: "inputCenter")
                // could also manipualte the radius of the filter based on face size!
                retImage = filt.outputImage!
            }
        }
        return retImage
    }
    
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation]
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
        
    }
    
    
    
    @IBAction func swipeRecognized(_ sender: UISwipeGestureRecognizer) {
        stageLabel.text = "Stage: \(self.bridge.processType)"

    }
    
    //MARK: Convenience Methods for UI Flash and Camera Toggle
    @IBAction func flash(_ sender: AnyObject) {
        if(self.videoManager.toggleFlash()){
            self.flashSlider.value = 1.0
        }
        else{
            self.flashSlider.value = 0.0
        }
    }
    
    @IBAction func switchCamera(_ sender: AnyObject) {
        self.videoManager.toggleCameraPosition()
    }
    
    @IBAction func setFlashLevel(_ sender: UISlider) {
        if(sender.value>0.0){
            self.videoManager.turnOnFlashwithLevel(sender.value)
        }
        else if(sender.value==0.0){
            self.videoManager.turnOffFlash()
        }
    }

   
}

