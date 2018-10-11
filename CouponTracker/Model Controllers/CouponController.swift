//
//  CouponController.swift
//  CouponTracker
//
//  Created by Jacob Metcalf on 8/23/18.
//  Copyright © 2018 JfMetcalf. All rights reserved.
//

import Foundation
import CoreData

class CouponController {
    
    init() {
        fetchCoupons()
        sortThrough(coupons: self.coupons)
    }
    
    var coupons: [Coupon] = []
    
    @discardableResult func createCouponWith(brand: String, product: String, category: CategoryType, expDate: String, quantity: String) -> Coupon {
        let coupon = Coupon(brand: brand, product: product, category: category.rawValue, expDate: expDate, quantity: quantity)
        saveToCoreData()
        return coupon
    }
    
    func delete(coupon: Coupon) {
        let moc = CoreDataStack.shared.mainContext
        moc.delete(coupon)
        saveToCoreData()
    }
    
    func update(coupon: Coupon, with brand: String, product: String, category: CategoryType, expDate: String, quantity: String) {
        coupon.brand = brand
        coupon.product = product
        coupon.category = category.rawValue
        coupon.expDate = expDate
        coupon.quantity = quantity
        saveToCoreData()
    }
    
    func saveToCoreData() {
        let moc = CoreDataStack.shared.mainContext
        do {
            try moc.save()
        } catch {
            NSLog("Error saving to Core Data: \(error.localizedDescription)")
        }
    }
    
    func fetchCoupons() {
        let fetchRequest: NSFetchRequest<Coupon> = Coupon.fetchRequest()
        
        do {
            let fetchedCoupons = try CoreDataStack.shared.mainContext.fetch(fetchRequest)
            self.coupons = fetchedCoupons
        } catch {
            NSLog("Unable to fetch coupons: \(error.localizedDescription)")
        }
    }
    
    func fetchCouponsWith(searchTerm: String) {
        fetchCoupons()
        if searchTerm != "" {
            let searchedCoupons = self.coupons.filter({($0.brand?.lowercased() ?? "").contains(searchTerm.lowercased()) || ($0.product?.lowercased() ?? "").contains(searchTerm.lowercased())})
            self.coupons = searchedCoupons
        } else {
            fetchCoupons()
        }
    }
    
    var couponsThatExpired: [Coupon] = []
    func sortThrough(coupons: [Coupon]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        for coupon in coupons {
            if let expDateString = coupon.expDate {
                if let expDate = dateFormatter.date(from: expDateString) {
                    if expDate <= Date().addingTimeInterval(-66400) {
                        couponsThatExpired.append(coupon)
                    }
                }
            }
        }
    }
}
