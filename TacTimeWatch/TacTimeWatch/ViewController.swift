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
import  EventKit

class ViewController: UIViewController, SettingDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var dateLabel: UILabel!
    
    private let eventStore = EKEventStore()
    
    private var data: [WatchDataModel] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    private var fromDate: Date = Date().startOfDay
    
    private var toDate: Date = Date().endOfDay! {
        didSet {
            setDate()
            fetchData()
        }
    }
    
    private let chrono = Chrono.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDate()
        
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.swipped(_:)))
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.swipped(_:)))
        leftSwipeGesture.direction = .left
        self.tableView.addGestureRecognizer(rightSwipeGesture)
        self.tableView.addGestureRecognizer(leftSwipeGesture)
        
        self.fetchData()
        self.parseAndSave(text: "Call hsam at 10:36 PM")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
            return
        }
    }
    
    @IBAction func settings(_ sender: Any) {
        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController else {return}
        vc.fromDatePicker.date = self.fromDate
        vc.toDatePicker.date = self.toDate
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    func filter(from: Date, to: Date) {
        self.fromDate = from
        self.toDate = to
    }
    
    @objc private func swipped(_ gesture: UISwipeGestureRecognizer) {
        if gesture.state == .ended {
            let multiplier: Double = gesture.direction.contains(.left) ? 1 : -1
            self.fromDate = self.fromDate.addingTimeInterval(24*60*60*multiplier)
            self.toDate = self.toDate.addingTimeInterval(24*60*60*multiplier)
            self.fetchData()
        }
    }
    
    private func setDate() {
        self.dateLabel.text = DateFormatter.toString(date: self.fromDate)
        if abs(self.fromDate.timeIntervalSince(self.toDate)) > 24*60*60 {
            self.dateLabel.text = self.dateLabel.text! + " to " + DateFormatter.toString(date: self.toDate)
        }
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
        fetchRequest.predicate = NSPredicate(format: "(startDate >= %@) AND (startDate <= %@)", argumentArray: [fromDate as NSDate, toDate as NSDate])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
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
        model.alarm = true
        
        do {
            try managedContext.save()
            self.data.append(model)
            self.setEventInCalender(model: model)
            self.tableView.reloadData()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    private func getStartTimeAndEndTime(text: String) -> (Date?, Date?, String?) {
        let result = chrono.parsedResultsFrom(naturalLanguageString: text, referenceDate: nil)
        let startDate = result.startDate
        let endDate = result.endDate
        let ignoredText = result.ignoredText
        return (startDate, endDate, ignoredText)
    }
    
    private func setEventInCalender(model: WatchDataModel) {
        guard let startDate = model.startDate as Date? else {return}
        let event = EKEvent(eventStore: self.eventStore)
        self.eventStore.requestAccess(to: .event, completion: {
            (granted,error) in
            if granted == true {
                event.title = model.note ?? "Task"
                event.startDate = startDate
                event.endDate = (model.endDate as Date?) ?? startDate
                event.calendar = self.eventStore.defaultCalendarForNewEvents

                let alarm = EKAlarm(absoluteDate: startDate)
                event.addAlarm(alarm)
                
                do {
                    try self.eventStore.save(event, span: .thisEvent, commit: true)
                    model.reminderId = event.eventIdentifier
                    model.alarm = true
                }catch {
                    print("Error creating and saving new event : \(error)")
                }
            }else {
                print("not granted")
            }
        })
    }
    
    private func addOrRemoveAlarm(model: WatchDataModel) {
        guard let startDate = model.startDate as Date? else {return}
        self.eventStore.requestAccess(to: .event, completion: {
            (granted,error) in
            if granted {
                guard let event = model.reminderId.flatMap ({self.eventStore.event(withIdentifier: $0)}) else {
                    self.setEventInCalender(model: model)
                    return
                }
                
                if model.alarm {
                    let alarm = EKAlarm(absoluteDate: startDate)
                    event.addAlarm(alarm)
                }else {
                    event.alarms?.forEach({
                        event.removeAlarm($0)
                    })
                }
                
                do {
                    try self.eventStore.save(event, span: .thisEvent, commit: true)
                }catch {
                    model.alarm = !model.alarm
                    print("Error creating and saving new event : \(error)")
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        })
    }
    
    private func setComplete(model: WatchDataModel) {
        
        self.eventStore.requestAccess(to: EKEntityType.reminder, completion: {
            (granted,error) in
            if granted {
                
                let reminder = model.reminderId.flatMap {self.eventStore.calendarItem(withIdentifier: $0) as? EKReminder}
                model.alarm = false
                self.addOrRemoveAlarm(model: model)
                reminder?.isCompleted = true
                reminder?.completionDate = model.completed as Date?
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        })
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
        cell.onAlarm = {[weak self] status in
            if cell.data?.completed == nil {
                cell.data?.alarm = status
                self?.addOrRemoveAlarm(model: cell.data!)
                tableView.reloadData()
            }
        }
//        cell.onComplete = {[weak self] in
//            cell.data?.completed = Date() as NSDate
//            self?.setComplete(model: cell.data!)
//            tableView.reloadData()
//        }
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

extension UIViewController {
    func alert(msg: String, title: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: false, completion: nil)
    }
}

