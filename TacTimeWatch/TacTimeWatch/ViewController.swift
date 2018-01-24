//
//  ViewController.swift
//  TacTimeWatch
//
//  Created by bibek timalsina on 1/24/18.
//  Copyright © 2018 bibek timalsina. All rights reserved.
//

import UIKit
import WatchConnectivity
import CoreData

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let session = WCSession.default
    var data: [WatchDataModel] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        session.delegate = self
        session.activate()
        
        tableView.dataSource = self
        ["7 AM to 8 PM work at office", "8 PM to 9:15 PM workout at gym", "9:20 PM to 10 PM Watch tv"].forEach(parseAndSave)
    }
    
    private func fetchData() {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "WatchDataModel")
        do {
            data = try managedContext.fetch(fetchRequest) as! [WatchDataModel]
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    private func parseAndSave(text: String) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let entity =
            NSEntityDescription.entity(forEntityName: "WatchDataModel",
                                       in: managedContext)!
        
        let model = WatchDataModel(entity: entity,
                                     insertInto: managedContext)
        
        let dates = getStartTimeAndEndTime(text: text)
        
        model.text = text
        model.startDate = dates.0 as NSDate?
        model.endDate = dates.1 as NSDate?
        model.note = dates.2
        
        do {
            try managedContext.save()
            self.data.append(model)
            self.tableView.reloadData()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    private func getStartTimeAndEndTime(text: String) -> (Date?, Date?, String?) {
        let newText = textReplacingMultipleSpaces(text: text)
        let startToEndTime = matches(for: "((((^([0-9]|0[0-9]|1[0-9])| ([0-9]|0[0-9]|1[0-9])))|(([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9])) (AM|PM)) to (((([0-9]|0[0-9]|1[0-9])| ([0-9]|0[0-9]|1[0-9]))|(([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9])) (AM|PM))", in: newText)
        let splitted = startToEndTime.first?.components(separatedBy: " to ")
        let start = splitted?.first?.trimmingCharacters(in: .whitespacesAndNewlines)
        let end = splitted?.last?.trimmingCharacters(in: .whitespacesAndNewlines)
        let remainingText = startToEndTime.first.map({text.components(separatedBy: $0)})?.last?.trimmingCharacters(in: .whitespacesAndNewlines)
        let dateFormatter1 = DateFormatter()
        dateFormatter1.dateFormat = "h:mm a"
        dateFormatter1.locale = Locale(identifier: "en_US")
        
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "h a"
        dateFormatter2.locale = Locale(identifier: "en_US")
        
        let startDate = start.flatMap({
            dateFormatter1.date(from: $0) ?? dateFormatter2.date(from: $0)
        })
        let endDate = end.flatMap({
             dateFormatter1.date(from: $0) ?? dateFormatter2.date(from: $0)
        })
        return (startDate, endDate, remainingText)
    }
    
    private func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
   private func textReplacingMultipleSpaces(text: String) -> String {
        let matched = matches(for: "\\s+", in: text).sorted(by: {$0.count > $1.count})
        var newText = text
        matched.forEach({
            if $0.count > 1 {
                newText = newText.replacingOccurrences(of: $0, with: " ")
            }
        })
        return newText
    }
}

// MARK: UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WatchDataTableViewCell", for: indexPath) as! WatchDataTableViewCell
        cell.data = self.data[indexPath.row]
        return cell
    }
}

// MARK: WCSessionDelegate
extension ViewController: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let msg = message["INPUT"] as! String
        DispatchQueue.main.async {
            self.parseAndSave(text: msg)
            print("Message : \(msg)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
}

