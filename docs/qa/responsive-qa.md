# Responsive / RTL / theme QA matrix

> Sprint G4 seed. Expand cells as goldens and manual passes land.

| Surface | Web desktop | Tablet | Mobile | LTR | RTL (ar) | Light | Dark |
|---------|-------------|--------|--------|-----|----------|-------|------|
| Login | | | | | | | |
| Today’s desk | | | | | | | |
| Master list | | | | | | | |
| Master form | | | | | | | |
| Document (SI) | | | | | | | |
| Report viewer | | | | | | | |
| Command palette | | | | | | | |
| Settings | | | | | | | |

**Legend:** blank = not yet signed off · `ok` · `issue:…`

## Notes

- Breakpoints: `lib/core/responsive/breakpoints.dart` (mobile / tablet / desktop / large).
- Locale: Settings → Language (en / ar / system) via `LocaleCubit`.
- Theme: Settings → Appearance via `ThemeCubit`.
- Palette: Ctrl/Cmd+K or header search.
