//
//  SettingsViewController.swift
//  TacTimeWatch
//
//  Created by bibek timalsina on 1/30/18.
//  Copyright © 2018 bibek timalsina. All rights reserved.
//

import UIKit

protocol SettingDelegate:class {
    func filter(from: Date, to: Date)
}

class SettingsViewController: UIViewController {
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
    }
    
    @objc func fromDatePicked() {
        self.fromTextField.text = DateFormatter.toString(date: fromDatePicker.date)
    }
    
    @objc func toDatePicked() {
        self.toTextField.text = DateFormatter.toString(date: toDatePicker.date)
    }
    
    @IBAction func filter(_ sender: Any) {
        fromDatePicked()
        toDatePicked()
        self.delegate?.filter(from: fromDatePicker.date, to: toDatePicker.date)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func export(_ sender: Any) {
        
    }
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
