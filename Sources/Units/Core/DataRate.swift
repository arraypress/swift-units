//
//  DataRate.swift
//  Units
//

import Foundation

/// Speed of data, which Foundation has no dimension for.
///
/// Foundation ships `UnitInformationStorage` for how much data there is, and
/// nothing at all for how fast it moves — so this is a real `Dimension`
/// subclass rather than a lookup table, and everything else in this library
/// works on it unchanged.
///
/// Decimal, not binary: a 100 Mbps line carries 100,000,000 bits per second,
/// not 104,857,600. Storage is the opposite — a kibibyte really is 1,024 bytes
/// — which is why the two live in separate dimensions and why 1 Mbps is
/// exactly 1,000 kbps here while 1 MiB is 1,024 KiB over there.
public final class UnitDataRate: Dimension, @unchecked Sendable {

    // MARK: - Bits, as networks are sold

    public static let bitsPerSecond = UnitDataRate(symbol: "bps", coefficient: 1)
    public static let kilobitsPerSecond = UnitDataRate(symbol: "kbps", coefficient: 1_000)
    public static let megabitsPerSecond = UnitDataRate(symbol: "Mbps", coefficient: 1_000_000)
    public static let gigabitsPerSecond = UnitDataRate(symbol: "Gbps", coefficient: 1_000_000_000)
    public static let terabitsPerSecond = UnitDataRate(symbol: "Tbps", coefficient: 1_000_000_000_000)

    // MARK: - Bytes, as transfers are reported

    public static let bytesPerSecond = UnitDataRate(symbol: "B/s", coefficient: 8)
    public static let kilobytesPerSecond = UnitDataRate(symbol: "KB/s", coefficient: 8_000)
    public static let megabytesPerSecond = UnitDataRate(symbol: "MB/s", coefficient: 8_000_000)
    public static let gigabytesPerSecond = UnitDataRate(symbol: "GB/s", coefficient: 8_000_000_000)

    private convenience init(symbol: String, coefficient: Double) {
        self.init(symbol: symbol, converter: UnitConverterLinear(coefficient: coefficient))
    }

    /// Bits per second, because that is the unit the number on the contract is in.
    public override class func baseUnit() -> UnitDataRate { bitsPerSecond }
}

public extension Units {

    /// The eight-fold difference everybody trips over, in one call.
    ///
    /// ```swift
    /// Units.dataRate("100 Mbps", as: .megabytesPerSecond)   // 12.5 MB/s
    /// ```
    ///
    /// A 100 Mbps connection downloads at 12.5 MB/s, and the gap between those
    /// two numbers is the most common "my internet is slower than advertised"
    /// complaint there is. Both are the same speed.
    static func dataRate(_ text: String, as target: UnitDataRate) -> Measurement<UnitDataRate>? {
        guard let parsed = parse(text), let unit = parsed.unit as? UnitDataRate else { return nil }
        return Measurement(value: parsed.value, unit: unit).converted(to: target)
    }
}
