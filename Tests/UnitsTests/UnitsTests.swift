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

@Suite("Scale of the answer")
struct ScaleTests {

    private let us = Locale(identifier: "en_US")
    private let uk = Locale(identifier: "en_GB")
    private let metric = Locale(identifier: "de_DE")

    @Test("A small volume is not answered in gallons")
    func smallVolumes() throws {
        // The bug this suite exists for: 2 cups came back as 0.13 gal.
        let (_, american) = try #require(Units.localised("2 cups", locale: us))
        #expect(american.unit == UnitVolume.fluidOunces)
        #expect(abs(american.value - 16) < 0.5)

        let (_, european) = try #require(Units.localised("2 cups", locale: metric))
        #expect(european.unit == UnitVolume.milliliters)
        // Foundation's cup is the 240 mL metric cup, not 236.588 mL.
        #expect(abs(european.value - 480) < 1)
    }

    @Test("A large volume still is")
    func largeVolumes() throws {
        #expect(Units.localised("20 litres", locale: us)?.converted.unit == UnitVolume.gallons)
        #expect(Units.localised("5 gallons", locale: metric)?.converted.unit == UnitVolume.liters)
    }

    @Test("Land and rooms take different units")
    func areas() throws {
        #expect(Units.localised("50 m2", locale: us)?.converted.unit == UnitArea.squareFeet)
        #expect(Units.localised("2 hectares", locale: us)?.converted.unit == UnitArea.acres)
        #expect(Units.localised("5 acres", locale: metric)?.converted.unit == UnitArea.hectares)
        // Britain buys land in acres however metric the rest of the shop is.
        #expect(Units.localised("2 hectares", locale: uk)?.converted.unit == UnitArea.acres)
    }
}

@Suite("Units written with an exponent")
struct ExponentTests {

    @Test("Square and cubic spellings resolve")
    func exponents() throws {
        // Before the lexer allowed a trailing 2, "50 m2" did not fail — it
        // came back as 50 metres. Silently wrong beats loudly wrong nowhere.
        #expect(Units.parse("50 m2")?.unit == UnitArea.squareMeters)
        #expect(Units.parse("50 m²")?.unit == UnitArea.squareMeters)
        #expect(Units.parse("3 ft2")?.unit == UnitArea.squareFeet)
        #expect(Units.parse("5 m3")?.unit == UnitVolume.cubicMeters)
        #expect(Units.parse("2 km2")?.unit == UnitArea.squareKilometers)
    }

    @Test("Feet and inches still split")
    func feetAndInchesSurvive() throws {
        // The exponent has to be exactly one digit, or this becomes 5 feet
        // and the 11 inches are swallowed by the unit token.
        let height = try #require(Units.parse("5'11\""))
        #expect(height.converted(to: UnitLength.inches).value == 71)
    }

    @Test("A rate is not its first unit")
    func ratesAreNotGuessed() {
        #expect(Units.parse("35 l/100km") == nil)
        // But a speed whose whole spelling is known still reads.
        #expect(Units.parse("100 km/h")?.unit == UnitSpeed.kilometersPerHour)
    }
}

@Suite("Data rate")
struct DataRateTests {

    @Test("Bits and bytes are told apart by the spelling")
    func bitsVersusBytes() throws {
        // The eight-fold difference everybody trips over. The suffix carries
        // it: "bps" is how a line is sold, "B/s" is how a transfer is reported.
        #expect(Units.parse("100 Mbps")?.unit == UnitDataRate.megabitsPerSecond)
        #expect(Units.parse("100 mbps")?.unit == UnitDataRate.megabitsPerSecond)
        #expect(Units.parse("100 MB/s")?.unit == UnitDataRate.megabytesPerSecond)
        #expect(Units.parse("100 Mb/s")?.unit == UnitDataRate.megabitsPerSecond)
    }

    @Test("A 100 Mbps line downloads at 12.5 MB/s")
    func theComplaint() throws {
        let speed = try #require(Units.dataRate("100 Mbps", as: .megabytesPerSecond))
        #expect(abs(speed.value - 12.5) < 0.001)

        let back = try #require(Units.dataRate("12.5 MB/s", as: .megabitsPerSecond))
        #expect(abs(back.value - 100) < 0.001)
    }

    @Test("Decimal, not binary")
    func decimalPrefixes() throws {
        // 1 Mbps is exactly 1,000 kbps. Storage is the opposite, which is why
        // the two are separate dimensions.
        let rate = try #require(Units.dataRate("1 Mbps", as: .kilobitsPerSecond))
        #expect(rate.value == 1_000)

        let storage = try #require(Units.parse("1 MiB"))
        #expect(storage.converted(to: UnitInformationStorage.kibibytes).value == 1_024)
    }

    @Test("Storage units are not shadowed by rate units")
    func storageStillWorks() {
        // "MB/s" is four characters and "MB" is two, so longest-first has to
        // pick the rate for one and the size for the other.
        #expect(Units.parse("500 MB")?.unit == UnitInformationStorage.megabytes)
        #expect(Units.parse("500 MB/s")?.unit == UnitDataRate.megabytesPerSecond)
    }

    @Test("A rate is not confused with a dimension it cannot convert to")
    func incompatible() {
        #expect(throws: (any Error).self) { try Units.convert("100 Mbps", to: "MB") }
    }
}
