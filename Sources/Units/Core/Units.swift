//
//  Units.swift
//  Units
//

import Foundation

/// Measurements as plain values — parse what someone wrote, convert it, print it.
///
/// Foundation already converts; `Measurement.converted(to:)` is one line. What
/// it has no answer for is the string. This turns "12 m", "12m", "12 metres",
/// "5'11\"" and "3 lb 4 oz" into something `Measurement` can work with, and
/// knows that "m" is metres while "min" is minutes.
public enum Units {
    
    // MARK: - Parsing
    
    /// The first measurement in a string, or nil.
    ///
    /// ```swift
    /// Units.parse("about 12 m to the door")   // 12.0 m
    /// Units.parse("5'11\"")                   // 71.0 in
    /// Units.parse("3 lb 4 oz")                // 52.0 oz
    /// ```
    public static func parse(_ text: String) -> Measurement<Dimension>? {
        parseAll(text).first
    }
    
    /// Every measurement in a string, left to right.
    ///
    /// Adjacent quantities of the same dimension are summed rather than
    /// returned separately — "5 ft 11 in" and "3 lb 4 oz" are one measurement
    /// each, which is how they are meant, not two.
    public static func parseAll(_ text: String) -> [Measurement<Dimension>] {
        let matches = Lexer.matches(in: text)
        guard matches.isEmpty == false else { return [] }
        
        var results: [Measurement<Dimension>] = []
        var pending: Measurement<Dimension>?
        var pendingEnd: String.Index?
        
        for (index, (match, entry)) in matches.enumerated() {
            var measurement = Measurement(value: match.value, unit: entry.unit)

            // "5 ft 11" and "6 foot 2": a bare number after feet is inches,
            // which is how a height is said aloud and how it is usually typed.
            // Only a number nothing else claimed — "5 ft 11 in" is already two
            // matches and sums on its own below.
            if entry.unit == UnitLength.feet {
                let nextStart = index + 1 < matches.count ? matches[index + 1].0.range.lowerBound : text.endIndex
                if let inches = bareInches(in: text[match.range.upperBound..<nextStart]) {
                    measurement = Measurement(value: match.value * 12 + inches, unit: UnitLength.inches)
                }
            }
            
            if let current = pending,
               let end = pendingEnd,
               current.unit.superclassIsSame(as: entry.unit),
               isAdjacent(text, from: end, to: match.range.lowerBound) {
                // Same dimension, nothing but space between them — one value.
                let combined = current.converted(to: entry.unit).value + measurement.value
                pending = Measurement(value: combined, unit: entry.unit)
            } else {
                if let current = pending { results.append(current) }
                pending = measurement
            }
            pendingEnd = match.range.upperBound
        }
        if let current = pending { results.append(current) }
        return results
    }
    
    /// A bare one- or two-digit number under twelve, and nothing that would
    /// make it something else: not "11.5", not "11am", not "110".
    private static func bareInches(in slice: Substring) -> Double? {
        let trimmed = slice.drop(while: \.isWhitespace)
        let digits = trimmed.prefix(while: \.isNumber)
        guard !digits.isEmpty, digits.count <= 2, let value = Double(digits), value < 12 else { return nil }
        if let next = trimmed.dropFirst(digits.count).first, next.isLetter || next.isNumber || ".,:".contains(next) {
            return nil
        }
        return value
    }

    /// Compound quantities are written with nothing but whitespace between the
    /// parts. A comma or a word means they are separate values.
    private static func isAdjacent(_ text: String, from: String.Index, to: String.Index) -> Bool {
        guard from <= to else { return false }
        return text[from..<to].allSatisfy(\.isWhitespace)
    }
    
    // MARK: - Converting
    
    /// Convert a written quantity into a named unit.
    ///
    /// ```swift
    /// try Units.convert("12 m", to: "ft")     // 39.37 ft
    /// try Units.convert("100 f", to: "c")     // 37.78 °C
    /// ```
    public static func convert(_ text: String, to unitName: String) throws -> Measurement<Dimension> {
        guard let source = parse(text) else { throw UnitsError.noMeasurementFound }
        guard let target = unit(named: unitName) else { throw UnitsError.unknownUnit(unitName) }
        guard source.unit.superclassIsSame(as: target) else {
            throw UnitsError.incompatibleDimensions(from: source.unit.symbol, to: target.symbol)
        }
        return source.converted(to: target)
    }
    
    /// Look up a unit by any of its spellings.
    public static func unit(named name: String) -> Dimension? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let lowered = trimmed.lowercased()
        for table in UnitTable.all {
            for entry in table {
                let spellings = entry.caseSensitive ? entry.spellings : entry.spellings.map { $0.lowercased() }
                let needle = entry.caseSensitive ? trimmed : lowered
                if spellings.contains(needle) { return entry.unit }
            }
        }
        return nil
    }
    
    // MARK: - Suggesting
    
    /// The unit someone most likely wants this converted into.
    ///
    /// Built for the "select a quantity, see it in your own terms" case, so the
    /// answer depends on the reader's locale rather than the writer's.
    ///
    /// Three systems, not two. Foundation distinguishes `.uk` from `.metric`
    /// and `.us` because Britain genuinely is mixed — road distances in miles,
    /// shopping in kilograms, weather in Celsius, beer in pints. Treating it as
    /// either pure system gets half the answers wrong.
    public static func counterpart(
        for measurement: Measurement<Dimension>,
        locale: Locale = .current
    ) -> Dimension? {
        let system = locale.measurementSystem
        
        switch measurement.unit {
        case is UnitLength:
            // Below a millimetre there is nothing everyday to convert into:
            // "5 nm" in inches is 0.0000002, which rounds to "0 in" and looks
            // like a bug rather than an answer.
            let metres = measurement.converted(to: UnitLength.meters).value
            guard metres >= 0.001 else { return nil }
            let long = metres >= 1000
            switch system {
            case .us: return long ? UnitLength.miles : UnitLength.feet
            // Long distances in miles, everything shorter in metres — which is
            // how road signs and everyday speech actually divide in the UK.
            case .uk: return long ? UnitLength.miles : UnitLength.meters
            default: return long ? UnitLength.kilometers : UnitLength.meters
            }
        case is UnitMass:
            // Same for anything under a gram — "500 mg" of a vitamin is not
            // usefully 0.02 oz.
            let grams = measurement.converted(to: UnitMass.grams).value
            guard grams >= 1 else { return nil }
            let heavy = grams >= 1000
            if system == .us { return heavy ? UnitMass.pounds : UnitMass.ounces }
            return heavy ? UnitMass.kilograms : UnitMass.grams
        case is UnitTemperature:
            return system == .us ? UnitTemperature.fahrenheit : UnitTemperature.celsius
        case is UnitVolume:
            // Scaled, like length and mass. A flat answer of gallons turns
            // "2 cups" into "0.13 gal", which is nobody's idea of a helpful
            // conversion — small volumes are poured, not filled.
            let litres = measurement.converted(to: UnitVolume.liters).value
            guard litres >= 0.001 else { return nil }
            let large = litres >= 1
            if system == .us {
                return large ? UnitVolume.gallons : UnitVolume.fluidOunces
            }
            return large ? UnitVolume.liters : UnitVolume.milliliters
        case is UnitSpeed:
            // Both the US and the UK post speed limits in mph.
            return system == .metric ? UnitSpeed.kilometersPerHour : UnitSpeed.milesPerHour
        case is UnitArea:
            // Land is measured in different units from rooms, in every system.
            let land = measurement.converted(to: UnitArea.squareMeters).value >= 4046.86
            if system == .us {
                return land ? UnitArea.acres : UnitArea.squareFeet
            }
            // The UK sells land in acres and always has, whatever the maps say.
            if system == .uk {
                return land ? UnitArea.acres : UnitArea.squareMeters
            }
            return land ? UnitArea.hectares : UnitArea.squareMeters
        default:
            return nil
        }
    }
    
    /// Parse, then convert to whatever the reader's locale would rather see.
    ///
    /// Returns nil when there is nothing to say — no measurement, or it is
    /// already in the reader's own units.
    public static func localised(
        _ text: String,
        locale: Locale = .current
    ) -> (source: Measurement<Dimension>, converted: Measurement<Dimension>)? {
        guard let source = parse(text),
              let target = counterpart(for: source, locale: locale),
              target != source.unit
        else { return nil }
        return (source, source.converted(to: target))
    }
}

// MARK: - Dimension comparison

extension Dimension {
    /// Whether two units measure the same kind of thing.
    ///
    /// `Measurement.converted(to:)` traps at runtime on a mismatch rather than
    /// throwing, so this has to be checked before every conversion.
    ///
    /// Compares base units rather than types, because `type(of:)` is a trap
    /// here: Foundation's static units are a private subclass — `UnitLength.inches`
    /// is `_NSStatic_NSUnitLength` — while anything built with
    /// `UnitLength(symbol:converter:)` is plain `NSUnitLength`. Comparing types
    /// reports those as incompatible even though they convert perfectly, which
    /// broke every CSS unit against every physical one.
    func superclassIsSame(as other: Dimension) -> Bool {
        type(of: self).baseUnit().symbol == type(of: other).baseUnit().symbol
    }
}
