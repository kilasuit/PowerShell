# Implementation Design Proposal: Human-Readable DateTime Display

## Status

**Proposal** - Not yet implemented

## Related Issues

- [Implement Easier to read file lengths](https://github.com/kilasuit/PowerShell/issues/170)
- [PowerShell/PowerShell#24011 - Easier to read file sizes in directory listing](https://github.com/PowerShell/PowerShell/issues/24011)

## Summary

This proposal describes how to make `DateTime` values easier to read in default PowerShell formatted output.

This is the second of three related proposals covering human-readable display improvements:

1. Size - see `human-readable-file-size-display.md`
2. **DateTime** (this proposal)
3. TimeSpan - see `human-readable-timespan-display.md`

## Motivation / Problem Statement

PowerShell currently renders file timestamps in fixed short date/time formats (for example `04/07/2024 01:36`). While this is compact and culture-aware, it is not always the most useful representation when users are triaging recent activity.

Examples where relative display is easier to scan:

- Incident response: "modified 3 minutes ago"
- Build triage: "updated yesterday"
- Log analysis: "2 days ago" versus counting calendar dates

The current display is precise but not always quickly readable for time-relative tasks.

## Current Implementation

### File listings (`Get-ChildItem`)

File listing views rely on the computed property `LastWriteTimeString` in
`src/System.Management.Automation/namespaces/FileSystemProvider.cs`:

```csharp
public static string LastWriteTimeString(PSObject instance)
{
    return instance?.BaseObject is FileSystemInfo fileInfo
        ? string.Create(CultureInfo.CurrentCulture, $"{fileInfo.LastWriteTime,10:d} {fileInfo.LastWriteTime,8:t}")
        : string.Empty;
}
```

That property is used by `src/System.Management.Automation/FormatAndOutput/DefaultFormatters/FileSystem_format_ps1xml.cs` for the `children` and `childrenWithHardlink` table views.

### `System.DateTime` default formatting

`src/System.Management.Automation/FormatAndOutput/DefaultFormatters/DotNetTypes_format_ps1xml.cs`
defines a `DateTime` view that renders the `DateTime` property directly, which defers to existing `DateTime` formatting conventions.

## Proposed Implementation Options

### Option 1: Keep absolute format, improve readability only

Retain absolute date/time display but increase readability with consistent spacing and explicit format style guidance.

**Example:**
```
04 Jul 2024 01:36
```

**Pros**
- Minimal behavioral change
- No ambiguity around timezone or reference point
- Very low compatibility risk

**Cons**
- Does not solve the "how recent is this" problem
- Users still need mental conversion to relative time

### Option 2: Relative DateTime for recent values

Use relative display for recent values while preserving absolute display for older values.

**Example policy:**
- `< 1 minute`: `just now`
- `< 1 hour`: `N min ago`
- `< 24 hours`: `N hours ago`
- `< 7 days`: `N days ago`
- `>= 7 days`: culture-aware absolute date/time

**Example output:**
```
Mode   LastWriteTime     Length Name
----   -------------     ------ ----
-a---  3 min ago            776 backup.xml
-a---  19 hours ago      17088 metadata.xml
-a---  04/07/2024 01:36  6884  oldfile.xml
```

**Pros**
- Fast scanning for recency
- Better triage UX for interactive sessions

**Cons**
- Loses precise timestamp directly in the table for recent items
- Could be surprising in scripts that parse formatted output

### Option 3: Dual-format (relative + absolute)

Display both relative and absolute values together.

**Example:**
```
3 min ago (04/07/2024 01:36)
```

**Pros**
- Keeps precision and readability
- Reduces ambiguity

**Cons**
- Expands column width significantly
- May truncate in narrow terminals

### Option 4: Experimental feature with opt-in behavior

Implement Option 2 or Option 3 behind an experimental feature flag (for example `PSHumanReadableDateTime`).

**Pros**
- Safe rollout
- Community feedback before default behavior changes
- Existing behavior remains unchanged unless enabled

**Cons**
- Additional implementation and maintenance cost

## Recommended Approach

**Option 2 behind an experimental feature (Option 4)**.

Reasoning:

1. Relative rendering provides the most user value for interactive use.
2. Experimental gating avoids breaking established expectations in default output.
3. The model matches the size proposal's rollout strategy for consistency.

## Implementation Plan (Design)

1. Add experimental feature metadata (`PSHumanReadableDateTime`) in experimental feature manifests.
2. Add a helper formatter for relative DateTime rendering with culture-aware units.
3. Update `LastWriteTimeString` to switch between existing absolute output and relative output when the feature is enabled.
4. Keep the table column width stable (target fixed width strings like `999 days ago`).
5. Add tests around boundaries (`59s`, `60s`, `59m`, `60m`, `23h`, `24h`, `6d`, `7d`).
6. Document the behavior and provide examples in changelog/docs.

## Compatibility and Risk

- Object properties are unchanged (`LastWriteTime` remains `DateTime`).
- Only display formatting changes.
- Scripts that parse formatted text output may be affected; this is a known non-goal pattern and should be called out in release notes.

## Open Questions

1. Should "future" timestamps render as `in 5 min` (clock skew scenarios)?
2. Should relative formatting include seconds granularity (`45 sec ago`) or round to minutes?
3. Should absolute fallback threshold be 7 days, 30 days, or configurable?
4. Should timezone indicator be appended in absolute fallback values?

## Related Work

- Size proposal: `human-readable-file-size-display.md`
- TimeSpan proposal: `human-readable-timespan-display.md`
