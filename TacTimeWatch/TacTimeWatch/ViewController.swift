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

let calendarKey = "user_selected_calander"

class ViewController: UIViewController, SettingDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var arrivingText: UILabel!
    
    private let eventStore = EKEventStore()
    
    private var data: [WatchDataModel] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
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
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.swipped(_:)))
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.swipped(_:)))
        leftSwipeGesture.direction = .left
        self.tableView.addGestureRecognizer(rightSwipeGesture)
        self.tableView.addGestureRecognizer(leftSwipeGesture)
        
        self.fetchData()
        
        self.reload(nil)
//        self.parseAndSave(text: "Call hsam at 10:36 PM")
    }
    
    @IBAction func settings(_ sender: Any) {
        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController else {return}
        vc.fromDatePicker.date = self.fromDate
        vc.toDatePicker.date = self.toDate
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func reload(_ sender: Any?) {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            if !session.isPaired {
                self.alert(msg: "Watch not paired.", title: "Error")
                return
            }
            
            if !session.isWatchAppInstalled {
                self.alert(msg: "Watch app not installed", title: "Error")
                return
            }
            
        }else {
            self.alert(msg: "Watch Connectivity not supported in your device.", title: "Error")
            return
        }
    }
    
    @IBAction func addEvent(_ sender: Any) {
        let alert = UIAlertController(title: "Add Event", message: nil, preferredStyle: .alert)
        alert.addTextField { (textfield) in
            textfield.placeholder = "Event"
        }
        let okAction = UIAlertAction(title: "Ok", style: .default) { (_) in
            guard let text = alert.textFields?.first?.text, !text.isEmpty else {
                return
            }
            self.parseAndSave(text: text)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(okAction)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
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
        
        if !model.isValid {
            self.alert(msg: "Invalid event: \(text)", title: "Invalid")
            return
        }
        self.setEventInCalender(model: model, completion: {
            do {
                try managedContext.save()
                self.data.append(model)
                
//                self.tableView.reloadData()
            } catch let error as NSError {
                self.alert(msg: "Could not save. \(error), \(error.userInfo)", title: "Error")
            }
        })
    }
    
    private func getStartTimeAndEndTime(text: String) -> (Date?, Date?, String?) {
        let result = chrono.parsedResultsFrom(naturalLanguageString: text, referenceDate: nil)
        let startDate = result.startDate
        let endDate = result.endDate
        let ignoredText = result.ignoredText
        return (startDate, endDate, ignoredText)
    }
    
    private func removeEventFromCalender(model: WatchDataModel, completion: @escaping () ->()) {
        self.eventStore.requestAccess(to: .event, completion: {
            (granted,error) in
            guard let eventId = model.reminderId,
                let event = self.eventStore.event(withIdentifier: eventId)
                else {
                    completion()
                    return
            }
            do {
                try self.eventStore.remove(event, span: .thisEvent)
                completion()
            }catch {
                self.alert(msg: "Error removing event : \(error)", title: "Error")
                print("Error removing event : \(error)")
            }
        })
    }
    
    private func setEventInCalender(model: WatchDataModel, completion: @escaping () ->()) {
        guard let startDate = model.startDate as Date? else {return}
        let event = EKEvent(eventStore: self.eventStore)
        self.eventStore.requestAccess(to: .event, completion: {
            (granted,error) in
            if granted == true {
                event.title = model.note ?? "Task"
                event.startDate = startDate
                event.endDate = (model.endDate as Date?) ?? startDate
                
                func addEventToCalendar(calendar: EKCalendar) {
                    UserDefaults.standard.set(calendar.calendarIdentifier, forKey: calendarKey)
                    event.calendar = calendar
                    let alarm = EKAlarm(absoluteDate: startDate)
                    event.addAlarm(alarm)
                    
                    do {
                        try self.eventStore.save(event, span: .thisEvent, commit: true)
                        model.reminderId = event.eventIdentifier
                        model.alarm = true
                        completion()
                    }catch {
                        self.alert(msg: "Error creating and saving new event : \(error)", title: "Error")
                    }
                }
                
                if let calendarIdentifier = UserDefaults.standard.string(forKey: calendarKey),
                    let calendar = self.eventStore.calendar(withIdentifier: calendarIdentifier) {
                    addEventToCalendar(calendar: calendar)
                }else {
                    let alert = UIAlertController(title: "Choose Calender", message: nil, preferredStyle: .alert)
                    let calendars = self.eventStore.calendars(for: .event)
                    let filtered = calendars.filter({!$0.isImmutable && $0.allowsContentModifications})
                    if filtered.count == 1 {
                        addEventToCalendar(calendar: filtered.first!)
                    }else {
                        filtered.forEach({ (calendar) in
                            let action = UIAlertAction(title: calendar.title, style: .default, handler: { (_) in
                                addEventToCalendar(calendar: calendar)
                            })
                            alert.addAction(action)
                        })
                        
                        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                        alert.addAction(cancel)
                        
                        self.present(alert, animated: true, completion: nil)
                    }
                }

            }else {
                print("not granted")
            }
        })
    }
    
//    private func addOrRemoveAlarm(model: WatchDataModel) {
//        guard let startDate = model.startDate as Date? else {return}
//        self.eventStore.requestAccess(to: .event, completion: {
//            (granted,error) in
//            if granted {
//                guard let event = model.reminderId.flatMap ({self.eventStore.event(withIdentifier: $0)}) else {
//                    self.setEventInCalender(model: model)
//                    return
//                }
//
//                if model.alarm {
//                    let alarm = EKAlarm(absoluteDate: startDate)
//                    event.addAlarm(alarm)
//                }else {
//                    event.alarms?.forEach({
//                        event.removeAlarm($0)
//                    })
//                }
//
//                do {
//                    try self.eventStore.save(event, span: .thisEvent, commit: true)
//                }catch {
//                    model.alarm = !model.alarm
//                    print("Error creating and saving new event : \(error)")
//                }
//
//                DispatchQueue.main.async {
//                    self.tableView.reloadData()
//                }
//            }
//        })
//    }
    
//    private func setComplete(model: WatchDataModel) {
//
//        self.eventStore.requestAccess(to: EKEntityType.reminder, completion: {
//            (granted,error) in
//            if granted {
//
//                let reminder = model.reminderId.flatMap {self.eventStore.calendarItem(withIdentifier: $0) as? EKReminder}
//                model.alarm = false
//                self.addOrRemoveAlarm(model: model)
//                reminder?.isCompleted = true
//                reminder?.completionDate = model.completed as Date?
//                DispatchQueue.main.async {
//                    self.tableView.reloadData()
//                }
//            }
//        })
//    }
    
}

// MARK: UITableViewDelegate

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
            
            let model = self.data[indexPath.row]
            
            self.removeEventFromCalender(model: model, completion: {
                let managedContext =
                    appDelegate.persistentContainer.viewContext
                managedContext.delete(model)
                do {
                    try managedContext.save()
//                    self.data.append(model)
//                    self.removeEventFromCalender(model: model)
                    self.data.remove(at: indexPath.row)
//                    self.tableView.reloadData()
                } catch let error as NSError {
                    self.alert(msg: "Could not delete. \(error), \(error.userInfo)", title: "Error")
                }
            })
        }
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
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WatchDataTableViewCell", for: indexPath) as! WatchDataTableViewCell
        cell.data = self.data[indexPath.row]
        cell.onAlarm = {[weak self] status in
            if cell.data?.completed == nil {
                cell.data?.alarm = status
//                self?.addOrRemoveAlarm(model: cell.data!)
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

