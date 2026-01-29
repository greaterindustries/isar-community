# Isar Links Web Support - Investigation Summary

## Question Asked

> "Can we determine with some degree of confidence if Isar Links are unsupported on the web in particular? I've found I've had to work around them, and I think it's because of 64-bit integers not being supported in the browser as it comes to IndexedDB, is that the case?"

## Answer: YES, Links ARE Supported on Web! ✅

After thorough investigation of the codebase, documentation, and implementation, we can **definitively confirm** that **Isar Links ARE fully supported on the web platform**.

## The Confusion

The confusion arose from:

1. **Documentation wording**: "For non-web targets, links get loaded automatically" implied links don't work on web
2. **Different behavior**: Web requires explicit `.load()` calls; VM auto-loads on first access
3. **Sync methods**: Unavailable on web (but this applies to ALL operations, not just links)
4. **Integer precision**: JavaScript's 53-bit safe integer range (not a link-specific issue)

## What Actually Works

### ✅ Fully Supported on Web

- `IsarLink<T>` - One-to-one relationships
- `IsarLinks<T>` - One-to-many relationships
- `@Backlink()` - Reverse relationships
- `.load()` - Loading linked objects
- `.save()` - Saving link changes
- `.reset()` - Clearing links
- Auto-increment IDs (safely handled)
- Manual IDs within safe range (±9 quadrillion)

### ❌ Not Supported on Web

- `.loadSync()` - Use `.load()` instead
- `.saveSync()` - Use `.save()` instead
- All other sync operations (consistent with web platform constraints)

## The Integer Issue Explained

### JavaScript Number Precision

- **Type**: 64-bit floating-point (IEEE 754)
- **Safe integers**: ±9,007,199,254,740,991 (±9 quadrillion)
- **Beyond this**: Precision not guaranteed due to floating-point representation

### Impact on Isar

This is **NOT a link-specific limitation**. It affects:
- All object IDs
- All integer fields
- All numeric operations

### Why It's Not a Problem

1. **Auto-increment is safe**: Uses -9,007,199,254,740,991 as sentinel
2. **Range is huge**: 9 quadrillion objects per collection is practically unlimited
3. **Common IDs work**: Most apps use much smaller ID ranges
4. **Documented clearly**: New documentation explains the constraint

## Idiomatic Usage (Works Everywhere)

```dart
// Creating relationships
final teacher = Teacher()..subject = 'Math';
final student = Student()..name = 'Alice';
student.teacher.value = teacher;

await isar.writeTxn(() async {
  await isar.teachers.put(teacher);
  await isar.students.put(student);
  await student.teacher.save();  // Explicit save
});

// Reading relationships
final alice = await isar.students.get(studentId);
await alice!.teacher.load();  // Explicit load
print(alice.teacher.value?.subject);  // "Math"

// Backlinks
final mathTeacher = await isar.teachers.get(teacherId);
await mathTeacher!.students.load();
for (final student in mathTeacher.students) {
  print(student.name);
}
```

## No Workarounds Needed!

You **don't need** workarounds. Just follow these principles:

1. ✅ Use async methods (`.load()`, `.save()`)
2. ✅ Explicitly load links before accessing
3. ✅ Use auto-increment or keep manual IDs reasonable
4. ❌ Don't use sync methods on web

## Implementation Details

### How Links Work on Web

- **Storage**: Separate IndexedDB object stores per link
- **Format**: `{a: sourceId, b: targetId}` entries
- **Indexes**: Backlink index on `b` property
- **Compound keys**: `[sourceId, targetId]` for fast lookups

### How Links Work on VM

- **Storage**: Native MDBX link tables
- **Format**: Binary-optimized structure
- **Auto-loading**: Lazy loads on first property access
- **Full 64-bit**: True Int64 support

## Testing

We've added comprehensive tests demonstrating proper usage:

```bash
cd packages/isar_test
flutter pub run build_runner build
flutter test test/links/web_link_example_test.dart --platform chrome
```

## Documentation Updates

- ✅ `docs/docs/limitations.md` - Added JavaScript precision section
- ✅ `docs/docs/links.md` - Added web support clarification
- ✅ `docs/WEB_LINKS_SUPPORT.md` - Complete web links guide
- ✅ `packages/isar_test/test/links/web_link_example_test.dart` - Example tests
- ✅ `packages/isar_test/test/links/TESTING_WEB_LINKS.md` - Testing guide

## Conclusion

**Isar Links work perfectly on web.** The perceived need for "workarounds" stemmed from unclear documentation, not from actual technical limitations. By following async patterns and explicitly loading/saving links, you can use Isar Links idiomatically across all platforms without any compromises.

## References

- Web implementation: `packages/isar_web/src/link.ts`
- Dart web bindings: `packages/isar_community/lib/src/web/isar_link_impl.dart`
- Common link base: `packages/isar_community/lib/src/common/isar_link_base_impl.dart`
- Existing tests: `packages/isar_test/test/links/` (already test web via async variants)

---

**TL;DR**: Links work on web. Use async methods. No workarounds needed. 🎉
