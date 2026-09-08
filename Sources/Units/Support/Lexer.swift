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
    static func matches(in text: String) -> [(Match, UnitTable.Entry)] {
        var results: [(Match, UnitTable.Entry)] = []
        
        // A number, then optional space, then whatever follows. The unit is
        // resolved from the tail rather than matched by regex, so a spelling
        // table stays the single source of truth.
        let pattern = #"(-?\d+(?:[.,]\d+)?)\s*([^\d\s,;]+(?:\s+[a-z]+)?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }
        
        let ns = text as NSString
        for match in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            let numberText = ns.substring(with: match.range(at: 1)).replacingOccurrences(of: ",", with: ".")
            guard let value = Double(numberText) else { continue }
            let tail = ns.substring(with: match.range(at: 2))
            guard !isOrdinal(numberText, tail) else { continue }
            
            guard let (entry, matchedSpelling) = resolve(tail) else { continue }
            guard let range = Range(match.range, in: text) else { continue }
            results.append((Match(value: value, unitText: matchedSpelling, range: range), entry))
        }
        return results
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
    private static func resolve(_ tail: String) -> (UnitTable.Entry, String)? {
        let lowered = tail.lowercased()
        for (spelling, entry) in sortedSpellings {
            let haystack = entry.caseSensitive ? tail : lowered
            let needle = entry.caseSensitive ? spelling : spelling.lowercased()
            if haystack == needle || haystack.hasPrefix(needle) {
                // A longer word that merely starts with a unit is not that unit:
                // "miles" is, "mileage" is not.
                let remainder = haystack.dropFirst(needle.count)
                if let next = remainder.first, next.isLetter { continue }
                return (entry, spelling)
            }
        }
        return nil
    }
}
