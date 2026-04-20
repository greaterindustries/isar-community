type Key = IDBValidKey

export const webAutoIncrementId = -9007199254740991

export function isAutoIncrementKey(value: unknown): value is number {
  return value === webAutoIncrementId
}

export function asValidKey(value: unknown): Key | undefined {
  if (value === undefined || isAutoIncrementKey(value)) {
    return undefined
  }

  try {
    indexedDB.cmp(value as Key, value as Key)
    return value as Key
  } catch (_) {
    return undefined
  }
}

export function keyEquals(a: unknown, b: unknown): boolean {
  const left = asValidKey(a)
  const right = asValidKey(b)
  return left != null && right != null && indexedDB.cmp(left, right) === 0
}

export function compareKeys(a: unknown, b: unknown): number {
  const left = asValidKey(a)
  const right = asValidKey(b)

  if (left != null && right != null) {
    return indexedDB.cmp(left, right)
  }
  if (left != null) {
    return -1
  }
  if (right != null) {
    return 1
  }

  const leftFallback = JSON.stringify(a) ?? String(a)
  const rightFallback = JSON.stringify(b) ?? String(b)
  return leftFallback.localeCompare(rightFallback)
}
