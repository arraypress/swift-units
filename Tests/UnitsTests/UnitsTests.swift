//
//  UnitsTests.swift
//  Units
//

import Testing
import Foundation
@testable import Units

@Suite("Parsing")
struct ParsingTests {
    
    @Test("Reads a plain quantity", arguments: [
        ("12 m", 12.0), ("12m", 12.0), ("12 metres", 12.0), ("12 meters", 12.0),
    ])
    func plainQuantity(_ input: String, _ expected: Double) {
        let parsed = Units.parse(input)
        #expect(parsed?.value == expected)
        #expect(parsed?.unit == UnitLength.meters)
    }
    
    @Test("Distinguishes units that share a prefix")
    func prefixes() {
        #expect(Units.parse("5 mm")?.unit == UnitLength.millimeters)
        #expect(Units.parse("5 m")?.unit == UnitLength.meters)
        #expect(Units.parse("5 mi")?.unit == UnitLength.miles)
        #expect(Units.parse("5 min")?.unit == UnitDuration.minutes)
        #expect(Units.parse("5 ms")?.unit == UnitDuration.milliseconds)
    }
    
    @Test("Does not claim a longer word that merely starts with a unit")
    func notAWord() {
        #expect(Units.parse("5 mileage") == nil)
        #expect(Units.parse("3 minding") == nil)
    }
    
    @Test("Finds a quantity inside a sentence")
    func inSentence() {
        let parsed = Units.parse("it is about 12 m to the door")
        #expect(parsed?.value == 12.0)
        #expect(parsed?.unit == UnitLength.meters)
    }
    
    @Test("Sums adjacent parts of a compound quantity")
    func compound() {
        // 3 lb 4 oz == 52 oz
        let parsed = Units.parse("3 lb 4 oz")
        #expect(parsed?.converted(to: UnitMass.ounces).value == 52.0)
    }
    
    @Test("Keeps separated quantities apart")
    func separated() {
        let all = Units.parseAll("2 kg, 3 kg")
        #expect(all.count == 2)
    }
    
    @Test("Handles decimals written either way")
    func decimals() {
        #expect(Units.parse("1.5 kg")?.value == 1.5)
        #expect(Units.parse("1,5 kg")?.value == 1.5)
    }
}

@Suite("Converting")
struct ConvertingTests {
    
    @Test("Converts across systems")
    func across() throws {
        let converted = try Units.convert("12 m", to: "ft")
        #expect(abs(converted.value - 39.3701) < 0.001)
    }
    
    @Test("Converts temperature, which is not a simple ratio")
    func temperature() throws {
        let converted = try Units.convert("100 f", to: "c")
        #expect(abs(converted.value - 37.7778) < 0.001)
    }
    
    @Test("Refuses incompatible dimensions instead of trapping")
    func incompatible() {
        #expect(throws: UnitsError.self) {
            try Units.convert("12 m", to: "kg")
        }
    }
    
    @Test("Reports an unknown target unit")
    func unknown() {
        #expect(throws: UnitsError.self) {
            try Units.convert("12 m", to: "bananas")
        }
    }
}

@Suite("Localising")
struct LocalisingTests {
    
    @Test("Offers imperial to a US reader")
    func toImperial() throws {
        let result = try #require(Units.localised("12 m", locale: Locale(identifier: "en_US")))
        #expect(result.converted.unit == UnitLength.feet)
    }
    
    @Test("Offers metric to a UK reader")
    func toMetric() throws {
        let result = try #require(Units.localised("12 ft", locale: Locale(identifier: "en_GB")))
        #expect(result.converted.unit == UnitLength.meters)
    }
    
    @Test("Says nothing when it is already in the reader's units")
    func alreadyLocal() {
        #expect(Units.localised("12 m", locale: Locale(identifier: "en_GB")) == nil)
    }
    
    @Test("Picks the sensible scale for the size")
    func scale() throws {
        let long = try #require(Units.localised("5000 m", locale: Locale(identifier: "en_US")))
        #expect(long.converted.unit == UnitLength.miles)
        let short = try #require(Units.localised("2 m", locale: Locale(identifier: "en_US")))
        #expect(short.converted.unit == UnitLength.feet)
    }
}

@Suite("CSS units")
struct CSSTests {
    
    @Test("Converts px to rem at the default base font size")
    func pxToRem() throws {
        let converted = try Units.convertCSS("24 px", to: "rem")
        #expect(abs(converted.value - 1.5) < 0.0001)
    }
    
    @Test("Converts rem back to px")
    func remToPx() throws {
        let converted = try Units.convertCSS("1.5 rem", to: "px")
        #expect(abs(converted.value - 24) < 0.0001)
    }
    
    @Test("Points are 1/72 inch, so 12pt is 16px at 96ppi")
    func points() throws {
        let converted = try Units.convertCSS("12 pt", to: "px")
        #expect(abs(converted.value - 16) < 0.0001)
    }
    
    @Test("Honours a non-default base font size")
    func customBase() throws {
        let config = Units.CSSConfiguration(baseFontSize: 20, pixelDensity: 96)
        let converted = try Units.convertCSS("40 px", to: "rem", configuration: config)
        #expect(abs(converted.value - 2.0) < 0.0001)
    }
    
    @Test("Honours a non-default pixel density")
    func customDensity() throws {
        let config = Units.CSSConfiguration(baseFontSize: 16, pixelDensity: 72)
        // At 72ppi a pixel is a point, so 12px == 12pt.
        let converted = try Units.convertCSS("12 px", to: "pt", configuration: config)
        #expect(abs(converted.value - 12) < 0.0001)
    }
    
    @Test("rem is not read as r + em")
    func remNotEm() throws {
        let parsed = try #require(Units.parseCSS("2 rem"))
        #expect(parsed.unit.symbol == "rem")
    }
    
    @Test("CSS lengths convert to physical ones")
    func toPhysical() throws {
        // 96 px at 96 ppi is exactly one inch.
        let converted = try Units.convertCSS("96 px", to: "in")
        #expect(abs(converted.value - 1.0) < 0.0001)
    }
}

@Suite("Ordinals are not units")
struct OrdinalTests {

    @Test("A date is not a weight")
    func datesDoNotParse() {
        #expect(Units.parse("21st") == nil)
        #expect(Units.parse("21st of March") == nil)
        #expect(Units.parse("1st") == nil)
        #expect(Units.parse("31st") == nil)
    }

    @Test("A weight in stone still parses")
    func stoneStillParses() throws {
        // The suffix has to be the right one for the number. "5th" is the
        // ordinal for 5, so "5st" can only be stone.
        let light = try #require(Units.parse("5st"))
        #expect(light.unit == UnitMass.stones)
        #expect(light.value == 5)

        // 11, 12 and 13 all take "th", which is what makes them unambiguous.
        #expect(Units.parse("11st")?.unit == UnitMass.stones)
        #expect(Units.parse("14 st")?.unit == UnitMass.stones)
        #expect(Units.parse("21 stone")?.unit == UnitMass.stones)
    }

    @Test("Other ordinals were never units, and still aren't")
    func otherOrdinals() {
        #expect(Units.parse("2nd") == nil)
        #expect(Units.parse("3rd") == nil)
        #expect(Units.parse("4th") == nil)
        #expect(Units.parse("12th") == nil)
    }
}
