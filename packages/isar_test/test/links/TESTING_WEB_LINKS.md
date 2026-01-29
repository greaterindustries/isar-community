# Testing Isar Links on Web

## Quick Start

To verify that Isar Links work correctly on the web platform, follow these steps:

## Prerequisites

- Flutter SDK (version specified in `.github/workflows/test.yaml`)
- Chrome browser (for web testing)

## Generate Test Code

Before running tests, you need to generate the `.g.dart` files:

```bash
cd packages/isar_test

# Install dependencies
flutter pub get

# Generate test code (including web_link_example_test.g.dart)
flutter pub run build_runner build

# Alternative: Watch for changes
flutter pub run build_runner watch
```

## Run Tests

### Run All Link Tests (VM + Web)

```bash
cd packages/isar_test

# Run on VM (includes sync and async tests)
flutter test test/links/

# Run on Web (Chrome) - async tests only
flutter test test/links/ --platform chrome
```

### Run Web-Specific Example Test

```bash
cd packages/isar_test

# Run the idiomatic cross-platform examples
flutter test test/links/web_link_example_test.dart --platform chrome
```

### Run Specific Test Groups

```bash
# Run just the web-compatible link usage tests
flutter test test/links/web_link_example_test.dart --platform chrome --name "Web-compatible"

# Run a specific test case
flutter test test/links/web_link_example_test.dart --platform chrome --name "Idiomatic async"
```

## CI/CD Integration

The tests are automatically run in the GitHub Actions workflow. See `.github/workflows/test.yaml` for the complete test matrix.

## Test Coverage

The `web_link_example_test.dart` file demonstrates:

1. ✅ Idiomatic async link pattern (works on all platforms)
2. ✅ Links with auto-increment IDs
3. ✅ Links with manual IDs within safe JavaScript range
4. ✅ Updating and resetting links
5. ✅ Multiple links using IsarLinks
6. ✅ Backlinks for reverse relationships

## Expected Results

All tests should pass on both VM and Web platforms:

- **VM**: Both sync and async variants pass
- **Web**: Async variants pass (sync tests are skipped automatically)

## Troubleshooting

### Build Runner Issues

If code generation fails:

```bash
# Clean and rebuild
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Web Test Failures

If web tests fail with "unsupportedOnWeb" errors:
- ✅ Verify you're using async methods (`.load()`, `.save()`)
- ❌ Check you're not using sync methods (`.loadSync()`, `.saveSync()`)

### Missing .g.dart Files

If you see import errors for `.g.dart` files:
- Run `flutter pub run build_runner build` first
- The `.g.dart` files are generated and should not be manually created

## Performance Notes

Web tests may run slower than VM tests due to:
- Browser startup overhead
- IndexedDB async operations
- JavaScript runtime differences

This is expected and normal behavior.
