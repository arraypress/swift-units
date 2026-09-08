//
//  Formatting.swift
//  Units
//

import Foundation

public extension Measurement where UnitType == Dimension {
    
    /// Short, readable, locale-aware — "39.37 ft".
    ///
    /// Significant digits rather than a fixed decimal count: 39.37 ft is
    /// useful, 0.00 kg is not, and 1200.000000001 km is noise.
    func short(locale: Locale = .current, maximumFractionDigits: Int = 2) -> String {
        let formatter = MeasurementFormatter()
        formatter.locale = locale
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = maximumFractionDigits
        formatter.numberFormatter.minimumFractionDigits = 0
        return formatter.string(from: self)
    }
    
    /// "12 m ≈ 39.37 ft" — the whole conversion in one line.
    ///
    /// Uses ≈ rather than = because almost every cross-system conversion is
    /// rounded, and claiming equality would be a small lie repeated constantly.
    func summary(with converted: Measurement<Dimension>, locale: Locale = .current) -> String {
        "\(short(locale: locale)) ≈ \(converted.short(locale: locale))"
    }
}
