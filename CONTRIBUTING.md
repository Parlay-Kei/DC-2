# Contributing to Direct Cuts v2

Thank you for your interest in contributing to Direct Cuts! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)
- [Testing Guidelines](#testing-guidelines)

## Code of Conduct

Please be respectful and constructive in all interactions. We're building a welcoming community.

## Getting Started

1. **Fork the repository**
   ```bash
   gh repo fork Parlay-Kei/DC-2 --clone
   ```

2. **Set up your development environment**
   ```bash
   cd DC-2
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **Verify everything works**
   ```bash
   flutter analyze
   flutter test
   flutter run
   ```

## Development Workflow

### Branch Naming Convention

Use descriptive branch names following this pattern:

- `feature/description` - New features (e.g., `feature/add-booking-notifications`)
- `bugfix/description` - Bug fixes (e.g., `bugfix/fix-login-crash`)
- `hotfix/description` - Critical production fixes
- `chore/description` - Maintenance tasks (e.g., `chore/update-dependencies`)
- `docs/description` - Documentation updates

### Making Changes

1. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write clean, readable code
   - Follow the coding standards below
   - Add tests for new functionality
   - Update documentation as needed

3. **Run code generation** (if you modified models/providers)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Test your changes**
   ```bash
   flutter analyze
   flutter test
   dart format .
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add booking notifications"
   ```

6. **Push and create a PR**
   ```bash
   git push origin feature/your-feature-name
   gh pr create --web
   ```

## Coding Standards

### Dart/Flutter Style

- Follow the official [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter analyze` to catch issues
- Format code with `dart format .` before committing
- Maximum line length: 80 characters (use your judgment for readability)

### Project Structure

```
lib/
├── core/           # Core utilities, constants, themes
├── features/       # Feature modules (auth, booking, profile, etc.)
│   └── [feature]/
│       ├── data/       # Data sources, repositories
│       ├── domain/     # Models, entities
│       ├── providers/  # Riverpod providers
│       └── presentation/
│           ├── screens/
│           └── widgets/
├── shared/         # Shared widgets and utilities
└── main.dart
```

### State Management

- Use Riverpod for state management
- Use code generation for providers (`@riverpod`)
- Keep business logic in providers, not widgets
- Use `AsyncValue` for async data

### Code Generation

Run code generation after modifying:
- Riverpod providers with `@riverpod`
- Freezed models with `@freezed`
- JSON serialization with `@JsonSerializable`

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Commit Messages

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
type(scope): description

[optional body]
[optional footer]
```

### Types

- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Code style changes (formatting, no logic change)
- `refactor` - Code refactoring
- `test` - Test updates
- `chore` - Build process, dependencies, tooling
- `perf` - Performance improvements
- `ci` - CI/CD changes

### Examples

```
feat(booking): add real-time availability check
fix(auth): resolve login redirect loop
docs(readme): update installation instructions
refactor(profile): simplify avatar upload logic
test(booking): add unit tests for booking service
chore(deps): update flutter_riverpod to 2.4.9
```

## Pull Request Process

1. **Fill out the PR template completely**
   - Describe what changed and why
   - List related issues
   - Indicate platforms tested
   - Add screenshots for UI changes

2. **Ensure all checks pass**
   - CI pipeline (build, test, analyze)
   - Code formatting
   - No merge conflicts

3. **Request review**
   - PR will be automatically assigned to code owners
   - Address any feedback promptly

4. **Merge requirements**
   - At least 1 approval required
   - All CI checks must pass
   - Branch must be up to date with main

5. **After merge**
   - Delete your branch
   - Close related issues

## Testing Guidelines

### Unit Tests

- Test business logic in providers and services
- Mock external dependencies (API, database)
- Aim for >80% code coverage

```dart
test('booking service calculates total price correctly', () {
  final service = BookingService();
  final price = service.calculateTotal(basePrice: 25, duration: 60);
  expect(price, 25.0);
});
```

### Widget Tests

- Test widget rendering and interactions
- Mock providers using `ProviderScope.overrides`

```dart
testWidgets('booking button shows loading state', (tester) async {
  await tester.pumpWidget(BookingButton());
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

### Integration Tests

- Test complete user flows
- Test across different platforms when possible

## Platform-Specific Considerations

### Android
- Test on multiple API levels (minimum API 21)
- Check permissions handling
- Verify ProGuard rules if using native code

### iOS
- Test on iOS 12+ (minimum deployment target)
- Check Info.plist permissions
- Test on physical devices when possible

### Web
- Test responsive layouts
- Check CORS issues
- Verify service worker functionality

## Getting Help

- Check existing issues and discussions
- Join our community chat (if available)
- Tag maintainers in your PR for urgent issues

## License

By contributing, you agree that your contributions will be licensed under the project's license.

---

Thank you for contributing to Direct Cuts!
