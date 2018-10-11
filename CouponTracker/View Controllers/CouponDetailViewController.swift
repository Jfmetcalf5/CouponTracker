//
//  CouponDetailViewController.swift
//  CouponTracker
//
//  Created by Jacob Metcalf on 8/24/18.
//  Copyright © 2018 JfMetcalf. All rights reserved.
//

import UIKit
import UserNotifications

enum CategoryType: String {
    case food
    case other
    
    static let categories: [CategoryType] = [.food, .other]
}

class CouponDetailViewController: ShiftableViewController, UNUserNotificationCenterDelegate {
    
    @IBOutlet var toolBar: UIToolbar!
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet weak var quantityBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var brandTextField: UITextField!
    @IBOutlet weak var productTextField: UITextField!
    @IBOutlet weak var expDateTextField: UITextField!
    @IBOutlet weak var segmentCategory: UISegmentedControl!
    @IBOutlet weak var noneButton: UIButton!
    
    var couponController: CouponController?
    
    var coupon: Coupon? {
        didSet {
            updateViews()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        brandTextField.delegate = self
        productTextField.delegate = self
        expDateTextField.delegate = self
        expDateTextField.inputView = datePicker
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        expDateTextField.inputAccessoryView = toolBar
        datePicker.heightAnchor.constraint(equalTo: expDateTextField.heightAnchor, multiplier: 4)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateViews()
    }
    
    //MARK: - Slider
    
    @IBAction func sliderSliding(_ sender: UISlider) {
        quantityBarButtonItem.title = "Qty: \(Int(sender.value))"
    }
    
    
    //MARK: - Button Actions
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        view.endEditing(true)
    }
    
    @IBAction func clearButtonTapped(_ sender: UIBarButtonItem) {
        expDateTextField.text = ""
        view.endEditing(true)
    }
    
    @IBAction func noneButtonTapped(_ sender: UIButton) {
        expDateTextField.text = "None"
    }
    
    func returnDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        return dateFormatter
    }
    
    
    //MARK: - Save and Update Functions
    
    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        let category = CategoryType.categories[segmentCategory.selectedSegmentIndex]
        let quantity = String(Int(slider.value))
        guard let brand = brandTextField.text, brand != "",
            let product = productTextField.text, product != "",
            let expDateString = expDateTextField.text, expDateString != "" else {
                let alert = UIAlertController(title: "Missing Information", message: "Please fill in all text fields", preferredStyle: .alert)
                let okayAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
                alert.addAction(okayAction)
                self.present(alert, animated: true, completion: nil)
                return }
        
        let dateFormatter = returnDateFormatter()
        if let date = dateFormatter.date(from: expDateString) {
            if date < Date() {
                let alert = UIAlertController(title: "\(expDateString) is before today's date... Your coupon has already expired", message: "Please make sure your dates match up", preferredStyle: .alert)
                let okayAction = UIAlertAction(title: "Okay", style: .default) { (okay) in
                    return
                }
                
                alert.addAction(okayAction)
                
                self.present(alert, animated: true, completion: nil)
                return 
            }
        }
        
        if let coupon = coupon {
            couponController?.update(coupon: coupon, with: brand, product: product, category: category, expDate: expDateString, quantity: quantity)
            setUpTimerFor(coupon: coupon)
        } else {
            let newCoupon = couponController!.createCouponWith(brand: brand, product: product,  category: category, expDate: expDateString, quantity: quantity)
            setUpTimerFor(coupon: newCoupon)
        }
        navigationController?.popViewController(animated: true)
    }
    
    func setUpTimerFor(coupon: Coupon) {
        
        let dateFormatter = returnDateFormatter()
        guard let expDate = dateFormatter.date(from: coupon.expDate ?? "") else { return }
        let notifDate = expDate.addingTimeInterval(-604800)
        
        let dateComponentsFormatter = DateComponentsFormatter()
        dateComponentsFormatter.allowedUnits = [.second]
        dateComponentsFormatter.maximumUnitCount = 1
        dateComponentsFormatter.unitsStyle = .short
        guard let numOfSecondsString = dateComponentsFormatter.string(from: Date(), to: notifDate) else { return }
        var totalSecondsString = ""
        for char in numOfSecondsString {
            if let _ = Double("\(char)") {
                totalSecondsString.append(char)
            }
        }
        
        guard var totalSeconds = Double(totalSecondsString) else { return }
        
        if numOfSecondsString.contains("-") {
            totalSeconds = 30
        }
        
        if expDate < Date().addingTimeInterval(-66400) { return }
        
        // Grabs the identifier to check if a TimeIntervalTrigger already has the same Identifier, if so it will remove that one and add the new one
        let requestIdentifier = "\(coupon.brand ?? "UNKNOWN"), \(coupon.product ?? "UNKNOWN"), \(coupon.expDate ?? "UNKNOWN")"
        
        let content = UNMutableNotificationContent()
        content.title = "\(coupon.brand ?? "UNKNOWN"), \(coupon.product ?? "UNKNOWN") is about to expire!"
        content.body = "The exp date is \(coupon.expDate ?? "UNKNOWN")!"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: totalSeconds, repeats: false)
        let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        center.getPendingNotificationRequests { (requests) in
            for pendingRequest in requests {
                if pendingRequest.identifier == requestIdentifier {
                    center.removePendingNotificationRequests(withIdentifiers: [requestIdentifier])
                }
            }
            center.add(request) { (error) in
                if let error = error {
                    NSLog("There was an errr scheduling a notification: \(error.localizedDescription)")
                    return
                }
            }
        }
    }
    
    func disableEverything() {
        brandTextField.isEnabled = false
        brandTextField.borderStyle = .none
        brandTextField.font = UIFont(name: "Bold", size: 17)
        brandTextField.backgroundColor = UIColor.white
        productTextField.isEnabled = false
        productTextField.borderStyle = .none
        productTextField.font = UIFont(name: "Bold", size: 17)
        productTextField.backgroundColor = UIColor.white
        expDateTextField.isEnabled = false
        expDateTextField.borderStyle = .none
        expDateTextField.font = UIFont(name: "", size: 17)
        expDateTextField.backgroundColor = UIColor.white
        noneButton.isHidden = true
        noneButton.isEnabled = false
    }
    
    func updateViews() {
        if isViewLoaded {
            let dateFormatter = returnDateFormatter()
            guard let coupon = coupon else {
                title = "New Coupon"
                return }
            disableEverything()
            
            title = coupon.product
            let quantityString = String(coupon.quantity!.last!)
            if quantityString == "O" {
                slider.value = 10
            } else {
                slider.value = (Float(quantityString))!
            }
            quantityBarButtonItem.title = "Qty: \(coupon.quantity!)"
            brandTextField.text = coupon.brand
            productTextField.text = coupon.product
            expDateTextField.text = coupon.expDate
            
            if let expDateString = coupon.expDate {
                if let expDate = dateFormatter.date(from: expDateString) {
                    datePicker.setDate(expDate, animated: true)
                }
            }
            
            guard let categoryString = coupon.category,
                let category = CategoryType(rawValue: categoryString) else { return }
            
            segmentCategory.selectedSegmentIndex = CategoryType.categories.index(of: category)!
        }
    }
    
    
    //MARK: - DatePicker Function
    @objc func dateChanged() {
        let dateFormatter = returnDateFormatter()
        expDateTextField.text = dateFormatter.string(from: datePicker.date)
    }
    
}
