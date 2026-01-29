---
title: Limitations
---

# Limitations

As you know, Isar works on mobile devices and desktops running on the VM as well as Web. Both platforms are very different and have different limitations.

## VM Limitations

- Only the first 1024 bytes of a string can be used for a prefix where-clause
- Objects can only be 16MB in size

## Web Limitations

Because Isar Web relies on IndexedDB, there are more limitations, but they are barely noticeable while using Isar.

- Synchronous methods are unsupported
- Currently, `Isar.splitWords()` and `.matches()` filters are not yet implemented
- Schema changes are not as tightly checked as in the VM so be careful to comply with the rules
- All number types are stored as double (the only js number type) so `@Size32` has no effect
- Indexes are represented differently so hash indexes don't use less space (they still work the same)
- `col.delete()` and `col.deleteAll()` work correctly but the return value is not correct
- `col.clear()` do not reset the auto-increment value
- `NaN` is not supported as a value

### JavaScript Number Precision

JavaScript numbers are 64-bit floating-point values (IEEE 754), which means integers are only safe up to 53 bits of precision. This affects Isar on the web:

- **Safe integer range**: ±9,007,199,254,740,991 (about ±9 quadrillion)
- **ID values**: Must stay within this range to avoid precision loss
- **Auto-increment**: Safely handled by using the negative boundary (-9,007,199,254,740,991)
- **Links**: Work correctly as long as IDs are within the safe range (which is the default behavior)

For most applications, this 53-bit integer limit is not a practical constraint. However, if you're migrating data from a native platform that uses IDs beyond this range, you'll need to remap those IDs for web compatibility.

### Links on Web

IsarLinks work fully on the web platform with the following considerations:

- **Async operations only**: Use `.load()` and `.save()` (sync versions are unsupported)
- **No automatic loading**: Links must be explicitly loaded with `.load()` (unlike VM targets where they auto-load on first access)
- **ID constraints**: Link relationships use IDs, which are subject to the JavaScript number precision limits above

For idiomatic cross-platform code, always use the async link methods:
```dart
// ✅ Works on all platforms
await link.load();
await link.save();

// ❌ Only works on VM platforms
link.loadSync();
link.saveSync();
```
