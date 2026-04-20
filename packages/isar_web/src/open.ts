import equal from 'fast-deep-equal'
import { IsarInstance } from './instance'
import { IsarLink } from './link'
import { OpfsDatabase } from './opfs'
import { IndexSchema, IsarType, LinkSchema, Schema } from './schema'

// Polyfill for older browsers
if (typeof IDBTransaction.prototype.commit !== "function") {
  IDBTransaction.prototype.commit = function () { }
}

export type IsarWebStorageKind =
  | 'indexedDbJsRuntime'
  | 'opfsWasmRuntime'

type RuntimeDescriptor = {
  implemented: boolean
  browserSupported: () => boolean
}

const runtimeDescriptors = {
  indexedDbJsRuntime: {
    implemented: true,
    browserSupported: () => typeof indexedDB !== 'undefined',
  },
  opfsWasmRuntime: {
    implemented: true,
    browserSupported: () =>
      typeof navigator !== 'undefined' &&
      typeof navigator.storage?.getDirectory === 'function',
  },
} satisfies Record<IsarWebStorageKind, RuntimeDescriptor>

function objectStoreNames(list: DOMStringList): string[] {
  const names: string[] = []
  for (let i = 0; i < list.length; i++) {
    const name = list.item(i)
    if (name != null) {
      names.push(name)
    }
  }
  return names
}

export function getAvailableIsarWebStorageKinds(): IsarWebStorageKind[] {
  return Object.entries(runtimeDescriptors)
    .filter(([, descriptor]) => descriptor.browserSupported())
    .map(([kind]) => kind as IsarWebStorageKind)
}

export function getSupportedIsarWebStorageKinds(): IsarWebStorageKind[] {
  return Object.entries(runtimeDescriptors)
    .filter(([, descriptor]) =>
      descriptor.implemented && descriptor.browserSupported())
    .map(([kind]) => kind as IsarWebStorageKind)
}

export function openIsar(
  name: string,
  schemas: Schema[],
  relaxedDurability: boolean,
  runtime: IsarWebStorageKind = 'indexedDbJsRuntime',
): Promise<IsarInstance> {
  return runtime === 'opfsWasmRuntime'
    ? openOpfs(name, schemas, relaxedDurability)
    : openInternal(name, schemas, relaxedDurability)
}

async function openOpfs(
  name: string,
  schemas: Schema[],
  relaxedDurability: boolean,
): Promise<IsarInstance> {
  const db = await OpfsDatabase.open(name, schemas)
  return new IsarInstance(db, relaxedDurability, schemas)
}

function openInternal(
  name: string,
  schemas: Schema[],
  relaxedDurability: boolean,
  version?: number,
): Promise<IsarInstance> {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(name, version)
    req.onsuccess = () => {
      const db = req.result
      if (version == null) {
        const txn = db.transaction(objectStoreNames(db.objectStoreNames), 'readonly')
        if (!performUpgrade(txn, true, schemas)) {
          const newVersion = txn.db.version + 1
          db.close()
          resolve(openInternal(name, schemas, relaxedDurability, newVersion))
          return
        }
      }

      const instance = new IsarInstance(db, relaxedDurability, schemas)
      resolve(instance)
    }
    req.onupgradeneeded = () => {
      performUpgrade(req.transaction!, false, schemas)
    }
    req.onerror = () => {
      reject(req.error)
    }
  })
}

function performUpgrade(
  txn: IDBTransaction,
  dryRun: boolean,
  schemas: Schema[],
): boolean {
  const schemaStoreNames: string[] = []
  for (const schema of schemas) {
    schemaStoreNames.push(schema.name)
    const schemaIndexNames: string[] = []

    let store: IDBObjectStore
    if (!txn.objectStoreNames.contains(schema.name)) {
      if (dryRun) {
        return false
      }
      store = txn.db.createObjectStore(schema.name, {
        autoIncrement: true,
      })
    } else {
      store = txn.objectStore(schema.name)
    }

    for (let indexSchema of schema.indexes) {
      schemaIndexNames.push(indexSchema.name)
      if (store.indexNames.contains(indexSchema.name)) {
        const index = store.index(indexSchema.name)
        if (IndexSchema.matchesIndex(schema, indexSchema, index)) {
          continue
        } else {
          if (!dryRun) {
            store.deleteIndex(indexSchema.name)
          }
        }
      }
      if (dryRun) {
        return false
      }
      store.createIndex(indexSchema.name, IndexSchema.getKeyPath(indexSchema), {
        unique: indexSchema.unique,
        multiEntry: IndexSchema.isIndexMultiEntry(schema, indexSchema),
      })
    }

    for (let linkSchema of schema.links) {
      const name = LinkSchema.getStoreName(
        schema.name,
        linkSchema.target,
        linkSchema.name,
      )
      let linkStore: IDBObjectStore
      if (!txn.objectStoreNames.contains(name)) {
        if (dryRun) {
          return false
        }
        linkStore = txn.db.createObjectStore(name, {
          keyPath: ['a', 'b'],
          autoIncrement: false,
        })
      } else {
        linkStore = txn.objectStore(name)
      }
      schemaStoreNames.push(name)

      const indexesOk = equal(
        objectStoreNames(linkStore.indexNames),
        [IsarLink.BacklinkIndex],
      )
      if (!indexesOk) {
        if (dryRun) {
          return false
        }
        for (const indexName of objectStoreNames(linkStore.indexNames)) {
          linkStore.deleteIndex(indexName)
        }
        linkStore.createIndex(IsarLink.BacklinkIndex, 'b')
      }
    }

    for (const indexName of objectStoreNames(store.indexNames)) {
      if (schemaIndexNames.indexOf(indexName) === -1) {
        if (dryRun) {
          return false
        }
        store.deleteIndex(indexName)
      }
    }
  }

  for (const storeName of objectStoreNames(txn.objectStoreNames)) {
    if (schemaStoreNames.indexOf(storeName) === -1) {
      if (dryRun) {
        return false
      }
      txn.db.deleteObjectStore(storeName)
    }
  }

  return true
  return true
}

type CollectionInfo = {
  properties: {
    [key: string]: CollectionProperty
  }
  nextId: number
}

type CollectionProperty = {
  id: number
  type: IsarType
}
