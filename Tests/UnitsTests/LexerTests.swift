//
//  LexerTests.swift
//  Units
//
//  Created by David Sherlock on 2026.
//
//  This library had no tests and no consumers, which is how a silent
//  mis-parse survived in it: "30 miles per gallon" read as 30 MILES. Most of
//  what follows is the traps the source comments describe, pinned down so
//  they stay fixed.
//

import XCTest
@testable import Units

final class LexerTests: XCTestCase {

    private let uk = Locale(identifier: "en_GB")

    private func parsed(_ text: String) -> Measurement<Dimension>? {
        Units.parse(text, locale: uk)
    }

    private func symbol(_ text: String) -> String? {
        parsed(text)?.unit.symbol
    }

    // MARK: - The bug this suite was written for

    func testMultiWordSpellingsBeatTheirFirstWord() {
        // "miles per gallon" is fuel consumption. Reading it as "miles" is a
        // different dimension and a confidently wrong answer.
        XCTAssertEqual(symbol("30 miles per gallon"), "mpg")
        XCTAssertEqual(symbol("8 litres per 100km"), "L/100km")
        XCTAssertEqual(parsed("30 miles per gallon")?.value, 30)
    }

    func testSingleWordStillWins() {
        XCTAssertEqual(symbol("5 miles"), "mi")
        XCTAssertEqual(symbol("5 litres"), "L")
        XCTAssertEqual(symbol("30 mpg"), "mpg")
    }

    func testTrailingWordsDoNotChangeTheUnit() {
        XCTAssertEqual(symbol("5 miles away"), "mi")
        XCTAssertEqual(symbol("5 miles away from home"), "mi")
    }

    // MARK: - Fuel efficiency is INVERSE

    func testFuelEfficiencyConvertsInversely() throws {
        // 235.2 / 30 = 7.84. A linear conversion would give something else
        // entirely, and it is the classic way to get this dimension wrong.
        let converted = try Units.convert("30 mpg", to: "l/100km")
        XCTAssertEqual(converted.value, 7.84, accuracy: 0.01)

        let back = try Units.convert("8 l/100km", to: "mpg")
        XCTAssertEqual(back.value, 29.4, accuracy: 0.01)
    }

    // MARK: - Bytes: 1000 vs 1024

    func testBinaryAndDecimalBytesAreNotTheSame() throws {
        XCTAssertEqual(try Units.convert("1 GiB", to: "MB").value, 1073.741824, accuracy: 0.001)
        XCTAssertEqual(try Units.convert("1 GB", to: "MiB").value, 953.674, accuracy: 0.01)
        XCTAssertEqual(try Units.convert("1024 MiB", to: "GiB").value, 1, accuracy: 0.0001)
    }

    // MARK: - Traps the source comments describe

    func testThousandsSeparatorIsNotADecimalPoint() {
        // "1,500 m" was one and a half metres on a British Mac.
        XCTAssertEqual(parsed("1,500 m")?.value, 1500)
        XCTAssertEqual(parsed("1,5 m")?.value, 1.5, "one or two digits after a comma can only be a fraction")
    }

    func testExponentsAreNotSwallowed() {
        // "50 m2" silently read as 50 metres before the [23] was added.
        XCTAssertEqual(symbol("50 m2"), "m²")
        XCTAssertEqual(symbol("2 ft3"), "ft³")
    }

    func testARateIsNotItsNumerator() {
        // Answering "35 litres" for "35 l/100km" would invent a measurement.
        XCTAssertNotEqual(symbol("35 l/100km"), "L")
    }

    func testALongerWordIsNotTheUnitItStartsWith() {
        XCTAssertNil(parsed("5 mileage"), "mileage is not miles")
        XCTAssertNil(parsed("5 t-shirts"), "the t in t-shirts is not tonnes")
    }

    func testBareTemperatureLettersOnlyWhenWrittenLikeOne() {
        XCTAssertEqual(symbol("180c"), "°C")
        XCTAssertEqual(symbol("350F"), "°F")
        XCTAssertNil(parsed("pack of 6 c batteries"), "a stray letter is not a temperature")
    }

    func testOrdinalsAreNotQuantities() {
        XCTAssertNil(parsed("the 3rd"), "3rd is a position, not three of anything")
    }

    // MARK: - Dimensions are real

    func testConvertingAcrossDimensionsIsRefused() {
        XCTAssertThrowsError(try Units.convert("5 km", to: "grams"))
    }

    func testTheDimensionsTheTableClaims() {
        // One spelling from each family, so a table edit that drops a whole
        // dimension is caught.
        for (text, expected) in [
            ("90 degrees", "°"), ("2 acres", "ac"), ("2.5 GHz", "GHz"),
            ("1 bar", "bar"), ("100 km/h", "km/h"), ("1 kWh", "kWh"),
            ("5 A", "A"), ("1 cup", "cup"), ("30 minutes", "min"),
            ("1 GiB", "GiB"), ("5 kg", "kg"), ("100 W", "W"), ("20 °C", "°C"),
        ] {
            XCTAssertEqual(symbol(text), expected, "\(text) should be \(expected)")
        }
    }
}
