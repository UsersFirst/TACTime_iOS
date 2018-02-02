//
//  SettingsViewController.swift
//  TacTimeWatch
//
//  Created by bibek timalsina on 1/30/18.
//  Copyright © 2018 bibek timalsina. All rights reserved.
//

import UIKit
import CoreData
import MessageUI

protocol SettingDelegate:class {
    func filter(from: Date, to: Date)
}

class SettingsViewController: UIViewController, MFMailComposeViewControllerDelegate {
    @IBOutlet weak var fromTextField: UITextField!
    @IBOutlet weak var toTextField: UITextField!
    
    let fromDatePicker: UIDatePicker = UIDatePicker()
    let toDatePicker: UIDatePicker = UIDatePicker()
    
    weak var delegate: SettingDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fromDatePicker.maximumDate = Date()
        self.fromDatePicker.datePickerMode = .date
        self.fromDatePicker.locale = Locale(identifier: "en_US")
        self.fromDatePicker.addTarget(self, action: #selector(self.fromDatePicked), for: .valueChanged)
        self.fromTextField.inputView = fromDatePicker
        
        self.toDatePicker.maximumDate = Date()
        self.toDatePicker.datePickerMode = .date
        self.toDatePicker.locale = Locale(identifier: "en_US")
        self.toDatePicker.addTarget(self, action: #selector(self.toDatePicked), for: .valueChanged)
        self.toTextField.inputView = toDatePicker
        
        fromDatePicked()
        toDatePicked()
    }
    
    @objc func fromDatePicked() {
        self.fromTextField.text = DateFormatter.toString(date: fromDatePicker.date)
    }
    
    @objc func toDatePicked() {
        self.toTextField.text = DateFormatter.toString(date: toDatePicker.date)
    }
    
    private func fetchData() -> [WatchDataModel] {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return []
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "WatchDataModel")
        fetchRequest.predicate = NSPredicate(format: "(startDate >= %@) AND (startDate <= %@)", argumentArray: [fromDatePicker.date.startOfDay as NSDate, toDatePicker.date.endOfDay! as NSDate])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        do {
            return try managedContext.fetch(fetchRequest) as! [WatchDataModel]
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return []
    }
    
    @IBAction func filter(_ sender: Any) {
        fromDatePicked()
        toDatePicked()
        self.delegate?.filter(from: fromDatePicker.date.startOfDay, to: toDatePicker.date.endOfDay!)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func export(_ sender: Any) {
        self.view.endEditing(true)
        let fileName = "Tasks.csv"
        let path = URL.init(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        var csvText = WatchDataModel.stringFormat
        let result = self.fetchData()
        if result.count > 0 {
            csvText = result.reduce(csvText) { (result, model) -> String in
                return result + "\n" + model.toString
            }
            do {
                try csvText.write(to: path, atomically: true, encoding: .utf8)
                self.sendMail(path: path)
            } catch {
                print(error)
                self.alert(msg: "Cant create the file.", title: "Error")
            }
        }else {
            self.alert(msg: "No data in this range.", title: "Error")
        }
        
    }
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func sendMail(path: URL) {
        if MFMailComposeViewController.canSendMail(), let data = try? Data.init(contentsOf: path) {
            let emailController = MFMailComposeViewController()
            emailController.mailComposeDelegate = self
            emailController.setToRecipients([])
            emailController.setSubject("Tasks from \(ISO8601DateFormatter().string(from: self.fromDatePicker.date)) to \(ISO8601DateFormatter().string(from: self.toDatePicker.date))")
            emailController.setMessageBody("Hi, please find the csv attachment.", isHTML: false)
            emailController.addAttachmentData(data, mimeType: "text/csv", fileName: "tasks.csv")
            self.present(emailController, animated: true, completion: nil)
        }else {
            self.alert(msg: "Can't send the mail.", title: "Error")
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) {
            if error != nil {
                print(error ?? "")
                self.alert(msg: "Failed to send.", title: "Error")
            }
        }
    }
    
}
