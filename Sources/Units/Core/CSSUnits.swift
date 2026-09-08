//
//  CSSUnits.swift
//  Units
//

import Foundation

public extension Units {
    
    /// The two numbers every CSS length conversion depends on.
    ///
    /// `px` and `em` are not fixed physical lengths — a pixel is a fraction of
    /// an inch at some assumed density, and an em is however many pixels the
    /// base font size says. Both are configurable because both are project
    /// decisions, and a library that hardcoded them would be wrong half the time.
    struct CSSConfiguration: Sendable, Equatable {
        /// Pixels represented by 1 em. The CSS default, and every browser's.
        public var baseFontSize: Double
        /// Pixels in one inch. 96 is the CSS reference pixel, not the density
        /// of any real screen — that is deliberate and matches how browsers work.
        public var pixelDensity: Double
        
        public init(baseFontSize: Double = 16, pixelDensity: Double = 96) {
            self.baseFontSize = baseFontSize
            self.pixelDensity = pixelDensity
        }
        
        public static let standard = CSSConfiguration()
    }
    
    /// Configuration used when none is passed.
    nonisolated(unsafe) static var css: CSSConfiguration = .standard
}

// MARK: - CSS lengths as real UnitLength units

public extension UnitLength {
    
    /// One inch, in metres — the anchor every CSS length is defined against.
    private static let metresPerInch = 0.0254
    
    /// A CSS reference pixel: 1/96 inch by default.
    ///
    /// Expressed as a `UnitLength` rather than a separate dimension, so px
    /// converts to millimetres, feet or anything else for free.
    static func pixels(_ configuration: Units.CSSConfiguration = Units.css) -> UnitLength {
        UnitLength(
            symbol: "px",
            converter: UnitConverterLinear(coefficient: metresPerInch / configuration.pixelDensity)
        )
    }
    
    /// A typographic point: 1/72 inch. Fixed, unlike px and em.
    static let points = UnitLength(
        symbol: "pt",
        converter: UnitConverterLinear(coefficient: 0.0254 / 72)
    )
    
    /// A pica: 12 points.
    static let picas = UnitLength(
        symbol: "pc",
        converter: UnitConverterLinear(coefficient: 0.0254 / 6)
    )
    
    /// One em — the base font size, in pixels, converted to a real length.
    static func em(_ configuration: Units.CSSConfiguration = Units.css) -> UnitLength {
        UnitLength(
            symbol: "em",
            converter: UnitConverterLinear(
                coefficient: (metresPerInch / configuration.pixelDensity) * configuration.baseFontSize
            )
        )
    }
    
    /// One rem. Identical to em against the root font size, which is what the
    /// configured base font size represents.
    static func rem(_ configuration: Units.CSSConfiguration = Units.css) -> UnitLength {
        UnitLength(
            symbol: "rem",
            converter: UnitConverterLinear(
                coefficient: (metresPerInch / configuration.pixelDensity) * configuration.baseFontSize
            )
        )
    }
}

public extension Units {
    
    /// Convert between CSS lengths, honouring the configured base font size and
    /// pixel density.
    ///
    /// ```swift
    /// try Units.convertCSS("24 px", to: "rem")     // 1.5 rem
    /// try Units.convertCSS("1.5 rem", to: "px")    // 24 px
    /// try Units.convertCSS("12 pt", to: "px")      // 16 px
    /// ```
    static func convertCSS(
        _ text: String,
        to unitName: String,
        configuration: CSSConfiguration = Units.css
    ) throws -> Measurement<Dimension> {
        guard let source = parseCSS(text, configuration: configuration) else {
            throw UnitsError.noMeasurementFound
        }
        guard let target = cssUnit(named: unitName, configuration: configuration)
                ?? unit(named: unitName) else {
            throw UnitsError.unknownUnit(unitName)
        }
        guard source.unit.superclassIsSame(as: target) else {
            throw UnitsError.incompatibleDimensions(from: source.unit.symbol, to: target.symbol)
        }
        return source.converted(to: target)
    }
    
    /// Parse a CSS length. Falls back to the ordinary table, so "2 cm" works
    /// here too — cm and mm are valid CSS units as well.
    static func parseCSS(
        _ text: String,
        configuration: CSSConfiguration = Units.css
    ) -> Measurement<Dimension>? {
        let pattern = #"(-?\d+(?:\.\d+)?)\s*(px|rem|em|pt|pc)\b"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            let ns = text as NSString
            if let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
               let value = Double(ns.substring(with: match.range(at: 1))),
               let unit = cssUnit(named: ns.substring(with: match.range(at: 2)), configuration: configuration) {
                return Measurement(value: value, unit: unit)
            }
        }
        return parse(text)
    }
    
    /// Resolve a CSS unit name. `rem` is checked before `em` so it is not read
    /// as an "r" followed by em.
    static func cssUnit(
        named name: String,
        configuration: CSSConfiguration = Units.css
    ) -> Dimension? {
        switch name.trimmingCharacters(in: .whitespaces).lowercased() {
        case "px": return UnitLength.pixels(configuration)
        case "rem": return UnitLength.rem(configuration)
        case "em": return UnitLength.em(configuration)
        case "pt": return UnitLength.points
        case "pc": return UnitLength.picas
        default: return nil
        }
    }
}
