//
//  Resources.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import SwiftUI

// MARK: - Extensions

extension Binding {
    func toUnwrapped<T>(defaultValue: T) -> Binding<T> where Value == Optional<T>  {
        Binding<T>(get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0 })
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components)!
    }
}

extension Calendar {
    func generateDates(
        inside interval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)

        enumerateDates(
            startingAfter: interval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date < interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }

        return dates
    }
}

extension Date {
    static func random(in range: ClosedRange<Date>) -> Date {
        let diff = range.upperBound.timeIntervalSinceReferenceDate - range.lowerBound.timeIntervalSinceReferenceDate
        let randomValue = Double.random(in: 0..<diff)
        return Date(timeIntervalSinceReferenceDate: range.lowerBound.timeIntervalSinceReferenceDate + randomValue)
    }
}

extension Double {
    func rounded(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// MARK: - Enums

enum ColorTheme: String, CaseIterable, Equatable {
    case standard
    case minty
    case lavender
    case sunrise
    case stonks
    case monochrome
    case flamingo
}

enum DeleteType: String {
    case inventory = "Inventory"
    case soldItems = "Sold Items"
    case tags = "Tags"
    case everything = "Everything"
    case error = "Error"
}

enum InputError: String {
    case invalidQuantity = "Quantity must be between at least 1."
    case invalidPurchasePrice = "Purchase price must be at least $0."
    case invalidListedPrice = "Listed price must be at least $0."
}

enum SearchMode {
    case inventory
    case receipts
}
