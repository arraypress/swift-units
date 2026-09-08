//
//  UnitsError.swift
//  Units
//

import Foundation

public enum UnitsError: Error, Equatable, Sendable {
    /// Nothing in the string looked like a quantity.
    case noMeasurementFound
    /// The unit was recognised but the target is a different dimension —
    /// metres cannot become kilograms.
    case incompatibleDimensions(from: String, to: String)
    /// The target unit was not recognised.
    case unknownUnit(String)
}

extension UnitsError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noMeasurementFound:
            return "No measurement found in the text."
        case let .incompatibleDimensions(from, to):
            return "Cannot convert \(from) to \(to) — different dimensions."
        case let .unknownUnit(unit):
            return "Unrecognised unit \"\(unit)\"."
        }
    }
}
