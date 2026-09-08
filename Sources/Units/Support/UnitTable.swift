//
//  UnitTable.swift
//  Units
//

import Foundation

/// Every unit this library recognises, keyed by the spellings people write.
///
/// Foundation already converts — `Measurement.converted(to:)` is one line. The
/// work is knowing that "12 m", "12m", "12 metres" and "12 meters" are the same
/// thing, and that "m" means metres here while "min" means minutes.
///
/// Entries are ordered longest-symbol-first when matching, so "mm" is never
/// read as "m" followed by a stray character.
enum UnitTable {
    
    /// A recognised unit: the Foundation dimension, and every way it is written.
    struct Entry {
        let unit: Dimension
        /// Lowercased spellings. Plurals are listed explicitly rather than
        /// stripped, because "feet" is not "foots" and "inches" is not "inchs".
        let spellings: [String]
        /// Symbols are case-sensitive where it matters — "M" is not "m", and
        /// "K" is kelvin while "k" is not.
        let caseSensitive: Bool
        
        init(_ unit: Dimension, _ spellings: [String], caseSensitive: Bool = false) {
            self.unit = unit
            self.spellings = spellings
            self.caseSensitive = caseSensitive
        }
    }
    
    // MARK: - Length
    
    static let length: [Entry] = [
        .init(UnitLength.nanometers, ["nm", "nanometre", "nanometres", "nanometer", "nanometers"]),
        .init(UnitLength.micrometers, ["µm", "um", "micrometre", "micrometres", "micrometer", "micrometers", "micron", "microns"]),
        .init(UnitLength.millimeters, ["mm", "millimetre", "millimetres", "millimeter", "millimeters"]),
        .init(UnitLength.centimeters, ["cm", "centimetre", "centimetres", "centimeter", "centimeters"]),
        .init(UnitLength.decimeters, ["dm", "decimetre", "decimetres", "decimeter", "decimeters"]),
        .init(UnitLength.meters, ["m", "metre", "metres", "meter", "meters"]),
        .init(UnitLength.kilometers, ["km", "kilometre", "kilometres", "kilometer", "kilometers", "kms"]),
        .init(UnitLength.inches, ["in", "\"", "inch", "inches"]),
        .init(UnitLength.feet, ["ft", "'", "foot", "feet"]),
        .init(UnitLength.yards, ["yd", "yds", "yard", "yards"]),
        .init(UnitLength.miles, ["mi", "mile", "miles"]),
        .init(UnitLength.scandinavianMiles, ["mil"]),
        .init(UnitLength.nauticalMiles, ["nmi", "nautical mile", "nautical miles"]),
        .init(UnitLength.fathoms, ["fathom", "fathoms"]),
        .init(UnitLength.furlongs, ["furlong", "furlongs"]),
        .init(UnitLength.astronomicalUnits, ["au", "astronomical unit", "astronomical units"]),
        .init(UnitLength.lightyears, ["ly", "lightyear", "lightyears", "light year", "light years"]),
        .init(UnitLength.parsecs, ["pc", "parsec", "parsecs"]),
    ]
    
    // MARK: - Mass
    
    static let mass: [Entry] = [
        .init(UnitMass.micrograms, ["µg", "ug", "microgram", "micrograms"]),
        .init(UnitMass.milligrams, ["mg", "milligram", "milligrams"]),
        .init(UnitMass.grams, ["g", "gram", "grams", "gramme", "grammes"]),
        .init(UnitMass.kilograms, ["kg", "kilo", "kilos", "kilogram", "kilograms", "kilogramme", "kilogrammes"]),
        .init(UnitMass.metricTons, ["t", "tonne", "tonnes", "metric ton", "metric tons"]),
        .init(UnitMass.shortTons, ["ton", "tons", "short ton", "short tons"]),
        .init(UnitMass.ounces, ["oz", "ounce", "ounces"]),
        .init(UnitMass.pounds, ["lb", "lbs", "pound", "pounds"]),
        .init(UnitMass.stones, ["st", "stone", "stones"]),
        .init(UnitMass.carats, ["ct", "carat", "carats"]),
        .init(UnitMass.slugs, ["slug", "slugs"]),
    ]
    
    // MARK: - Temperature
    
    static let temperature: [Entry] = [
        .init(UnitTemperature.celsius, ["°c", "c", "celsius", "centigrade"]),
        .init(UnitTemperature.fahrenheit, ["°f", "f", "fahrenheit"]),
        // "K" is kelvin; "k" is the prefix kilo. Listed the wrong way round,
        // "50 k" — fifty thousand of something, in anybody's writing — parsed
        // as fifty kelvin and answered −223 °C. The symbol is case-sensitive
        // because that distinction is the whole point; the word is not.
        .init(UnitTemperature.kelvin, ["K"], caseSensitive: true),
        .init(UnitTemperature.kelvin, ["kelvin", "kelvins"]),
    ]
    
    // MARK: - Volume
    
    static let volume: [Entry] = [
        .init(UnitVolume.milliliters, ["ml", "millilitre", "millilitres", "milliliter", "milliliters", "cc"]),
        .init(UnitVolume.centiliters, ["cl", "centilitre", "centilitres"]),
        .init(UnitVolume.deciliters, ["dl", "decilitre", "decilitres"]),
        .init(UnitVolume.liters, ["l", "litre", "litres", "liter", "liters"]),
        .init(UnitVolume.cubicMeters, ["m3", "m³", "cubic metre", "cubic metres"]),
        .init(UnitVolume.teaspoons, ["tsp", "teaspoon", "teaspoons"]),
        .init(UnitVolume.tablespoons, ["tbsp", "tablespoon", "tablespoons"]),
        .init(UnitVolume.fluidOunces, ["fl oz", "floz", "fluid ounce", "fluid ounces"]),
        .init(UnitVolume.cups, ["cup", "cups"]),
        .init(UnitVolume.pints, ["pt", "pint", "pints"]),
        .init(UnitVolume.quarts, ["qt", "quart", "quarts"]),
        .init(UnitVolume.gallons, ["gal", "gallon", "gallons"]),
        .init(UnitVolume.imperialPints, ["imperial pint", "imperial pints"]),
        .init(UnitVolume.imperialGallons, ["imperial gallon", "imperial gallons"]),
        .init(UnitVolume.bushels, ["bushel", "bushels"]),
    ]
    
    // MARK: - Duration
    
    static let duration: [Entry] = [
        .init(UnitDuration.nanoseconds, ["ns", "nanosecond", "nanoseconds"]),
        .init(UnitDuration.microseconds, ["µs", "us", "microsecond", "microseconds"]),
        .init(UnitDuration.milliseconds, ["ms", "millisecond", "milliseconds"]),
        .init(UnitDuration.seconds, ["s", "sec", "secs", "second", "seconds"]),
        .init(UnitDuration.minutes, ["min", "mins", "minute", "minutes"]),
        .init(UnitDuration.hours, ["h", "hr", "hrs", "hour", "hours"]),
    ]
    
    // MARK: - Speed
    
    static let speed: [Entry] = [
        .init(UnitSpeed.metersPerSecond, ["m/s", "mps", "metres per second"]),
        .init(UnitSpeed.kilometersPerHour, ["km/h", "kmh", "kph", "kilometres per hour"]),
        .init(UnitSpeed.milesPerHour, ["mph", "mi/h", "miles per hour"]),
        .init(UnitSpeed.knots, ["kn", "kt", "kts", "knot", "knots"]),
    ]
    
    // MARK: - Information storage
    
    static let storage: [Entry] = [
        .init(UnitInformationStorage.bytes, ["b", "byte", "bytes"]),
        .init(UnitInformationStorage.kilobytes, ["kb", "kilobyte", "kilobytes"]),
        .init(UnitInformationStorage.megabytes, ["mb", "megabyte", "megabytes"]),
        .init(UnitInformationStorage.gigabytes, ["gb", "gigabyte", "gigabytes"]),
        .init(UnitInformationStorage.terabytes, ["tb", "terabyte", "terabytes"]),
        .init(UnitInformationStorage.petabytes, ["pb", "petabyte", "petabytes"]),
        .init(UnitInformationStorage.kibibytes, ["kib", "kibibyte", "kibibytes"]),
        .init(UnitInformationStorage.mebibytes, ["mib", "mebibyte", "mebibytes"]),
        .init(UnitInformationStorage.gibibytes, ["gib", "gibibyte", "gibibytes"]),
        .init(UnitInformationStorage.tebibytes, ["tib", "tebibyte", "tebibytes"]),
        .init(UnitInformationStorage.bits, ["bit", "bits"]),
    ]
    
    // MARK: - Area
    
    static let area: [Entry] = [
        .init(UnitArea.squareMillimeters, ["mm2", "mm²", "square millimetre", "square millimetres"]),
        .init(UnitArea.squareCentimeters, ["cm2", "cm²", "square centimetre", "square centimetres"]),
        .init(UnitArea.squareMeters, ["m2", "m²", "sqm", "square metre", "square metres", "square meter", "square meters"]),
        .init(UnitArea.squareKilometers, ["km2", "km²", "square kilometre", "square kilometres"]),
        .init(UnitArea.squareInches, ["in2", "in²", "square inch", "square inches"]),
        .init(UnitArea.squareFeet, ["ft2", "ft²", "sqft", "sq ft", "square foot", "square feet"]),
        .init(UnitArea.squareYards, ["yd2", "yd²", "square yard", "square yards"]),
        .init(UnitArea.squareMiles, ["mi2", "mi²", "square mile", "square miles"]),
        .init(UnitArea.acres, ["acre", "acres"]),
        .init(UnitArea.hectares, ["ha", "hectare", "hectares"]),
    ]
    
    // MARK: - Everything
    
    /// Every table, in the order ambiguity is resolved.
    ///
    /// Length before mass matters: "st" is stones, but "s" alone is seconds and
    /// duration must not claim the "st" prefix first.
    static let all: [[Entry]] = [
        length, mass, temperature, volume, duration, speed, storage, area,
        power, energy, pressure, angle, frequency, electricCurrent, fuelEfficiency,
        dataRate,
    ]
    
    // MARK: - Data rate
    
    /// How fast data moves, which Foundation has no dimension for.
    ///
    /// The bits/bytes split is carried by the *spelling*, not by guesswork, and
    /// that convention is reliable: a "bps" suffix is bits, because that is how
    /// connections are sold, and a "B/s" suffix is bytes, because that is how
    /// transfers are reported. Case-sensitive for exactly this reason — "MB/s"
    /// is eight times "Mb/s", and quietly picking one would be wrong half the
    /// time. Sloppy lowercase "mbps" resolves to megabits, which is what the
    /// person writing it about their broadband means.
    static let dataRate: [Entry] = [
        .init(UnitDataRate.bitsPerSecond, ["bps", "bit/s", "bits per second"]),
        .init(UnitDataRate.kilobitsPerSecond, ["kbps", "kbit/s", "kb/s", "Kb/s"], caseSensitive: true),
        .init(UnitDataRate.megabitsPerSecond, ["mbps", "Mbps", "MBPS", "mbit/s", "Mbit/s", "mb/s", "Mb/s"], caseSensitive: true),
        .init(UnitDataRate.gigabitsPerSecond, ["gbps", "Gbps", "gbit/s", "Gbit/s", "gb/s", "Gb/s"], caseSensitive: true),
        .init(UnitDataRate.terabitsPerSecond, ["tbps", "Tbps"], caseSensitive: true),
        .init(UnitDataRate.bytesPerSecond, ["B/s", "bytes per second"], caseSensitive: true),
        .init(UnitDataRate.kilobytesPerSecond, ["KB/s", "kB/s"], caseSensitive: true),
        .init(UnitDataRate.megabytesPerSecond, ["MB/s"], caseSensitive: true),
        .init(UnitDataRate.gigabytesPerSecond, ["GB/s"], caseSensitive: true),
    ]
    
    // MARK: - The rest of Foundation's dimensions
    
    static let power: [Entry] = [
        .init(UnitPower.milliwatts, ["mw", "milliwatt", "milliwatts"]),
        .init(UnitPower.watts, ["w", "watt", "watts"]),
        .init(UnitPower.kilowatts, ["kw", "kilowatt", "kilowatts"]),
        .init(UnitPower.megawatts, ["mw", "megawatt", "megawatts"]),
        .init(UnitPower.horsepower, ["hp", "horsepower"]),
    ]
    
    static let energy: [Entry] = [
        .init(UnitEnergy.joules, ["j", "joule", "joules"]),
        .init(UnitEnergy.kilojoules, ["kj", "kilojoule", "kilojoules"]),
        .init(UnitEnergy.calories, ["cal", "calorie", "calories"]),
        .init(UnitEnergy.kilocalories, ["kcal", "kilocalorie", "kilocalories"]),
        .init(UnitEnergy.kilowattHours, ["kwh", "kilowatt hour", "kilowatt hours"]),
    ]
    
    static let pressure: [Entry] = [
        .init(UnitPressure.hectopascals, ["hpa", "hectopascal", "hectopascals"]),
        .init(UnitPressure.kilopascals, ["kpa", "kilopascal", "kilopascals"]),
        .init(UnitPressure.bars, ["bar", "bars"]),
        .init(UnitPressure.millibars, ["mbar", "millibar", "millibars"]),
        .init(UnitPressure.inchesOfMercury, ["inhg", "inches of mercury"]),
        .init(UnitPressure.millimetersOfMercury, ["mmhg", "millimetres of mercury"]),
        .init(UnitPressure.poundsForcePerSquareInch, ["psi"]),
    ]
    
    static let angle: [Entry] = [
        .init(UnitAngle.degrees, ["°", "deg", "degree", "degrees"]),
        .init(UnitAngle.radians, ["rad", "radian", "radians"]),
        .init(UnitAngle.gradians, ["grad", "gradian", "gradians"]),
    ]
    
    static let frequency: [Entry] = [
        .init(UnitFrequency.hertz, ["hz", "hertz"]),
        .init(UnitFrequency.kilohertz, ["khz", "kilohertz"]),
        .init(UnitFrequency.megahertz, ["mhz", "megahertz"]),
        .init(UnitFrequency.gigahertz, ["ghz", "gigahertz"]),
    ]
    
    static let electricCurrent: [Entry] = [
        .init(UnitElectricCurrent.milliamperes, ["ma", "milliamp", "milliamps", "milliampere", "milliamperes"]),
        .init(UnitElectricCurrent.amperes, ["a", "amp", "amps", "ampere", "amperes"]),
    ]
    
    static let fuelEfficiency: [Entry] = [
        .init(UnitFuelEfficiency.litersPer100Kilometers, ["l/100km", "litres per 100km"]),
        .init(UnitFuelEfficiency.milesPerGallon, ["mpg", "miles per gallon"]),
    ]
}
