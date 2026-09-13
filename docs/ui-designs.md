# Durus UI Design — Three Runtime Themes

Appendix to the master plan: how the "3-design-rule" is satisfied for the
teacher/manager Android app. Arabic-first, RTL throughout. Seeded via
`src/lib/theme/themes.dart` (Material 3 `ColorScheme.fromSeed`), pickable in
Settings, persisted in `SharedPreferences` (`theme_key`), applied in
`app.dart` before the router.

| Key | Name (Arabic) | Seed | Surface | Character |
|---|---|---|---|---|
| `d1` (default) | دفتر (notebook) | `0xFF7A5C3E` warm brown | `0xFFFDF8F2` paper | calm, familiar, low glare for long teaching days |
| `d2` | لوح (board) | `0xFF00897B` teal | `0xFFF2FAF7` mint | fresh, energetic, modern |
| `d3` | مكتب (desk) | `0xFF1E293B` slate | null (Material default) | serious, compact (denser `CardTheme` via `compact`) |

All three keep the same layout, spacing and component rules — only color seed
(+ density for `d3`) differs, so switching never breaks layouts. Dark mode is a
separate toggle and stacks on top of any theme.

Why these three:
- دفتر (notebook) — default: a paper-like warm brown used during long teaching
  sessions; lowest visual fatigue.
- لوح (board) — for users who want a fresh, green board feel.
- مكتب (desk) — slate + compact density for managers doing admin work on web.

Parent portal (web) intentionally does NOT expose themes: one clean portal
look, maximum simplicity for non-technical parents.