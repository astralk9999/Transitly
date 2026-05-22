# Contributing to Transitly

## Getting started

```bash
flutter pub get
flutter gen-l10n
tool/build.sh
flutter run
```

## Development workflow

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Make changes following [ARCHITECTURE.md](docs/ARCHITECTURE.md)
4. Ensure `flutter analyze` has 0 issues
5. Ensure `flutter test` passes all tests
6. Commit using [Conventional Commits](https://www.conventionalcommits.org/)
7. Push and open a PR

## Commit conventions

- `feat:` new feature
- `fix:` bug fix
- `refactor:` code restructuring
- `docs:` documentation
- `test:` adding or fixing tests
- `chore:` maintenance tasks

## Code style

- Dart: follow `analysis_options.yaml` (strict-casts, strict-raw-types)
- Widgets: feature-first organization (see ARCHITECTURE.md)
- Models: use `@freezed` for value types
