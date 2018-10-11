//
//  Coupon+Convenience.swift
//  CouponTracker
//
//  Created by Jacob Metcalf on 8/23/18.
//  Copyright © 2018 JfMetcalf. All rights reserved.
//

import Foundation
import CoreData

extension Coupon {
    
    convenience init(brand: String, product: String, category: String, expDate: String = "None", quantity: String = "1", context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        self.init(context: context)
        self.brand = brand
        self.product = product
        self.category = category
        self.expDate = expDate
        self.quantity = quantity
    }
    
}
