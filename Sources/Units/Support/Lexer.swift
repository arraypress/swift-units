//
//  Lexer.swift
//  Units
//

import Foundation

/// Finds "a number followed by a unit" inside a string.
///
/// Deliberately not a general expression parser — the job is recognising a
/// quantity someone selected or typed, not evaluating arithmetic.
enum Lexer {
    
    struct Match {
        let value: Double
        /// The spelling as written, for echoing back in the result.
        let unitText: String
        /// Where it sat, so callers can highlight or replace in place.
        let range: Range<String.Index>
    }
    
    /// Longest-first so "mm" is never read as "m" plus a stray character, and
    /// "fl oz" beats "oz".
    private static let sortedSpellings: [(spelling: String, entry: UnitTable.Entry)] = {
        var all: [(String, UnitTable.Entry)] = []
        for table in UnitTable.all {
            for entry in table {
                for spelling in entry.spellings {
                    all.append((spelling, entry))
                }
            }
        }
        return all.sorted { $0.0.count > $1.0.count }
    }()
    
    /// Pull every quantity out of a string.
    static func matches(in text: String, locale: Locale = .current) -> [(Match, UnitTable.Entry)] {
        var results: [(Match, UnitTable.Entry)] = []
        
        // A number, then optional space, then whatever follows. The unit is
        // resolved from the tail rather than matched by regex, so a spelling
        // table stays the single source of truth.
        // The `[23]` is what makes "m2" and "ft3" reachable at all. Without it
        // the unit token stops dead at the first digit, and "50 m2" does not
        // fail — it silently reads as 50 metres, which is the worst way to be
        // wrong. Restricted to 2 and 3 because they are the only exponents in
        // the tables, and because anything greedier eats the inches in 5'11".
        let pattern = #"(-?\d+(?:[.,]\d+)*)\s*([^\d\s,;]+[23]?(?:\s+[a-z]+)?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }
        
        let ns = text as NSString
        for match in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            // A number sitting directly after a slash is the bottom of a rate,
            // not a quantity: the "100km" in "35 l/100km" is per-something, and
            // reporting it as a distance would invent a measurement nobody
            // wrote. Dates get the same protection — "9/11" is not 11 of
            // anything.
            let start = match.range(at: 1).location
            if start > 0, ns.character(at: start - 1) == unichar(UInt16(47)) { continue }

            let numberText = ns.substring(with: match.range(at: 1))
            guard let value = number(from: numberText, locale: locale) else { continue }
            let tail = ns.substring(with: match.range(at: 2))
            guard !isOrdinal(numberText, tail) else { continue }

            // Whether the unit sits hard against its number, as in "180c".
            let numberRange = match.range(at: 1)
            let attached = numberRange.location + numberRange.length == match.range(at: 2).location
            
            guard let (entry, matchedSpelling) = resolve(tail, attached: attached) else { continue }
            guard let range = Range(match.range, in: text) else { continue }
            results.append((Match(value: value, unitText: matchedSpelling, range: range), entry))
        }
        return results
    }
    
    /// Reads "1,500", "1,5", "1,234.56" and "1.234,56" the way the reader would.
    ///
    /// Every comma used to become a decimal point, which made "1,500 m" one
    /// and a half metres on a British Mac. A comma followed by exactly three
    /// digits is a thousands separator wherever the decimal separator is a
    /// dot, and only a decimal where it is a comma; one or two digits after a
    /// comma can only be a fraction; more than one group can only be
    /// thousands. When both separators appear, whichever comes last is the
    /// decimal point.
    static func number(from raw: String, locale: Locale) -> Double? {
        let text = raw.replacingOccurrences(of: " ", with: "")
        let hasComma = text.contains(","), hasDot = text.contains(".")

        if hasComma && hasDot {
            let commaLast = text.lastIndex(of: ",")! > text.lastIndex(of: ".")!
            let grouping = commaLast ? "." : ","
            return Double(text.replacingOccurrences(of: grouping, with: "").replacingOccurrences(of: ",", with: "."))
        }
        if hasComma {
            let groups = text.split(separator: ",", omittingEmptySubsequences: false)
            let groupsOfThree = groups.dropFirst().allSatisfy { $0.count == 3 }
            let commaIsDecimal = locale.decimalSeparator == ","
            if groupsOfThree && (groups.count > 2 || !commaIsDecimal) {
                return Double(text.replacingOccurrences(of: ",", with: ""))
            }
            return Double(text.replacingOccurrences(of: ",", with: "."))
        }
        if hasDot {
            let groups = text.split(separator: ".", omittingEmptySubsequences: false)
            if groups.count > 2, groups.dropFirst().allSatisfy({ $0.count == 3 }) {
                return Double(text.replacingOccurrences(of: ".", with: ""))
            }
        }
        return Double(text)
    }

    /// Whether "21st" is a date rather than 21 stone.
    ///
    /// `st` is stone, and an ordinal is written hard against its number, so
    /// "21st of March" parses as a weight without this. Only the *correct*
    /// suffix for the number counts, which is what keeps real weights: 1st,
    /// 21st and 31st are ordinals, while 5st, 11st and 14st are stone — and
    /// stone is exactly the unit people write attached like that.
    private static func isOrdinal(_ number: String, _ tail: String) -> Bool {
        guard let value = Int(number) else { return false }

        let suffix: String
        switch (abs(value) % 100, abs(value) % 10) {
        case (11...13, _): suffix = "th"
        case (_, 1):       suffix = "st"
        case (_, 2):       suffix = "nd"
        case (_, 3):       suffix = "rd"
        default:           suffix = "th"
        }

        let lowered = tail.lowercased()
        guard lowered.hasPrefix(suffix) else { return false }
        return lowered.dropFirst(suffix.count).first?.isLetter != true
    }
    
    /// Find the longest spelling that the tail starts with.
    ///
    /// Prefix rather than equality so "12kg." and "5 miles away" both resolve —
    /// people rarely select exactly the quantity and nothing else.
    private static func resolve(_ tail: String, attached: Bool) -> (UnitTable.Entry, String)? {
        let lowered = tail.lowercased()
        for (spelling, entry) in sortedSpellings {
            let haystack = entry.caseSensitive ? tail : lowered
            let needle = entry.caseSensitive ? spelling : spelling.lowercased()
            guard haystack == needle || haystack.hasPrefix(needle) else { continue }

            // A longer word that merely starts with a unit is not that unit:
            // "miles" is, "mileage" is not. A trailing "/" means a rate —
            // "l/100km" is fuel consumption, and answering 35 litres for it
            // would be confidently wrong — and a "-" means a compound: the
            // "t" in "5 t-shirts" is not five tonnes.
            let remainder = haystack.dropFirst(needle.count)
            if let next = remainder.first, next.isLetter || next == "/" || next == "-" { continue }

            // The word after the unit, when there is one.
            let following = remainder.first?.isWhitespace == true
                ? String(remainder.drop(while: \.isWhitespace).prefix(while: \.isLetter))
                : ""

            if !following.isEmpty {
                if wordsWhenFollowed.contains(needle) { continue }
                if needle == "in", !inchFollowers.contains(following) { continue }
            }

            // A bare "c" or "f" is a temperature when it is written like one —
            // "180c", "350F", "100 f" and nothing after — and a stray letter
            // when a lowercase one floats between the number and another
            // word: "pack of 6 c batteries", "grade 3 c average".
            if bareTemperatureLetters.contains(needle), !attached, !following.isEmpty,
               tail.first?.isUppercase != true { continue }

            return (entry, spelling)
        }
        return nil
    }

    /// Spellings that are ordinary English words, and mean the word rather
    /// than the unit whenever another word follows: "3 cup finals", "2 ton
    /// truck", "10 pt font", "12 kt gold", "3 t shirts", "5 ha ha", "3 bars
    /// of chocolate". Alone at the end — "weighs 2 ton", "2 pt" — they are
    /// still units.
    private static let wordsWhenFollowed: Set<String> = [
        "cup", "ton", "tons", "pt", "kt", "kts", "t", "ha", "bar", "bars", "yard",
    ]

    /// The one spelling ambiguous enough to need the opposite rule.
    ///
    /// "in" is the commonest preposition in the language — "5 in the morning",
    /// "the 3 in question" — so it is only inches when the next word says so
    /// ("12 in wide", "12 in x 8 in") or when nothing follows at all.
    private static let inchFollowers: Set<String> = [
        "wide", "long", "tall", "high", "deep", "thick", "diameter", "across",
        "x", "by", "screen", "display", "wheel", "wheels", "tyre", "tyres",
        "tire", "tires", "pipe", "bore", "barrel", "gauge", "square", "sq",
    ]

    private static let bareTemperatureLetters: Set<String> = ["c", "f"]
}
