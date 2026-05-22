# Dartdoc Generation

Generate API documentation for the Transitly codebase.

## Quick start

```bash
dart doc .
```

Output is written to `doc/api/`. Open `doc/api/index.html` in a browser.

## Configuration

`dartdoc_options.yaml` (root):

```yaml
dartdoc:
  categoryOrder:
    - Core
    - Data
    - Features
    - Shared
  errors:
    - unresolved-export
  warnings:
    - unresolved-doc-reference
```

## GitHub Pages deployment

Add to CI (`.github/workflows/docs.yml`):

```yaml
name: Docs

on:
  push:
    branches: [master]

jobs:
  dartdoc:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.35.x"
          channel: stable
      - run: flutter pub get
      - run: dart doc .
      - uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: doc/api
```

## Notes

- `dart doc` requires `flutter pub get` first
- Generated docs exclude private members by default
- Use `///` triple-slash comments for public API documentation
- `@freezed` models generate docs from the abstract class definition
