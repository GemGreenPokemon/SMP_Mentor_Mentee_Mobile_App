# Test Directory Structure

This directory contains all tests for the SMP Mentor Mentee Mobile App. Tests are organized by feature using a self-contained modular approach.

## Directory Structure

```
test/
├── features/                   # Feature-based test organization
│   ├── mentee_registration/    # Example feature tests
│   │   ├── unit/              # Unit tests
│   │   ├── widget/            # Widget tests
│   │   └── integration/       # Integration tests
│   └── [other_features]/      # Future feature tests
├── shared/                     # Shared test utilities
│   ├── mocks/                 # Mock implementations
│   ├── fixtures/              # Test data fixtures
│   └── helpers/               # Test helper functions
└── widget_test.dart           # Default Flutter widget test
```

## Test Organization Guidelines

1. **Feature-Based Structure**: Each feature should have its own directory under `test/features/`
2. **Test Types**: Organize tests by type (unit, widget, integration)
3. **Self-Contained**: Each feature's tests should be self-contained with their own mocks and fixtures
4. **Naming Convention**: Test files should end with `_test.dart`

## Running Tests

### From Command Line
```bash
# Run all tests
flutter test

# Run specific feature tests
flutter test test/features/mentee_registration/

# Run with coverage
flutter test --coverage
```

### From Web Interface
Use the Test Runner available in Developer Settings to run tests directly from the browser.

## Creating New Tests

When adding tests for a new feature:

1. Create a new directory under `test/features/[feature_name]/`
2. Organize tests by type (unit, widget, integration)
3. Add feature-specific mocks and fixtures if needed
4. Update this README if adding new test patterns

## Example Test Structure

```dart
// test/features/example_feature/unit/example_service_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExampleService', () {
    test('should do something', () {
      // Arrange
      // Act
      // Assert
    });
  });
}
```