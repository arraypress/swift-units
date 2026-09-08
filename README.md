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

## Data rate

Foundation has a dimension for how much data there is and none at all for how
fast it moves, so `UnitDataRate` is a real `Dimension` subclass — everything
else here works on it unchanged.

```swift
Units.dataRate("100 Mbps", as: .megabytesPerSecond)   // 12.5 MB/s
```

That gap is the most common "my internet is slower than advertised" complaint
there is, and both numbers describe the same speed.

Bits and bytes are told apart by the spelling, which is a reliable convention:
a `bps` suffix is bits, because that is how a connection is sold, and a `B/s`
suffix is bytes, because that is how a transfer is reported. Case-sensitive for
exactly that reason — `MB/s` is eight times `Mb/s`, and quietly picking one
would be wrong half the time. A sloppy lowercase `mbps` resolves to megabits,
which is what somebody writing about their broadband means.

Decimal, not binary: 1 Mbps is exactly 1,000 kbps, while 1 MiB really is 1,024
KiB. That is why rate and storage are separate dimensions rather than one with
a suffix.

## CSS units

`px`, `em`, `rem`, `pt` and `pc`, because developers convert those constantly.

```swift
try Units.convertCSS("24 px", to: "rem")    // 1.5 rem
try Units.convertCSS("12 pt", to: "px")     // 16 px
try Units.convertCSS("96 px", to: "in")     // 1 in
```

`px` and `em` are not fixed lengths — a pixel is a fraction of an inch at an
assumed density, and an em is however many pixels the base font size says. Both
are configurable, because both are project decisions:

```swift
let config = Units.CSSConfiguration(baseFontSize: 20, pixelDensity: 96)
try Units.convertCSS("40 px", to: "rem", configuration: config)   // 2 rem
```

Defaults are 16 px/em and 96 ppi — the CSS reference pixel, not any real
screen's density, which is what browsers use.

They are modelled as real `UnitLength` units, so a CSS length converts to
millimetres or feet for free.

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
