# Implementation Design Proposal: Human-Readable TimeSpan Display

## Status

**Proposal** - Not yet implemented

## Related Issues

- [Implement Easier to read file lengths](https://github.com/kilasuit/PowerShell/issues/170)
- [PowerShell/PowerShell#24011 - Easier to read file sizes in directory listing](https://github.com/PowerShell/PowerShell/issues/24011)

## Summary

This proposal describes how to make `TimeSpan` values easier to read in default PowerShell formatted output.

This is the third of three related proposals covering human-readable display improvements:

1. Size - see `human-readable-file-size-display.md`
2. DateTime - see `human-readable-datetime-display.md`
3. **TimeSpan** (this proposal)

## Motivation / Problem Statement

PowerShell commonly displays `TimeSpan` values using canonical .NET formatting (for example `00:00:00.0452000` or `1.02:03:04`). These are precise but not always easy to interpret quickly.

Examples of friction:

- `00:00:00.0452000` requires mental conversion to "45.2 milliseconds"
- `1.02:03:04` is compact but not instantly readable as "1 day, 2 hours, 3 minutes, 4 seconds"
- Large durations are difficult to compare visually in table output

A human-readable representation improves discoverability and triage speed in interactive sessions.

## Current Implementation

`System.TimeSpan` format views are defined in:
`src/System.Management.Automation/FormatAndOutput/DefaultFormatters/DotNetTypes_format_ps1xml.cs`

Current views:

- **List view**: shows component and total properties (`Days`, `Hours`, `TotalMilliseconds`, etc.)
- **Table view**: columns for `Days`, `Hours`, `Minutes`, `Seconds`, `Milliseconds`
- **Wide view**: `TotalMilliseconds`

There is no dedicated compact humanized formatter today; output is mostly numeric and property-centric.

## Proposed Implementation Options

### Option 1: Keep numeric output; add separators/rounding guidance

Retain current component display and only standardize precision for common contexts.

**Pros**
- Minimal change
- Keeps exact numeric interpretation

**Cons**
- Does not significantly improve readability

### Option 2: Humanized natural-language string

Introduce compact natural language rendering for interactive default table/list contexts.

**Examples:**

- `00:00:00.0452000` -> `45.2 ms`
- `00:03:12` -> `3 min 12 sec`
- `02:15:00` -> `2 hr 15 min`
- `1.02:03:04` -> `1 d 2 hr 3 min`

**Pros**
- Very fast visual scanning
- Unit-aware representation
- Better UX for diagnostics and progress-like outputs

**Cons**
- Loses direct full precision unless explicitly requested
- Potential width variability

### Option 3: Dual output (humanized + canonical)

Display humanized value followed by canonical string.

**Example:**
```
2 hr 15 min (02:15:00)
```

**Pros**
- Readable and precise at the same time

**Cons**
- Significantly wider display strings
- More truncation in narrow terminal widths

### Option 4: Experimental feature-gated formatter

Use Option 2 (or Option 3) behind an experimental feature (for example `PSHumanReadableTimeSpan`).

**Pros**
- Low-risk rollout
- Community feedback before default behavior changes
- Preserves compatibility by default

**Cons**
- Added implementation complexity

## Recommended Approach

**Option 2 behind an experimental feature (Option 4)**.

Reasoning:

1. Humanized TimeSpan values provide the largest readability gain.
2. Experimental gating protects existing workflows and expectations.
3. This aligns rollout strategy with the size and DateTime proposals.

## Proposed Formatting Rules (Design Draft)

### Unit selection

- `< 1 ms`: show microseconds where available (`250 us`) or `0 ms` if no sub-ms precision is desired
- `< 1 sec`: show milliseconds with one decimal place (`45.2 ms`)
- `< 1 min`: show seconds with one decimal place (`12.4 sec`)
- `< 1 hr`: show minutes and optional seconds (`3 min 12 sec`)
- `< 1 day`: show hours and minutes (`2 hr 15 min`)
- `>= 1 day`: show days, hours, and minutes (`1 d 2 hr 3 min`)

### Rounding

- Use banker-independent standard rounding (`MidpointRounding.AwayFromZero`) for user-facing values.
- Keep at most one decimal place for sub-minute displays.

### Negative values

- Preserve sign prefix: `-3.5 sec`, `-1 hr 12 min`.

### Width target

- Keep default rendered strings under ~16 characters where possible to fit common table layouts.

## Implementation Plan (Design)

1. Add experimental feature metadata (`PSHumanReadableTimeSpan`) to feature manifests.
2. Add a centralized TimeSpan humanization helper in formatting/runtime utilities.
3. Update `System.TimeSpan` format views to use the helper for the relevant default view(s) when feature is enabled.
4. Keep existing views unchanged when feature is disabled.
5. Add tests for boundary values and sign handling.
6. Document behavior and examples in changelog/docs.

## Compatibility and Risk

- `TimeSpan` objects and properties are unchanged.
- Only display rendering changes in selected views.
- Scripts parsing formatted strings may be impacted; this should be documented as unsupported parsing behavior.

## Test Matrix (Design)

Suggested targeted test cases:

- `TimeSpan.Zero`
- `TimeSpan.FromTicks(1)`
- `TimeSpan.FromMilliseconds(999.95)`
- `TimeSpan.FromSeconds(59.95)`
- `TimeSpan.FromMinutes(59.5)`
- `TimeSpan.FromHours(23.9)`
- `TimeSpan.FromDays(1.5)`
- Negative variants for each category

## Open Questions

1. Should sub-millisecond values be surfaced as microseconds (`us`) or rounded to milliseconds?
2. Should rounding mode be configurable?
3. Should canonical string be available via an opt-in table column style?
4. Should we align abbreviations with .NET or PowerShell-specific conventions (`hr` vs `h`, `sec` vs `s`)?

## Related Work

- Size proposal: `human-readable-file-size-display.md`
- DateTime proposal: `human-readable-datetime-display.md`
