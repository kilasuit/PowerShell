# Implementation Design Proposal: Human-Readable DateTime Display

## Status

**Planned** - Design proposal to be written

## Related Issues

- [Implement Easier to read file lengths](https://github.com/kilasuit/PowerShell/issues/170)
- [PowerShell/PowerShell#24011 - Easier to read file sizes in directory listing](https://github.com/PowerShell/PowerShell/issues/24011)

## Summary

This proposal will describe how to make `DateTime` values in PowerShell output easier to read.
This is one of three related proposals for human-readable display improvements:

1. **Size** - see `human-readable-file-size-display.md` (proposal complete)
2. **DateTime** (this proposal - to be detailed)
3. TimeSpan - see `human-readable-timespan-display.md`

## Scope

The proposal will cover improvements to how `DateTime` values are displayed in formatted output,
potentially including:

- Relative time display (e.g., `2 hours ago`, `yesterday`, `3 days ago`) for `LastWriteTime` in `Get-ChildItem`
- Configurable date/time format strings in `$PSStyle`
- Locale-aware formatting improvements

## Next Steps

A detailed implementation design proposal will be written as a follow-up to the Size proposal.
