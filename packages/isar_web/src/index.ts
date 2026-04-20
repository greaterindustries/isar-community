import { IsarCollection } from './collection'
import { IsarInstance } from './instance'
import { IsarLink } from './link'
import {
  getAvailableIsarWebStorageKinds,
  getSupportedIsarWebStorageKinds,
  openIsar,
} from './open'
import { IsarQuery } from './query'
import { IsarTxn } from './txn'

;(window as any).openIsar = openIsar
;(window as any).getAvailableIsarWebStorageKinds = getAvailableIsarWebStorageKinds
;(window as any).getSupportedIsarWebStorageKinds = getSupportedIsarWebStorageKinds
;(window as any).IsarInstance = IsarInstance
;(window as any).IsarTxn = IsarTxn
;(window as any).IsarCollection = IsarCollection
;(window as any).IsarQuery = IsarQuery
;(window as any).IsarLink = IsarLink
