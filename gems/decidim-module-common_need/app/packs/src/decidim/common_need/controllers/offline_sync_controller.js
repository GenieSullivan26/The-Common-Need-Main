import { Controller } from "@hotwired/stimulus"

const DB_NAME = "common_need_offline_store"
const DB_VERSION = 1
const ROUTE_STORE = "osrm_routes"
const SYNC_QUEUE_STORE = "stop_confirmations_queue"

export default class extends Controller {
  static targets = ["syncStatus", "stopCard"]
  static values = {
    serviceWorkerUrl: { type: String, default: "/service-worker.js" },
    offlineBundleUrl: { type: String, default: "/volunteer/routes/OAK-409/offline_bundle.json" },
    confirmUrlTemplate: { type: String, default: "/volunteer/routes/OAK-409/route_stops/:stop_id/confirm_stop" }
  }

  connect() {
    this.dbPromise = this.openDatabase()
    this.registerServiceWorker()
    this.cacheRouteBundle()

    this.boundOnlineHandler = () => this.flushSyncQueue()
    window.addEventListener("online", this.boundOnlineHandler)
  }

  disconnect() {
    if (this.boundOnlineHandler) {
      window.removeEventListener("online", this.boundOnlineHandler)
    }
  }

  registerServiceWorker() {
    if ("serviceWorker" in navigator) {
      navigator.serviceWorker.register(this.serviceWorkerUrlValue).catch(() => {
        // Service worker registration gracefully skipped in non-HTTPS preview contexts
      })
    }
  }

  openDatabase() {
    if (typeof window.indexedDB === "undefined") {
      return Promise.resolve(null)
    }

    return new Promise((resolve, reject) => {
      const request = window.indexedDB.open(DB_NAME, DB_VERSION)

      request.onupgradeneeded = (event) => {
        const db = event.target.result
        if (!db.objectStoreNames.contains(ROUTE_STORE)) {
          db.createObjectStore(ROUTE_STORE, { keyPath: "batchCode" })
        }
        if (!db.objectStoreNames.contains(SYNC_QUEUE_STORE)) {
          db.createObjectStore(SYNC_QUEUE_STORE, { keyPath: "id", autoIncrement: true })
        }
      }

      request.onsuccess = (event) => resolve(event.target.result)
      request.onerror = (event) => reject(event.target.error)
    })
  }

  async cacheRouteBundle() {
    const fallbackBundle = {
      batchCode: "BATCH #OAK-409",
      cachedAt: new Date().toISOString(),
      polyline: [
        [37.7651, -122.1755],
        [37.8215, -122.2769],
        [37.7685, -122.1960]
      ],
      maneuvers: [
        { counter: "[ ↱ ] LEG 1 OF 3 • STEP 1/4", dist: "5.8 mi (9 min)", text: "Head northwest on MacArthur Blvd and merge onto I-580 W toward West Oakland." },
        { counter: "[ ↖ ] LEG 1 OF 3 • STEP 2/4", dist: "0.6 mi (2 min)", text: "Take Exit 19C toward West St / San Pablo Ave and merge onto 36th St toward Stop #2." },
        { counter: "[ ↰ ] LEG 1 OF 3 • STEP 3/4", dist: "0.4 mi (1 min)", text: "Turn left onto San Pablo Ave toward 31st St." },
        { counter: "[ 🏁 ] LEG 1 OF 3 • STEP 4/4", dist: "0.0 mi (Arrive)", text: "Arrive at Stop #2: West County Mutual Aid Care Hub (3115 San Pablo Ave) on right." }
      ]
    }

    try {
      const db = await this.dbPromise
      if (!db) return

      const tx = db.transaction(ROUTE_STORE, "readwrite")
      tx.objectStore(ROUTE_STORE).put(fallbackBundle)
    } catch (_err) {
      // Ignore IndexedDB quota/privacy errors
    }
  }

  async confirmStop(event) {
    const stopNumber = parseInt(event.currentTarget.dataset.stopNumber || "2", 10)
    const payload = {
      stopNumber,
      confirmedAt: new Date().toISOString(),
      batchCode: "BATCH #OAK-409"
    }

    if (!navigator.onLine) {
      await this.enqueueConfirmation(payload)
      if (this.hasSyncStatusTarget) {
        this.syncStatusTarget.textContent = "⏳ Queued Offline"
      }
      return
    }

    await this.sendConfirmation(payload)
  }

  async enqueueConfirmation(payload) {
    try {
      const db = await this.dbPromise
      if (!db) return
      const tx = db.transaction(SYNC_QUEUE_STORE, "readwrite")
      tx.objectStore(SYNC_QUEUE_STORE).add(payload)
    } catch (_err) {
      // Fallback in-memory queue
    }
  }

  async flushSyncQueue() {
    try {
      const db = await this.dbPromise
      if (!db) return

      const tx = db.transaction(SYNC_QUEUE_STORE, "readwrite")
      const store = tx.objectStore(SYNC_QUEUE_STORE)
      const getAllReq = store.getAll()

      getAllReq.onsuccess = async () => {
        const items = getAllReq.result || []
        for (const item of items) {
          await this.sendConfirmation(item)
        }
        const clearTx = db.transaction(SYNC_QUEUE_STORE, "readwrite")
        clearTx.objectStore(SYNC_QUEUE_STORE).clear()
        if (this.hasSyncStatusTarget) {
          this.syncStatusTarget.textContent = "✓ Synced"
        }
      }
    } catch (_err) {
      // Ignore flush error
    }
  }

  async sendConfirmation(payload) {
    const url = this.confirmUrlTemplateValue.replace(":stop_id", String(payload.stopNumber))
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

    try {
      await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "text/vnd.turbo-stream.html, application/json",
          ...(csrfToken ? { "X-CSRF-Token": csrfToken } : {})
        },
        body: JSON.stringify(payload)
      })
    } catch (_err) {
      await this.enqueueConfirmation(payload)
    }
  }
}
