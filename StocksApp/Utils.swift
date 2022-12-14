//
//  Utils.swift
//  StocksApp
//
//  Created by mufkhalif on 07/12/22.
//

import Foundation


struct Utils {
    static let numberFormater: NumberFormatter = {
       let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = ""
        formatter.currencyDecimalSeparator = "."
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    static func format(value: Double?) -> String? {
        guard let value,
              let text = numberFormater.string(from: NSNumber(value: value))
        else { return nil }
        return text
    }
    
    
}
