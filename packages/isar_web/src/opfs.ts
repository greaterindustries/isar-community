import { IndexSchema, LinkSchema, Schema } from './schema'
import { asValidKey, compareKeys, keyEquals } from './key'

type Key = IDBValidKey
type KeyOrRange = IDBValidKey | IDBKeyRange

type StoreDefinition = {
  name: string
  keyPath?: string | string[]
  autoIncrement: boolean
  indexes: IndexDefinition[]
}

type IndexDefinition = {
  name: string
  keyPath: string | string[]
  unique: boolean
  multiEntry: boolean
}

type PersistedRecord = {
  key: Key
  value: any
}

type PersistedStore = {
  keyPath?: string | string[]
  autoIncrement: boolean
  nextKey: number
  records: PersistedRecord[]
}

type PersistedDatabase = {
  stores: Record<string, PersistedStore>
}

const isarRootDir = 'isar_community'

function clone<T>(value: T): T {
  return structuredClone(value)
}

function matchesKey(rangeOrKey: KeyOrRange, key: Key): boolean {
  return rangeOrKey instanceof IDBKeyRange
    ? rangeOrKey.includes(key)
    : keyEquals(rangeOrKey, key)
}

function normalizeKeyPath(keyPath?: string | string[]): string[] {
  if (keyPath == null) {
    return []
  }
  return Array.isArray(keyPath) ? keyPath : [keyPath]
}

function getKeyFromValue(value: any, keyPath?: string | string[]): Key | undefined {
  const path = normalizeKeyPath(keyPath)
  if (path.length === 0) {
    return undefined
  }
  if (path.length === 1) {
    return asValidKey(value[path[0]])
  }
  return asValidKey(path.map((part) => value[part]))
}

function setKeyOnValue(value: any, keyPath: string | string[], key: Key) {
  const path = normalizeKeyPath(keyPath)
  if (path.length === 1) {
    value[path[0]] = key
    return
  }
  if (Array.isArray(key)) {
    for (let i = 0; i < path.length; i++) {
      value[path[i]] = key[i]
    }
  }
}

function objectStoreNames(list: Record<string, PersistedStore>): string[] {
  return Object.keys(list)
}

function buildDefinitions(schemas: Schema[]): StoreDefinition[] {
  const definitions: StoreDefinition[] = []
  for (const schema of schemas) {
    definitions.push({
      name: schema.name,
      autoIncrement: true,
      indexes: schema.indexes.map((index) => ({
        name: index.name,
        keyPath: IndexSchema.getKeyPath(index),
        unique: index.unique,
        multiEntry: IndexSchema.isIndexMultiEntry(schema, index),
      })),
    })

    for (const link of schema.links) {
      definitions.push({
        name: LinkSchema.getStoreName(schema.name, link.target, link.name),
        keyPath: ['a', 'b'],
        autoIncrement: false,
        indexes: [
          {
            name: 'backlink',
            keyPath: 'b',
            unique: false,
            multiEntry: false,
          },
        ],
      })
    }
  }
  return definitions
}

function upgradeState(
  state: PersistedDatabase,
  definitions: StoreDefinition[],
): PersistedDatabase {
  const upgradedStores: Record<string, PersistedStore> = {}
  for (const definition of definitions) {
    const existing = state.stores[definition.name]
    upgradedStores[definition.name] = existing ?? {
      keyPath: definition.keyPath,
      autoIncrement: definition.autoIncrement,
      nextKey: 1,
      records: [],
    }
  }
  return { stores: upgradedStores }
}

class OpfsStringList {
  constructor(private readonly values: string[]) {}

  get length(): number {
    return this.values.length
  }

  contains(value: string): boolean {
    return this.values.includes(value)
  }

  item(index: number): string | null {
    return this.values[index] ?? null
  }
}

class OpfsRequest<T> {
  result!: T
  error: any = null
  onsuccess: ((event?: any) => void) | null = null
  onerror: ((event?: any) => void) | null = null

  constructor(action?: () => T | Promise<T>) {
    if (!action) {
      return
    }
    queueMicrotask(async () => {
      try {
        this.result = await action()
        this.onsuccess?.({ target: this })
      } catch (error) {
        this.error = error
        this.onerror?.({ target: this })
      }
    })
  }
}

type CursorEntry = {
  key: Key
  primaryKey: Key
  value: any
}

class OpfsCursorRequest extends OpfsRequest<OpfsCursor | null> {
  constructor(entries: CursorEntry[]) {
    super()
    this.emit(entries, 0)
  }

  emit(entries: CursorEntry[], index: number) {
    queueMicrotask(() => {
      this.result =
        index < entries.length ? new OpfsCursor(entries, index, this) : null
      this.onsuccess?.({ target: this })
    })
  }
}

class OpfsCursor {
  constructor(
    private readonly entries: CursorEntry[],
    private index: number,
    private readonly request: OpfsCursorRequest,
  ) {}

  get key(): Key {
    return this.entries[this.index].key
  }

  get primaryKey(): Key {
    return this.entries[this.index].primaryKey
  }

  get value(): any {
    return clone(this.entries[this.index].value)
  }

  continue(nextKey?: Key) {
    let nextIndex = this.index + 1
    if (nextKey != null) {
      nextIndex = this.entries.findIndex(
        (entry, candidateIndex) =>
          candidateIndex >= this.index + 1 &&
          compareKeys(entry.key, nextKey) >= 0,
      )
      if (nextIndex === -1) {
        nextIndex = this.entries.length
      }
    }
    this.request.emit(this.entries, nextIndex)
  }

  advance(count: number) {
    this.request.emit(this.entries, this.index + count)
  }
}

class OpfsIndex {
  constructor(
    private readonly store: OpfsObjectStore,
    readonly name: string,
    readonly keyPath: string | string[],
    readonly multiEntry: boolean,
  ) {}

  private entries(): CursorEntry[] {
    const entries: CursorEntry[] = []
    for (const record of this.store.records()) {
      const key = getKeyFromValue(record.value, this.keyPath)
      if (this.multiEntry && Array.isArray(key)) {
        for (const item of key) {
          const entryKey = asValidKey(item)
          if (entryKey == null) {
            continue
          }
          entries.push({
            key: entryKey,
            primaryKey: record.key,
            value: record.value,
          })
        }
      } else if (key != null) {
        entries.push({
          key,
          primaryKey: record.key,
          value: record.value,
        })
      }
    }
    entries.sort((left, right) => {
      const keyOrder = compareKeys(left.key, right.key)
      return keyOrder !== 0
        ? keyOrder
        : compareKeys(left.primaryKey, right.primaryKey)
    })
    return entries
  }

  openCursor(
    range?: IDBKeyRange,
    direction: IDBCursorDirection = 'next',
  ): OpfsCursorRequest {
    let entries = this.entries()
    if (range) {
      entries = entries.filter((entry) => range.includes(entry.key))
    }
    if (direction.startsWith('prev')) {
      entries = [...entries].reverse()
    }
    if (direction.endsWith('unique')) {
      const distinct: CursorEntry[] = []
      let previousKey: Key | undefined
      for (const entry of entries) {
        if (previousKey == null || !keyEquals(previousKey, entry.key)) {
          distinct.push(entry)
          previousKey = entry.key
        }
      }
      entries = distinct
    }
    return new OpfsCursorRequest(entries)
  }

  getAllKeys(query: KeyOrRange): OpfsRequest<Key[]> {
    return new OpfsRequest(() =>
      this.entries()
        .filter((entry) => matchesKey(query, entry.key))
        .map((entry) => clone(entry.primaryKey)),
    )
  }
}

class OpfsObjectStore {
  readonly indexNames: OpfsStringList

  constructor(
    private readonly state: PersistedStore,
    readonly name: string,
    private readonly definition: StoreDefinition,
  ) {
    this.indexNames = new OpfsStringList(definition.indexes.map((index) => index.name))
  }

  records(): PersistedRecord[] {
    return this.state.records
  }

  private resolveKey(value: any): { key: Key; storedValue: any } {
    const rawValue = clone(value)
    const explicitKey =
      asValidKey(value?._id) ?? asValidKey(value?.id)
    let key = explicitKey ?? getKeyFromValue(rawValue, this.state.keyPath)
    if (key == null) {
      if (!this.state.autoIncrement) {
        throw new Error(`Missing key for store ${this.name}`)
      }
      key = this.state.nextKey++
      if (this.state.keyPath) {
        setKeyOnValue(rawValue, this.state.keyPath, key)
      }
    } else if (typeof key === 'number' && this.state.autoIncrement) {
      this.state.nextKey = Math.max(this.state.nextKey, key + 1)
    }

    const storedValue = clone(rawValue)
    delete storedValue._id
    delete storedValue.id
    return { key, storedValue }
  }

  private assertUniqueIndexes(key: Key, value: any) {
    for (const indexDefinition of this.definition.indexes) {
      if (!indexDefinition.unique) {
        continue
      }
      const incomingKey = getKeyFromValue(value, indexDefinition.keyPath)
      if (incomingKey == null) {
        continue
      }
      for (const record of this.state.records) {
        if (keyEquals(record.key, key)) {
          continue
        }
        const existingKey = getKeyFromValue(record.value, indexDefinition.keyPath)
        if (existingKey != null && keyEquals(existingKey as Key, incomingKey as Key)) {
          throw new Error(
            `Unique index ${indexDefinition.name} violated in store ${this.name}`,
          )
        }
      }
    }
  }

  private writeRecord(value: any, overwrite: boolean): Key {
    const { key, storedValue } = this.resolveKey(value)
    const existingIndex = this.state.records.findIndex((record) =>
      keyEquals(record.key, key),
    )
    if (!overwrite && existingIndex >= 0) {
      throw new Error(`Key ${JSON.stringify(key)} already exists in store ${this.name}`)
    }

    this.assertUniqueIndexes(key, storedValue)
    const persisted = { key, value: storedValue }
    if (existingIndex >= 0) {
      this.state.records[existingIndex] = persisted
    } else {
      this.state.records.push(persisted)
    }
    return clone(key)
  }

  get(key: Key): OpfsRequest<any> {
    return new OpfsRequest(() => {
      const record = this.state.records.find((candidate) => keyEquals(candidate.key, key))
      return record ? clone(record.value) : undefined
    })
  }

  put(value: any): OpfsRequest<Key> {
    return new OpfsRequest(() => this.writeRecord(value, true))
  }

  add(value: any): OpfsRequest<Key> {
    return new OpfsRequest(() => this.writeRecord(value, false))
  }

  delete(keyOrRange: KeyOrRange): OpfsRequest<void> {
    return new OpfsRequest(() => {
      this.state.records = this.state.records.filter(
        (record) => !matchesKey(keyOrRange, record.key),
      )
    })
  }

  clear(): OpfsRequest<void> {
    return new OpfsRequest(() => {
      this.state.records = []
    })
  }

  openCursor(
    range?: IDBKeyRange,
    direction: IDBCursorDirection = 'next',
  ): OpfsCursorRequest {
    let entries = this.state.records
      .map((record) => ({
        key: record.key,
        primaryKey: record.key,
        value: record.value,
      }))
      .sort((left, right) => compareKeys(left.key, right.key))

    if (range) {
      entries = entries.filter((entry) => range.includes(entry.key))
    }
    if (direction.startsWith('prev')) {
      entries = [...entries].reverse()
    }
    return new OpfsCursorRequest(entries)
  }

  index(name: string): OpfsIndex {
    const definition = this.definition.indexes.find((index) => index.name === name)
    if (!definition) {
      throw new Error(`Unknown index ${name} on store ${this.name}`)
    }
    return new OpfsIndex(this, definition.name, definition.keyPath, definition.multiEntry)
  }
}

export class OpfsTransaction {
  active = true
  oncomplete: (() => void) | null = null
  onerror: (() => void) | null = null
  error: any = null

  private readonly state: PersistedDatabase

  constructor(
    private readonly database: OpfsDatabase,
    readonly write: boolean,
  ) {
    this.state = write ? clone(database.snapshot()) : database.snapshot()
  }

  objectStore(name: string): OpfsObjectStore {
    const definition = this.database.definition(name)
    const store = this.state.stores[name]
    if (!store) {
      throw new Error(`Unknown store ${name}`)
    }
    return new OpfsObjectStore(store, name, definition)
  }

  commit() {
    void this.database
      .commitTransaction(this.state, this.write)
      .then(() => {
        this.active = false
        this.oncomplete?.()
      })
      .catch((error) => {
        this.active = false
        this.error = error
        this.onerror?.()
      })
  }

  abort() {
    this.active = false
  }
}

export class OpfsDatabase {
  readonly version = 1
  readonly objectStoreNames: OpfsStringList

  private constructor(
    readonly name: string,
    private state: PersistedDatabase,
    private readonly definitions: Map<string, StoreDefinition>,
    private readonly fileHandle: FileSystemFileHandle,
  ) {
    this.objectStoreNames = new OpfsStringList(objectStoreNames(state.stores))
  }

  static async open(name: string, schemas: Schema[]): Promise<OpfsDatabase> {
    const root = await navigator.storage.getDirectory()
    const dir = await root.getDirectoryHandle(isarRootDir, { create: true })
    const fileHandle = await dir.getFileHandle(`${name}.json`, { create: true })
    const persisted = await readPersistedDatabase(fileHandle)
    const definitions = new Map(buildDefinitions(schemas).map((definition) => [definition.name, definition]))
    const state = upgradeState(persisted, [...definitions.values()])
    return new OpfsDatabase(name, state, definitions, fileHandle)
  }

  definition(name: string): StoreDefinition {
    const definition = this.definitions.get(name)
    if (!definition) {
      throw new Error(`Unknown store definition ${name}`)
    }
    return definition
  }

  snapshot(): PersistedDatabase {
    return this.state
  }

  transaction(
    _storeNames: any,
    mode: IDBTransactionMode,
    _options?: any,
  ): OpfsTransaction {
    return new OpfsTransaction(this, mode === 'readwrite')
  }

  async commitTransaction(state: PersistedDatabase, write: boolean) {
    if (!write) {
      return
    }
    this.state = state
    await writePersistedDatabase(this.fileHandle, state)
  }

  close() {}

  async deleteFromDisk() {
    const root = await navigator.storage.getDirectory()
    const dir = await root.getDirectoryHandle(isarRootDir, { create: true })
    await dir.removeEntry(`${this.name}.json`)
  }
}

async function readPersistedDatabase(
  fileHandle: FileSystemFileHandle,
): Promise<PersistedDatabase> {
  const file = await fileHandle.getFile()
  const text = await file.text()
  if (!text) {
    return { stores: {} }
  }
  return JSON.parse(text) as PersistedDatabase
}

async function writePersistedDatabase(
  fileHandle: FileSystemFileHandle,
  state: PersistedDatabase,
) {
  const writable = await (
    fileHandle as FileSystemFileHandle & {
      createWritable(): Promise<{
        write(data: string): Promise<void>
        close(): Promise<void>
      }>
    }
  ).createWritable()
  await writable.write(JSON.stringify(state))
  await writable.close()
}
