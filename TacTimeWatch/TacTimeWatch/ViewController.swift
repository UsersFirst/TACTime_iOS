//
//  ViewController.swift
//  TacTimeWatch
//
//  Created by bibek timalsina on 1/24/18.
//  Copyright © 2018 bibek timalsina. All rights reserved.
//

import UIKit
import WatchConnectivity

class ViewController: UIViewController {

    @IBOutlet weak var myLabel: UILabel!
    let session = WCSession.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        session.delegate = self
        session.activate()
    }
}

// MARK: WCSessionDelegate
extension ViewController: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let msg = message["INPUT"] as! String
        DispatchQueue.main.async {
            self.myLabel.text = "Message : \(msg)"
        }
        print("recieved message in iphone")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    
}

