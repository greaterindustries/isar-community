import { IsarTxn } from './txn'
import { asValidKey } from './key'

function normalizeIndexLookupKey(
  index: { keyPath: string | string[] | null },
  key: IDBValidKey,
): IDBValidKey {
  const keyPath = index.keyPath
  const isSingleKeyPath =
    typeof keyPath === 'string' || (Array.isArray(keyPath) && keyPath.length === 1)
  return isSingleKeyPath && Array.isArray(key) ? key[0] : key
}

export function bulkDelete(
  txn: IsarTxn,
  storeName: string,
  keys: (IDBValidKey | IDBKeyRange)[],
): Promise<void> {
  return new Promise((resolve, reject) => {
    const len = keys.length
    const lastItem = len - 1
    if (len === 0) return resolve()
    const store = txn.txn.objectStore(storeName)
    for (let i = 0; i < keys.length; i++) {
      const req = store.delete(keys[i])
      req.onerror = () => {
        txn.abort()
        reject(req.error)
      }
      if (i === lastItem) {
        req.onsuccess = () => {
          resolve()
        }
      }
    }
  })
}

export function bulkDeleteByIndex(
  txn: IsarTxn,
  storeName: string,
  indexName: string,
  keys: IDBValidKey[],
): Promise<IDBValidKey[]> {
  const validKeys = keys.filter((key): key is IDBValidKey => asValidKey(key) != null)
  if (validKeys.length === 0) return Promise.resolve([])
  return new Promise((resolve, reject) => {
    const store = txn.txn.objectStore(storeName)
    const index = store.index(indexName)
    const normalizedKeys = validKeys.map((key) => normalizeIndexLookupKey(index, key))

    const primaryKeys: IDBValidKey[] = []
    for (var i = 0; i < normalizedKeys.length; i++) {
      const indexReq = index.getAllKeys(normalizedKeys[i])
      const isLast = i === normalizedKeys.length - 1
      indexReq.onsuccess = () => {
        primaryKeys.push(...indexReq.result)
        if (isLast) {
          bulkDelete(txn, storeName, primaryKeys).then(
            () => resolve(primaryKeys),
            reject,
          )
        }
      }
      indexReq.onerror = () => {
        txn.abort()
        reject(indexReq.error)
      }
    }
  })
}
