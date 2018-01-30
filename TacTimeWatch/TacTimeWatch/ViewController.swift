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
    @IBOutlet weak var dateLabel: UILabel!
    
    private var data: [WatchDataModel] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    private var date: Date = Date() {
        didSet {
            setDate()
            fetchData()
        }
    }
    private let chrono = Chrono.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if WCSession.isSupported() {
            
            let session = WCSession.default
            if !session.isPaired {
                self.alert(msg: "Watch not paired.", title: "Error")
                return
            }
            
            if !session.isWatchAppInstalled {
                self.alert(msg: "Watch app not installed", title: "Error")
                return
            }
            
            session.delegate = self
            session.activate()
        }else {
            self.alert(msg: "Watch Connectivity not supported in your device.", title: "Error")
        }
        
        setDate()
        
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.swipped(_:)))
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.swipped(_:)))
        leftSwipeGesture.direction = .left
        self.tableView.addGestureRecognizer(rightSwipeGesture)
        self.tableView.addGestureRecognizer(leftSwipeGesture)
        
        ["7 AM to 8 PM work at office", "8 PM to 9:15 PM workout at gym", "9:20 PM to 10 PM Watch tv", "Talked with Pete yesterday 2AM to 3:15AM", "a day before yesterday I was working with my friend at 8 AM", "7:23 AM to 8:48 PM got ready for work", "yesterday 10:30 PM to 645 today got some sleep", "723 to 8:48 PM got ready for work", "723 to 8:48 AM should get ready for work"].forEach(parseAndSave)
       
    }
    
    func alert(msg: String, title: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: false, completion: nil)
    }
    
    @objc private func swipped(_ gesture: UISwipeGestureRecognizer) {
        if gesture.state == .ended {
            let multiplier: Double = gesture.direction.contains(.left) ? 1 : -1
            self.date = self.date.addingTimeInterval(24*60*60*multiplier)
            self.fetchData()
        }
    }
    
    private func setDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, dd MMM, YYYY"
        dateFormatter.locale = Locale(identifier: "en_US")
        self.dateLabel.text = dateFormatter.string(from: self.date)
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
        fetchRequest.predicate = NSPredicate(format: "(startDate >= %@) AND (startDate <= %@)", argumentArray: [date.startOfDay as NSDate, date.endOfDay! as NSDate])
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
//        return (nil, nil, nil)
        let result = chrono.parsedResultsFrom(naturalLanguageString: text, referenceDate: nil)
        let startDate = result.startDate
        let endDate = result.endDate
        let ignoredText = result.ignoredText
        return (startDate, endDate, ignoredText)
//        let newText = textReplacingMultipleSpaces(text: text)
//        let startToEndTime = matches(for: "((((^([0-9]|0[0-9]|1[0-9])| ([0-9]|0[0-9]|1[0-9])))|(([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9])) (AM|PM)) to (((([0-9]|0[0-9]|1[0-9])| ([0-9]|0[0-9]|1[0-9]))|(([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9])) (AM|PM))", in: newText)
//        let splitted = startToEndTime.first?.components(separatedBy: " to ")
//        let start = splitted?.first?.trimmingCharacters(in: .whitespacesAndNewlines)
//        let end = splitted?.last?.trimmingCharacters(in: .whitespacesAndNewlines)
//        let remainingText = startToEndTime.first.map({text.components(separatedBy: $0)})?.last?.trimmingCharacters(in: .whitespacesAndNewlines)
//
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "dd/MM/yyyy"
//        dateFormatter.locale = Locale(identifier: "en_US")
//        let dateString = dateFormatter.string(from: Date())
//
//        let dateFormatter1 = DateFormatter()
//        dateFormatter1.dateFormat = "dd/MM/yyyy'T'h:mm a"
//        dateFormatter1.locale = Locale(identifier: "en_US")
//
//        let dateFormatter2 = DateFormatter()
//        dateFormatter2.dateFormat = "dd/MM/yyyy'T'h a"
//        dateFormatter2.locale = Locale(identifier: "en_US")
//
//        let startDate: Date? = start.flatMap({
//            let completeDate = dateString + "T" + $0
//            return dateFormatter1.date(from: completeDate) ?? dateFormatter2.date(from: completeDate)
//        })
//        let endDate: Date? = end.flatMap({
//            let completeDate = dateString + "T" + $0
//            return dateFormatter1.date(from: completeDate) ?? dateFormatter2.date(from: completeDate)
//        })
//        return (startDate, endDate, remainingText)
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
        let count = self.data.count
        if count == 0 {
            let label = UILabel(frame: tableView.bounds)
            label.textColor = .black
            label.text = "No Data"
            label.textAlignment = .center
            tableView.backgroundView = label
        }else {
            tableView.backgroundView = nil
        }
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

