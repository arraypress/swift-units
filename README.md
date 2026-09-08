# swift-units

Measurements as plain values — parse what someone wrote, convert it, print it.

Foundation already converts. `Measurement.converted(to:)` is one line, and it
covers every dimension Apple ships. What it has no answer for is the *string*:
nothing in Foundation turns `"12 m"` into a `Measurement`.

That is what this is.

```swift
import Units

Units.parse("about 12 m to the door")     // 12.0 m
Units.parse("5'11\"")                      // 71.0 in
Units.parse("3 lb 4 oz")                   // 52.0 oz

try Units.convert("12 m", to: "ft")        // 39.37 ft
try Units.convert("100 f", to: "c")        // 37.78 °C
```

## Show it in the reader's own terms

The case this was built for: someone selects a quantity written in units they
do not think in, and wants it in units they do.

```swift
if let (source, converted) = Units.localised("12 m") {
    source.summary(with: converted)         // "12 m ≈ 39.37 ft" in the US
}
```

`localised` returns `nil` when there is nothing to say — no measurement, or it
is already in the reader's own system.

**Three measurement systems, not two.** Foundation distinguishes `.uk` from
`.metric` and `.us` because Britain genuinely is mixed: road distances in miles,
shopping in kilograms, weather in Celsius, beer in pints. Treating it as either
pure system gets half the answers wrong, so `.uk` is handled on its own terms.

## What it recognises

Every dimension Foundation defines: length, mass, temperature, volume, duration,
speed, information storage, area, power, energy, pressure, angle, frequency,
electric current and fuel efficiency.

Spellings are listed rather than derived, because plurals do not follow a rule —
"feet" is not "foots" and "inches" is not "inchs".

## The parsing rules that matter

**Longest match wins.** `mm` is never read as `m` followed by a stray
character, and `fl oz` beats `oz`.

**A longer word is not a unit.** `5 miles` parses; `5 mileage` does not.

**Prefixes, not equality.** `12kg.` and `5 miles away` both resolve — people
rarely select exactly the quantity and nothing else.

**Adjacent parts are one value.** `3 lb 4 oz` is 52 oz, not two measurements.
A comma or a word between them means they are separate: `2 kg, 3 kg` is two.

**Dimensions are checked before converting.** `Measurement.converted(to:)`
traps at runtime on a mismatch rather than throwing, so `convert` verifies first
and throws `UnitsError.incompatibleDimensions`.

**`≈`, not `=`.** Almost every cross-system conversion is rounded, and claiming
equality would be a small lie repeated constantly.

## Ambiguity

Some symbols are genuinely ambiguous and are resolved by convention:

| Symbol | Read as | Not |
| --- | --- | --- |
| `m` | metres | miles, minutes |
| `min` | minutes | — |
| `t` | tonnes | short tons (`ton`) |
| `st` | stones | seconds |
| `K` | kelvin | kilo — case-sensitive |

## Requirements

Swift 6, macOS 14, iOS 16, tvOS 16, watchOS 9, visionOS 1. No dependencies.
