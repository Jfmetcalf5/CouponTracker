//
//  CouponTableViewCell.swift
//  CouponTracker
//
//  Created by Jacob Metcalf on 8/24/18.
//  Copyright © 2018 JfMetcalf. All rights reserved.
//

import UIKit

class CouponTableViewCell: UITableViewCell {

    @IBOutlet weak var brandLabel: UILabel!
    @IBOutlet weak var productLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    
    var coupon: Coupon? {
        didSet {
            updateViews()
        }
    }
    
    func updateViews() {
        guard let coupon = coupon else { return }
        brandLabel.text = coupon.brand
        productLabel.text = coupon.product
        dateLabel.text = coupon.expDate
        quantityLabel.text = "Qty: \(coupon.quantity!)"
    }
    
}
