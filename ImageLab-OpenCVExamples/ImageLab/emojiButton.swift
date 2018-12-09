//
//  emojiButton.swift
//  ImageLab
//
//  Created by Samuel Lefcourt on 12/9/18.
//  Copyright © 2018 Eric Larson. All rights reserved.
//

import Foundation
class EmojiButton: UIButton {
    var emotion: String
    func setVals(emotion: String = "hi") {
        // set myValue before super.init is called
        self.emotion = emotion
        
        
        // set other operations after super.init, if required
        self.isHidden = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.emotion = "Default"
        super.init(frame: .zero)
        self.setVals()
       // super.init(coder: aDecoder)
    }
    
    @IBAction func pressed() {
//        UIPasteboard.generalPasteboard().image = image;
    }
}

