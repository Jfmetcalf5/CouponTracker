//
//  CouponListTableViewController.swift
//  CouponTracker
//
//  Created by Jacob Metcalf on 8/23/18.
//  Copyright © 2018 JfMetcalf. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class CouponListTableViewController: UITableViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    let couponController = CouponController()
    let center = UNUserNotificationCenter.current()
    
    var refresh: UIRefreshControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkTheExpiredCoupons()
        
        searchBar.delegate = self
        
        refresh = UIRefreshControl()
        refresh?.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refresh?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        self.tableView.addSubview(refresh ?? UIRefreshControl())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        couponController.fetchCoupons()
        tableView.reloadData()
    }
    
    func checkTheExpiredCoupons() {
        if couponController.couponsThatExpired.count > 0 {
            var couponList = ""
            for coupon in couponController.couponsThatExpired {
                couponList.append("\(coupon.brand ?? ""), \(coupon.product ?? "")\n\(coupon.expDate ?? "")\n\n")
            }
            let alert = UIAlertController(title: "You have coupon(s) that are expired. Would you like to delete them?", message: couponList, preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "Yes", style: .default) { (yes) in
                for coupon in self.couponController.couponsThatExpired {
                    self.couponController.delete(coupon: coupon)
                }
            }
            
            let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
            
            alert.addAction(yesAction)
            alert.addAction(noAction)
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func refreshData() {
        couponController.fetchCoupons()
            tableView.reloadData()
            refresh?.endRefreshing()
    }
    
    @IBAction func categorySelected(_ sender: UISegmentedControl) {
        couponController.fetchCoupons()
        if sender.selectedSegmentIndex == 0 {
            self.couponController.coupons = self.couponController.coupons.filter({ $0.category == "food"})
            self.tableView.reloadData()
        } else {
            self.couponController.coupons = self.couponController.coupons.filter({ $0.category == "other"})
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Search Bar Delegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else { return }
        couponController.fetchCouponsWith(searchTerm: text)
            tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentControl.selectedSegmentIndex == 0 {
            couponController.coupons = couponController.coupons.filter({ $0.category == "food"})
            return couponController.coupons.count
        } else {
            couponController.coupons = couponController.coupons.filter({ $0.category == "other"})
            return couponController.coupons.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "couponCell", for: indexPath) as? CouponTableViewCell else { fatalError("Unable dequeue Cell as CouponTableViewCell") }
        
        let coupon = couponController.coupons[indexPath.row]
        cell.coupon = coupon
        
        return cell
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let coupon = couponController.coupons[indexPath.row]
            
            let center = UNUserNotificationCenter.current()
            let requestIdentifier = "\(coupon.brand ?? "UNKNOWN"), \(coupon.product ?? "UNKNOWN"), \(coupon.expDate ?? "UNKNOWN")"
            center.getPendingNotificationRequests { (requests) in
                for request in requests {
                    if request.identifier == requestIdentifier {
                        center.removeDeliveredNotifications(withIdentifiers: [requestIdentifier])
                    }
                }
            }
            
            couponController.delete(coupon: coupon)
            
            refreshData()
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailCoupon" {
            guard let indexPath = tableView.indexPathForSelectedRow,
                let detailVC = segue.destination as? CouponDetailViewController else { return }
            let coupon = couponController.coupons[indexPath.row]
            detailVC.couponController = couponController
            detailVC.coupon = coupon
        }
        if segue.identifier == "toAddNew" {
            guard let detailVC = segue.destination as? CouponDetailViewController else { return }
            detailVC.couponController = couponController
        }
    }
}
