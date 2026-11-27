# Implementation Design Proposal: Human-Readable File Size Display

## Status

**Proposal** - Not yet implemented

## Related Issues

- [Implement Easier to read file lengths](https://github.com/kilasuit/PowerShell/issues/170)
- [PowerShell/PowerShell#24011 - Easier to read file sizes in directory listing](https://github.com/PowerShell/PowerShell/issues/24011)

## Summary

This proposal describes how to make the `Length` column in `Get-ChildItem` output easier to read by displaying file sizes in a human-readable format (e.g., `1.18 TB` instead of `1298450612224`).

This is the first of three related proposals covering human-readable display improvements:

1. **Size** (this proposal)
2. DateTime (separate proposal - see `human-readable-datetime-display.md`)
3. TimeSpan (separate proposal - see `human-readable-timespan-display.md`)

## Motivation / Problem Statement

When using `Get-ChildItem` (or its alias `dir`/`ls`) to list files, the `Length` column currently shows raw byte counts. For large files, these numbers are difficult to read at a glance:

```
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---          04/07/2024    01:36      859832320 small-backup.vhdx
-a---          04/07/2024    01:36  1298450612224 large-backup.vhdx
-a---          04/07/2024    01:36       62914560 esp.vhdx
```

The number `1298450612224` requires the user to manually count digits to determine the order of magnitude. This is poor user experience compared to tools like Windows File Explorer, which displays `1.18 TB` using binary units (1024-based), or the Unix `ls -h` flag which uses a similar convention.

## Current Implementation

### `LengthString` in `FileSystemProvider.cs`

The `Length` column is populated via the `LengthString` computed property defined in
`src/System.Management.Automation/namespaces/FileSystemProvider.cs`:

```csharp
public static string LengthString(PSObject instance)
{
    return instance?.BaseObject is FileInfo fileInfo
        ? fileInfo.Attributes.HasFlag(FileAttributes.Offline)
            ? $"({fileInfo.Length})"
            : fileInfo.Length.ToString()
        : string.Empty;
}
```

This is registered in the type system via `TypeTable_Types_Ps1Xml.cs` and used in the table format view defined in `FileSystem_format_ps1xml.cs`.

### Existing `DisplayHumanReadableFileSize` Utility

There is already a utility function in `src/System.Management.Automation/engine/Utils.cs` that converts bytes to human-readable format. It is currently used for progress display during copy/remove operations:

```csharp
internal static string DisplayHumanReadableFileSize(long bytes)
{
    return bytes switch
    {
        < 1024 and >= 0 => $"{bytes} Bytes",
        < 1048576 and >= 1024 => $"{(bytes / 1024.0).ToString("0.0")} KB",
        < 1073741824 and >= 1048576 => $"{(bytes / 1048576.0).ToString("0.0")} MB",
        < 1099511627776 and >= 1073741824 => $"{(bytes / 1073741824.0).ToString("0.000")} GB",
        < 1125899906842624 and >= 1099511627776 => $"{(bytes / 1099511627776.0).ToString("0.00000")} TB",
        < 1152921504606847000 and >= 1125899906842624 => $"{(bytes / 1125899906842624.0).ToString("0.0000000")} PB",
        >= 1152921504606847000 => $"{(bytes / 1152921504606847000.0).ToString("0.000000000")} EB",
        _ => $"0 Bytes",
    };
}
```

## Proposed Implementation Options

### Option 1: Thousands Separator (N0 format)

Format the byte count with thousands separators, keeping the raw byte value but making it easier to read at a glance.

**Example output:**
```
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---          04/07/2024    01:36    859,832,320 small-backup.vhdx
-a---          04/07/2024    01:36 1,298,450,612,224 large-backup.vhdx
-a---          04/07/2024    01:36     62,914,560 esp.vhdx
```

**Pros:**
- Lossless: retains exact byte count
- Familiar to users who need precise sizes
- Locale-aware (commas vs. periods depending on system locale)
- No breaking change for scripts that parse the `Length` property (`.Length` on `FileInfo` is unaffected)

**Cons:**
- Column still grows wide for very large files
- Still requires some cognitive effort for very large numbers

**Implementation:**

Modify `LengthString` to use the `N0` format specifier:

```csharp
public static string LengthString(PSObject instance)
{
    return instance?.BaseObject is FileInfo fileInfo
        ? fileInfo.Attributes.HasFlag(FileAttributes.Offline)
            ? $"({fileInfo.Length:N0})"
            : fileInfo.Length.ToString("N0")
        : string.Empty;
}
```

Note: The column width in `FileSystem_format_ps1xml.cs` would need to be adjusted from 14 to accommodate larger formatted strings (e.g., `1,298,450,612,224` is 17 characters).

### Option 2: Human-Readable Units (KB/MB/GB/TB)

Display file sizes in the largest appropriate unit, similar to Windows File Explorer or Unix `ls -h`.

**Example output:**
```
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---          04/07/2024    01:36       820.1 MB small-backup.vhdx
-a---          04/07/2024    01:36        1.18 TB large-backup.vhdx
-a---          04/07/2024    01:36        60.0 MB esp.vhdx
```

**Pros:**
- Extremely easy to read at a glance
- Consistent with Windows Explorer, macOS Finder, and `ls -h` on Unix
- Fixed-width column (e.g., `10.0 KB` to `999.9 TB`)

**Cons:**
- Lossy: exact byte count not shown
- Could potentially break scripts that parse the `Length` column from formatted output (though this is not recommended practice)
- Requires a decision on binary (KiB/MiB/GiB) vs. decimal (KB/MB/GB) units

**Implementation:**

Reuse the existing `DisplayHumanReadableFileSize` utility (with possible refinements for consistent column width) in `LengthString`:

```csharp
public static string LengthString(PSObject instance)
{
    return instance?.BaseObject is FileInfo fileInfo
        ? fileInfo.Attributes.HasFlag(FileAttributes.Offline)
            ? $"({Utils.DisplayHumanReadableFileSize(fileInfo.Length)})"
            : Utils.DisplayHumanReadableFileSize(fileInfo.Length)
        : string.Empty;
}
```

The `DisplayHumanReadableFileSize` function would need to be reviewed and potentially updated to produce consistent-width output suitable for table alignment.

### Option 3: Experimental Feature with Configurable Format

Wrap the change in an experimental feature flag (similar to other formatting changes in PowerShell), allowing users to opt in. The format could be configurable via `$PSStyle`.

**Example (experimental feature enabled):**

```powershell
Enable-ExperimentalFeature PSFileInfoHumanReadableSize
# Restart PowerShell session
Get-ChildItem
```

```
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---          04/07/2024    01:36       820.1 MB small-backup.vhdx
-a---          04/07/2024    01:36        1.18 TB large-backup.vhdx
-a---          04/07/2024    01:36        60.0 MB esp.vhdx
```

**Pros:**
- No breaking change for existing users
- Opt-in allows gathering feedback before making the change the default
- Follows established PowerShell pattern for behavior-changing features

**Cons:**
- More implementation work (experimental feature infrastructure)
- Feature may never graduate from experimental status
- Users need to discover and enable the feature

## Recommended Approach

**Option 2 (human-readable units) wrapped in an experimental feature (Option 3)** is the recommended approach because:

1. It provides the most user-friendly output
2. The experimental feature wrapper minimizes risk of breaking existing workflows
3. The existing `DisplayHumanReadableFileSize` function can be reused with minor adjustments
4. This mirrors how other improvements to `FileSystemProvider` formatting have been introduced (e.g., the `PSAnsiRenderingFileInfo` experimental feature)

Once the experimental feature has been validated and has received positive community feedback, it can be promoted to the default behavior in a future major version.

## Implementation Steps

1. **Review and refine `DisplayHumanReadableFileSize`**
   - Make the function `public` or extract a `public` variant that is suitable for column display
   - Ensure consistent output width for table alignment
   - Consider whether to use binary (1024-based) or decimal (1000-based) units
   - Add culture-aware formatting

2. **Create experimental feature**
   - Add `PSFileInfoHumanReadableSize` to `experimental-feature-windows.json` and `experimental-feature-linux.json`
   - Update `TypeTable_Types_Ps1Xml.cs` to conditionally use the new format when the feature is enabled

3. **Update `LengthString`**
   - Modify `FileSystemProvider.cs` to call the human-readable formatter when the experimental feature is active
   - Keep existing behavior when the feature is not enabled

4. **Update column width in format definition**
   - Update `FileSystem_format_ps1xml.cs` to accommodate the new format width (e.g., 10 characters is typically sufficient for `000.0 XB`)

5. **Update tests**
   - Add/update tests in `test/powershell/Modules/Microsoft.PowerShell.Management/FileSystem.Tests.ps1` to verify the new formatting behavior
   - Test with the experimental feature both enabled and disabled

6. **Documentation**
   - Update `CHANGELOG.md` with the new feature
   - Consider adding an entry to the `docs/` for user-facing documentation

## Considerations and Open Questions

### Binary vs. Decimal Units

- **Binary (IEC) units**: KB = 1024 bytes, MB = 1,048,576 bytes, etc. (also written KiB, MiB, etc.)
- **Decimal (SI) units**: KB = 1,000 bytes, MB = 1,000,000 bytes, etc.

Windows Explorer displays file sizes using binary units (1024-based), even though it labels them as KB/MB/GB/TB rather than using the IEC KiB/MiB/GiB/TiB notation. The existing `DisplayHumanReadableFileSize` in `Utils.cs` also uses binary units. The implementation should follow this convention for consistency, but the community should confirm whether to adopt IEC notation (KiB/MiB/GiB) for precision.

### Offline Files

The current implementation wraps offline file sizes in parentheses: `(1234)`. This convention should be preserved: `(1.2 GB)` or `(1,234,567,890)`.

### Very Small Files (< 1 KB)

Files under 1 KB should still display bytes. The threshold for switching to KB should be at least 1024 bytes to avoid displaying `0.0 KB`.

### Backwards Compatibility

The `Length` **property** on `FileInfo` objects (`$file.Length`) is unaffected — it will continue to return an exact `long` value. Only the formatted **display** string changes.

Scripts that parse `Get-ChildItem | Format-Table Length` output would be affected if they rely on the raw byte string, but such parsing is generally considered bad practice in favor of using the property value directly.

### Column Width

Switching from raw bytes to human-readable units changes the column width characteristics:
- Raw bytes: variable width, up to 20+ characters for very large files
- Human-readable: relatively fixed width, typically 6-10 characters

The column width in `FileSystem_format_ps1xml.cs` should be updated accordingly.

## Related Work

- This proposal covers **Size** only. Related proposals should be created for:
  - **DateTime**: Easier-to-read `LastWriteTime` display (e.g., relative times like "2 hours ago")
  - **TimeSpan**: Easier-to-read `TimeSpan` display in other contexts
