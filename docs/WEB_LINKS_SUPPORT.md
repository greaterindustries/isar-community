# Isar Links Web Platform Support

## Summary

**Isar Links ARE fully supported on the web platform.** This document clarifies the implementation details and best practices for using links across all platforms, including web.

## Key Findings

### Links Work on Web ✅

Contrary to potential confusion from the documentation, Isar Links work perfectly on the web platform. The implementation uses IndexedDB object stores to manage link relationships between collections.

### Main Differences: Web vs VM

| Feature | Web (IndexedDB) | VM (Native) |
|---------|----------------|-------------|
| **Async Operations** | ✅ Fully supported | ✅ Fully supported |
| **Sync Operations** | ❌ Not supported | ✅ Supported |
| **Automatic Loading** | ❌ No (explicit `.load()` required) | ✅ Yes (auto-loads on first access) |
| **Link Storage** | Separate IndexedDB object stores | Native MDBX storage |
| **ID Constraints** | 53-bit safe integer range | Full 64-bit integers |

## JavaScript Number Precision Limitation

The web platform has a mathematical constraint that affects all numeric operations, not just Isar:

- **JavaScript numbers**: 64-bit floating-point (IEEE 754)
- **Safe integer range**: ±9,007,199,254,740,991 (±9 quadrillion)
- **Precision beyond this**: Not guaranteed (floating-point rounding)

### Impact on Isar

1. **Object IDs**: Must stay within the safe integer range
2. **Auto-increment**: Safely handled (uses -9,007,199,254,740,991 as sentinel)
3. **Link IDs**: Subject to same constraint as object IDs
4. **Practical impact**: Minimal for most applications

### When This Matters

- ❌ Migrating data with IDs > 9 quadrillion from native to web
- ❌ Manually assigning IDs beyond safe range
- ✅ Using auto-increment (safe by design)
- ✅ Using IDs within normal application ranges

## Best Practices for Cross-Platform Code

### ✅ DO: Use Async Methods

```dart
// Works on ALL platforms (VM + Web)
final book = await isar.books.get(bookId);
await book!.author.load();  // Explicit load
final authorName = book.author.value?.name;

await isar.writeTxn(() async {
  book.author.value = newAuthor;
  await book.author.save();  // Explicit save
});
```

### ❌ DON'T: Use Sync Methods for Cross-Platform

```dart
// Only works on VM platforms - will crash on web
final book = isar.books.getSync(bookId);
book!.author.loadSync();  // ❌ Not available on web
final authorName = book.author.value?.name;
```

### ✅ DO: Always Load Links Explicitly

```dart
// Best practice: always load explicitly
final student = await isar.students.get(id);
await student!.teacher.load();  // Works everywhere
print(student.teacher.value?.name);
```

### 💡 TIP: Auto-Loading Only Works on VM

```dart
// This auto-loads on VM but NOT on web
final student = await isar.students.get(id);
print(student!.teacher.value?.name);  // May be null on web!

// Always call .load() for cross-platform compatibility
await student.teacher.load();
print(student.teacher.value?.name);  // ✅ Works everywhere
```

## Testing

The test suite includes comprehensive link tests that run on both VM and web platforms:

```bash
# Run all link tests (includes web via async tests)
cd packages/isar_test
flutter test test/links/

# Run web-specific example test
flutter test test/links/web_link_example_test.dart --platform chrome
```

See `packages/isar_test/test/links/web_link_example_test.dart` for examples of idiomatic cross-platform link usage.

## Common Patterns

### One-to-One Relationship

```dart
@collection
class Student {
  Id? id;
  late String name;
  final teacher = IsarLink<Teacher>();
}

// Usage (cross-platform)
await isar.writeTxn(() async {
  student.teacher.value = teacher;
  await isar.students.put(student);
  await isar.teachers.put(teacher);
  await student.teacher.save();
});

// Retrieval (cross-platform)
final student = await isar.students.get(studentId);
await student!.teacher.load();
print(student.teacher.value?.subject);
```

### One-to-Many with Backlinks

```dart
@collection
class Teacher {
  Id? id;
  late String subject;
  
  @Backlink(to: 'teacher')
  final students = IsarLinks<Student>();
}

// Usage (cross-platform)
final teacher = await isar.teachers.get(teacherId);
await teacher!.students.load();
for (final student in teacher.students) {
  print(student.name);
}
```

## Migration from Native to Web

If you have an existing native app with data you want to use on web:

1. **Check ID ranges**: Ensure all IDs are within ±9,007,199,254,740,991
2. **Use auto-increment**: Let Isar manage IDs when possible
3. **Remap if needed**: If IDs exceed safe range, remap them during export/import
4. **Test thoroughly**: Run the same tests on web and native

## Documentation Updates

The following documentation has been updated to clarify web support:

- ✅ `docs/docs/limitations.md` - Added JavaScript number precision section and links clarification
- ✅ `docs/docs/links.md` - Added web platform warning and updated examples
- ⏳ Localized documentation (de, es, fr, it, ja, ko, pt, ur, zh) - Should be updated to match

## Conclusion

**Links are NOT unsupported on web.** The confusion stems from:

1. Documentation implying links are "non-web only"
2. Auto-loading behavior difference (VM auto-loads, web doesn't)
3. Sync method availability (VM has them, web doesn't)

By following the async patterns shown above, you can use Isar Links idiomatically across all platforms without workarounds.
