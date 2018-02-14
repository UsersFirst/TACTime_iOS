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

let scribbleKey = "IsScribbleOn"
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
        textInputButtonPressed()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func textInputButtonPressed() {

        func sendMessage(results: [Any]?) {
            if results != nil && results!.count > 0 {
                if let aResult = results?[0] as? String {
                    self.myLabel.setText(aResult)
                    //Send Data to iOS
                    if self.session.isReachable {
                        let msg = ["INPUT" : aResult]
                        //                        DispatchQueue.main.async {
                        self.session.sendMessage(msg, replyHandler: nil, errorHandler: { (error) in
                            print("MESSAGE SEND FAILED \(error.localizedDescription)")
                        })
                        //                        }
                    }else {
                        print("SESSION UNREACHABLE")
                    }
                }
            }
        }
        
        if UserDefaults.standard.bool(forKey: scribbleKey) {
            self.presentTextInputController(
                withSuggestions: nil,
                allowedInputMode: .plain,
                completion: sendMessage)
        }else {
            self.presentTextInputControllerWithSuggestions(forLanguage: { (lang) -> [Any]? in
                return []
            }, allowedInputMode: .plain,
               completion: sendMessage)
        }
    }
    
}

// MARK: WCSessionDelegate
extension InterfaceController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let scribbleIsOn = message[scribbleKey] as? Bool {
            UserDefaults.standard.set(scribbleIsOn, forKey: scribbleKey)
        }
    }
}
