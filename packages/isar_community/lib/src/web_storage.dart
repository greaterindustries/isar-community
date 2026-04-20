part of isar;

/// Storage runtimes exposed by the Isar web package.
enum IsarWebStorageKind {
  /// The legacy JavaScript runtime backed by IndexedDB object stores.
  indexedDbJsRuntime,

  /// A future wasm-backed runtime persisted in OPFS.
  opfsWasmRuntime,
}

/// Returns the storage runtimes enabled by the current Isar web build.
Future<List<IsarWebStorageKind>> getSupportedIsarWebStorageKinds() =>
    getSupportedWebStorageKinds();

/// Returns the storage runtimes the current browser can detect, even if they
/// are not implemented by this Isar web build yet.
Future<List<IsarWebStorageKind>> getAvailableIsarWebStorageKinds() =>
    getAvailableWebStorageKinds();
