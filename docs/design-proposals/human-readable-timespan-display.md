# Implementation Design Proposal: Human-Readable TimeSpan Display

## Status

**Planned** - Design proposal to be written

## Related Issues

- [Implement Easier to read file lengths](https://github.com/kilasuit/PowerShell/issues/170)
- [PowerShell/PowerShell#24011 - Easier to read file sizes in directory listing](https://github.com/PowerShell/PowerShell/issues/24011)

## Summary

This proposal will describe how to make `TimeSpan` values in PowerShell output easier to read.
This is one of three related proposals for human-readable display improvements:

1. **Size** - see `human-readable-file-size-display.md` (proposal complete)
2. DateTime - see `human-readable-datetime-display.md`
3. **TimeSpan** (this proposal - to be detailed)

## Scope

The proposal will cover improvements to how `TimeSpan` values are displayed in formatted output,
potentially including:

- Natural language formatting (e.g., `1 hour 30 minutes` instead of `01:30:00`)
- Condensed display for small values (e.g., `45.2 ms` instead of `00:00:00.0452000`)
- Configurable format strings in `$PSStyle`

## Next Steps

A detailed implementation design proposal will be written as a follow-up to the Size proposal.
