//
//  InterfaceController.swift
//  TacTimeWatch WatchKit Extension
//
//  Created by bibek timalsina on 1/24/18.
//  Copyright © 2018 bibek timalsina. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController {
    
    @IBOutlet var myLabel: WKInterfaceLabel!
    @IBOutlet var textInputButton: WKInterfaceButton!
    
    let session = WCSession.default
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        session.delegate = self
        session.activate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func textInputButtonPressed() {
        self.presentTextInputControllerWithSuggestions(forLanguage: { (lang) -> [Any]? in
            return ["7 AM to 8 PM work at office", "8 PM to 9:15 PM workout at gym", "9:20 PM to 10 PM Watch tv"]
        }, allowedInputMode: WKTextInputMode.plain) { (results) in
            if results != nil && results!.count > 0 {
                if let aResult = results?[0] as? String {
                    self.myLabel.setText(aResult)
                    //Send Data to iOS
                    if self.session.isReachable {
                        let msg = ["INPUT" : aResult]
                        self.session.sendMessage(msg, replyHandler: nil, errorHandler: { (error) in
                            print("MESSAGE SEND FAILED \(error.localizedDescription)")
                        })
                    }else {
                        print("SESSION UNREACHABLE")
                    }
                }
            }
        }
    }
}

// MARK: WCSessionDelegate
extension InterfaceController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
}
