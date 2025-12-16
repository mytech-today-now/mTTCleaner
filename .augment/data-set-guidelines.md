# Bookmark Data Set Fix Guidelines

**Tool:** `bookmarks/data-set-fix.ps1`

## CRITICAL: AI Must Use data-set-fix.ps1
1. **NEVER manually edit** data set files for structural/syntax/formatting errors
2. **ALWAYS update `data-set-fix.ps1`** with new fix capabilities if needed
3. **ALWAYS run `data-set-fix.ps1`** to process fixes

## Quick Reference

```powershell
# Diagnose
.\bookmarks\data-set-fix.ps1 -InputFile ".\bookmarks\<file>.psd1" -Diagnose

# Fix all
.\bookmarks\data-set-fix.ps1 -InputFile ".\bookmarks\<file>.psd1" -AllFixes

# Specific fixes
.\bookmarks\data-set-fix.ps1 -InputFile ".\bookmarks\<file>.psd1" -FixBraces -FixSyntax
```

## Fix Parameters
| Parameter | Fixes |
|-----------|-------|
| `-FixBraces` | Missing/extra braces |
| `-FixSyntax` | Missing `=`, invalid commas |
| `-FixQuotes` | Smart quotes, apostrophes |
| `-RemoveDuplicates` | Duplicate keys |
| `-RepairHierarchy` | Escaped keys (needs `-WrapperKey`) |
| `-AllFixes` | Apply all |

## Adding New Fixes
1. Add parameter to script
2. Add repair function following existing patterns
3. Call function in processing section
4. Document in script help

