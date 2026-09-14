# Playbooks — Durus

Append-only. Reusable workflows.

No project-specific playbooks yet. Reuse the global playbooks in
`~/.config/opencode/` and sibling-project playbooks
(`klear-staff`, `telegram-trade-feed`) before writing new ones.
## deploy_free_flutter (GitHub Pages + Releases)

Use for any Flutter/Dart web+APK 100%-free deployment. Reuse before creating.

1. gh repo create <owner>/<repo> --public --source=. --remote=origin --push
2. Web: lutter build web --release --base-href /<repo>/
3. Orphan branch in temp dir: copy build/web, add .nojekyll,
   git init -b gh-pages, commit, force-push to origin gh-pages.
4. Pages auto-enables; confirm gh api repos/<owner>/<repo>/pages status=built.
5. APK: generate keystore with keytool (outside repo), write key.properties
   (gitignored), wire release signingConfig with debug fallback.
6. lutter build apk --release; gh release create v1.0.0 <apk>
7. Verify live in Chrome MCP: page title flips to app name.