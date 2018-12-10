//
//  ViewController.swift
//  ImageLab
//
//  Created by Eric Larson
//  Copyright © 2016 Eric Larson. All rights reserved.
//
import UIKit
import AVFoundation

class ViewController: UIViewController, URLSessionDelegate, UITextFieldDelegate  {
    //MARK: Class Properties
    var base64string = String()
    let operationQueue = OperationQueue()
    
    var session = URLSession()
    
    var colorPrediction: Any!
    var emotionPrediction: Any!
    var emojiButtons: [EmojiButton]!
    var greenButtons: [UIButton] = []
    
    var faceImages = [CIImage]()
    var detector:CIDetector! = nil
    var retImage:CIImage = CIImage()
    var fGlobal:[CIFaceFeature] = [];
    
    let bridge = OpenCVBridge()
    var videoManager:VideoAnalgesic! = nil
    
    let SERVER_URL = "http://169.254.156.29:8000"
    
    
    @IBOutlet weak var copyLabel: UILabel!
    @IBOutlet weak var emojiButton1: EmojiButton!
    @IBOutlet weak var emojiButton2: EmojiButton!
    @IBOutlet weak var emojiButton3: EmojiButton!
    @IBOutlet weak var emojiButton4: EmojiButton!
    @IBOutlet weak var emojiButton5: EmojiButton!
    
    @IBOutlet weak var reset: UIButton!
    @IBOutlet weak var predictionImg: UIImageView!
    
    @IBOutlet weak var emojiPressed: EmojiButton!
    
    @IBAction func emojiPressed(_ sender: EmojiButton) {
        sender.pressed()
    }
    
    @IBAction func reset(_ sender: Any) {
        
        self.faceImages.removeAll()
        
        for button in self.greenButtons {
            button.removeFromSuperview()
        }
        
        self.greenButtons.removeAll()
        
        for emojiButton in self.emojiButtons{
            emojiButton.setImage(nil, for: .normal)
        }
        
        
        self.copyLabel.isHidden = true
        self.emotionPrediction = ""
        self.colorPrediction = ""

        self.videoManager.start()
      

    }
    
    func makeModel2() {
        // create a GET request for server to update the ML model with current data
        let baseURL = "\(SERVER_URL)/UpdateModel"
        let query = "?dsid=1&modelName=0"
        
        let getUrl = URL(string: baseURL+query)
        let request: URLRequest = URLRequest(url: getUrl!)
        let dataTask : URLSessionDataTask = self.session.dataTask(with: request, completionHandler:{(
            data, response, error) in  // handle error!
            if (error != nil) {
                if let res = response{
                    print("Response:\n",res)
                }
            }
            else{
                let jsonDictionary = self.convertDataToDictionary(with: data)
                
                if let resubAcc = jsonDictionary["resubAccuracy"]{
                    print("Resubstitution Accuracy is", resubAcc)
                }
            }
                                                                    
        })
        dataTask.resume() // start the task
    }
    
    
    func convertDictionaryToData(with jsonUpload:NSDictionary) -> Data?{
        do { // try to make JSON and deal with errors using do/catch block
            let requestBody = try JSONSerialization.data(withJSONObject: jsonUpload, options:JSONSerialization.WritingOptions.prettyPrinted)
            return requestBody
        } catch {
            print("json error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func convertDataToDictionary(with data:Data?)->NSDictionary{
        do { // try to parse JSON and deal with errors using do/catch block
            let jsonDictionary: NSDictionary =
                try JSONSerialization.jsonObject(with: data!, options:
                    JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            
            return jsonDictionary
            
        } catch {
            print("json error: \(error.localizedDescription)")
            return NSDictionary() // just return empty
        }
    }
    
    func sendFeatures(_ array:[String], withLabel label:String){
        
        let baseURL = "\(SERVER_URL)/AddDataPoint"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["feature":[self.base64string],
                                       "label":"Hi",
            "dsid":1,
            "modelName": 0]
        
       // print(jsonUpload)
        let requestBody:Data = self.convertDictionaryToData(with:jsonUpload)! // ? changed
        
        request.httpMethod = "POST"
        request.httpBody = requestBody
        
        let postTask : URLSessionDataTask = self.session.dataTask(with: request, completionHandler:
        {(data, response, error) in
            if(error != nil){
                if let res = response{
                    print("Response:\n",res)
                }
                
            }
            else{
                let jsonDictionary = self.convertDataToDictionary(with: data)
          //      print(jsonDictionary["feature"]!)
            //    print(jsonDictionary["label"]!)
                let colorResponse = jsonDictionary["prediction"]
                
                self.colorPrediction = colorResponse
            }
                                                                    
        })
        
        postTask.resume() // start the task
    }
    
    func getPrediction(_ array:[String]){
       // print("CALLING PREDICTION")
        let baseURL = "\(SERVER_URL)/PredictOne"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["feature":array, "dsid":1]
        
        
        let requestBody:Data = self.convertDictionaryToData(with:jsonUpload)! // changed ?
        
        request.httpMethod = "POST"
        request.httpBody = requestBody
        
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
          completionHandler:{(data, response, error) in
            if(error != nil){
                if let res = response{
                    print("Response:\n",res)
                }
            }
            else{
                let jsonDictionary = self.convertDataToDictionary(with: data)
                
                
                
                //if let colorPrediction = jsonDictionary["prediction"] as String{
                    //([u'light'])
                let colorPrediction = jsonDictionary["prediction"] as! String
           //     print("colorPrediction: ", colorPrediction)
                var newStr = ""
                
                var index = colorPrediction.index(colorPrediction.startIndex, offsetBy: 0)
                var i = 0
                while(colorPrediction[index] != "]"){
                    if(colorPrediction[index] == "[" || colorPrediction[index] == "'" /*|| colorPrediction[index] == "\""*/){}
                    else {
                        newStr += String(colorPrediction[index])
                    }
                    i += 1
                    index = colorPrediction.index(colorPrediction.startIndex, offsetBy: i)
                }
                    newStr.remove(at: newStr.startIndex)

                    self.colorPrediction = newStr
                    
                 //   print("Color response, ", self.colorPrediction)
                //}
                
                let emotionResponse = jsonDictionary["emotion"] as! String
             //   print("Emotion response, ", emotionResponse)

                self.emotionPrediction = emotionResponse
             //   print("Emotion Response, ", self.emotionPrediction)
                
                self.afterPrediction()
            }
                                                                    
        })
        
        postTask.resume() // start the task
    }
    
    func afterPrediction() {
        // set the buttons to corresponding emojis
        DispatchQueue.main.async {
            self.copyLabel.isHidden = false
        }
        for (i, emojiButton) in self.emojiButtons.enumerated() {
            var emoji = UIImage(named:"dark/angry-1")
            var str=""
            if(self.emotionPrediction as! String == "none"){
                str = "\(self.colorPrediction!)/\(self.emotionPrediction!)"
            //    print("str: ", str)
                emoji = UIImage(named:str) as UIImage?
            }  else {
                str = "\(self.colorPrediction!)/\(self.emotionPrediction!)-\(i+1)"
              //  print("str: ", str)
                 emoji = UIImage(named:str) as UIImage?
            }
            
          //  let emoji = UIImage(named: "dark/happy-1") as UIImage?
          //  print("emoji: ", emoji as Any)
           // print("type of emoji: ", type(of:emoji))
            DispatchQueue.main.async {
                emojiButton.setVals(emotion: self.emotionPrediction as! String)
                emojiButton.setImage(emoji, for: .normal)
                
                
                emojiButton.setImage(emoji, for: .normal)
              //  emojiButton.setBackgroundImage(emoji, for: .normal)
                emojiButton.isHidden = false
          //      print("emojibutton.isHidden: ", emojiButton.isHidden)
            //    print("emojibutton.emotion: ", emojiButton.emotion)
            }
        }
    }
    
    
    // this function should call the server
    // and get an emotion & skin tone prediction
    @objc func  buttonAction(sender: UIButton!) {
        
      //  print("title:", sender.currentTitle!)
        let i = Int(sender.currentTitle!)
        let faceImage = self.faceImages[i ?? 0];
        if(faceImage != nil) {
            //print("face image is not null")
            DispatchQueue.main.async {
                let ciContext = CIContext()
                let cgImage = ciContext.createCGImage(faceImage, from: faceImage.extent)
                let uiImage = UIImage.init(cgImage: cgImage!)
                let uiImageData:NSData = uiImage.pngData()! as NSData
                let strBase64 = uiImageData.base64EncodedString(options: .lineLength64Characters)
               // self.sendFeatures([self.base64string],withLabel:"Hi")
               // self.makeModel2()
                self.getPrediction([strBase64])
            }
        }
    }
    // here
    func makeButtons(i:Int, face:CIFaceFeature) {
       // print("mouthPosition: ", face.mouthPosition)
        let button = UIButton(frame: CGRect(x: face.bounds.midX/2, y: face.bounds.maxY, width: 50, height: 50))
        button.backgroundColor = .green
        button.setTitle(String(i), for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: UIControl.Event.touchUpInside)
        self.view.addSubview(button)
        self.greenButtons.append(button)
    }
    
    // this function should stop the videoManager
    // and have buttons appear so that user can
    // press & see predictions
    @IBAction func actuallyCapture(_ sender: Any) {
        self.bridge.setTransforms(self.videoManager.transform)
        for (i, face) in self.fGlobal.enumerated() {

            makeButtons(i: i, face: face);

            // Making photo appear in box
            let faceImage = self.bridge.capture(self.retImage, withBounds: face.bounds, // the first face bounds
                andContext: self.videoManager.getCIContext())
            
            if(faceImage != nil) {
               // print("face image is not null")
                self.faceImages.append(faceImage!)
            }
        }

        self.videoManager.stop()
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
        self.emojiButtons = [emojiButton1, emojiButton2, emojiButton3, emojiButton4, emojiButton5]
        self.bridge.processType = 1;

        self.videoManager = VideoAnalgesic.sharedInstance
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.front)
        
        // create dictionary for face detection
        // HINT: you need to manipulate these proerties for better face detection efficiency
        let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyLow,CIDetectorTracking:true] as [String : Any]
        
        // setup a face detector in swift
        self.detector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: self.videoManager.getCIContext(), // perform on the GPU is possible
            options: (optsDetector as [String : AnyObject]))
        
        let sessionConfig = URLSessionConfiguration.ephemeral
        self.base64string =
        """
        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
        

        """
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        self.session = URLSession(configuration: sessionConfig,
                                  delegate: self,
                                  delegateQueue:self.operationQueue)
        
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImage)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
    }
    
    //MARK: Process image output
    
    func processImage(inputImage:CIImage) -> CIImage{
        
        // detect faces
        let faces = getFaces(img: inputImage)
        
        // if no faces, just return original image
        if faces.count == 0 { return inputImage }
        
        self.fGlobal = faces
        self.retImage = inputImage
        
        // used for applying filter to faces
        
        self.bridge.setTransforms(self.videoManager.transform)
        
        for (i,face) in faces.enumerated() {
            print(i, face)
            
            self.bridge.setImage(self.retImage, withBounds: face.bounds, andContext: self.videoManager.getCIContext())
            
            self.bridge.processImage()
            
            self.retImage = self.bridge.getImageComposite()
        }
        return self.retImage
    }
    
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation]
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
        
    }
    

}

