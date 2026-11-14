import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modeButton",
    "listContainer",
    "gridContainer",
    "mapContainer",
    "searchInput",
    "dateSelect",
    "orgSelect",
    "topicSelect",
    "totalCount",
    "gridDayCell",
    "gridBanner",
    "mapCanvas",
    "eventCard"
  ]

  static values = {
    mode: { type: String, default: "list" },
    defaultLat: { type: Number, default: 37.779 },
    defaultLng: { type: Number, default: -122.222 },
    defaultZoom: { type: Number, default: 12 }
  }

  connect() {
    this.leafletMap = null
    this.markersLayer = null
  }

  switchMode(event) {
    const mode = event.currentTarget.dataset.mode || "list"
    this.modeValue = mode

    this.modeButtonTargets.forEach((btn) => {
      btn.classList.toggle("active", btn.dataset.mode === mode)
    })

    if (this.hasListContainerTarget) {
      this.listContainerTarget.classList.toggle("hidden", mode !== "list")
    }
    if (this.hasGridContainerTarget) {
      this.gridContainerTarget.classList.toggle("hidden", mode !== "grid")
    }
    if (this.hasMapContainerTarget) {
      this.mapContainerTarget.classList.toggle("hidden", mode !== "map")
    }

    if (mode === "map") {
      setTimeout(() => {
        this.initLeafletMap()
        if (this.leafletMap) {
          this.leafletMap.invalidateSize()
          this.syncMapMarkers()
        }
      }, 120)
    }
  }

  selectDayFromGrid(event) {
    const day = event.currentTarget.dataset.gridDay || "all"

    if (this.hasDateSelectTarget) {
      this.dateSelectTarget.value = day
    }

    this.gridDayCellTargets.forEach((cell) => {
      cell.classList.toggle("selected-day", day !== "all" && cell.dataset.gridDay === day)
    })

    this.filterEvents()

    if (this.hasGridBannerTarget) {
      this.gridBannerTarget.textContent =
        day === "all"
          ? "Showing all November 2026 partner events below • Tap a date cell to filter"
          : `Filtered to ${day} • Showing matching partner events below`
    }
  }

  filterEvents() {
    const query = this.hasSearchInputTarget ? this.searchInputTarget.value.toLowerCase().trim() : ""
    const selDate = this.hasDateSelectTarget ? this.dateSelectTarget.value : "all"
    const selOrg = this.hasOrgSelectTarget ? this.orgSelectTarget.value : "all"
    const selTopic = this.hasTopicSelectTarget ? this.topicSelectTarget.value : "all"

    let visibleCount = 0

    this.eventCardTargets.forEach((card) => {
      const cardDay = card.dataset.day || ""
      const cardOrg = card.dataset.org || ""
      const cardTopic = card.dataset.topic || ""
      const cardText = `${card.textContent} ${card.dataset.keywords || ""}`.toLowerCase()

      const matchesDate = selDate === "all" || cardDay === selDate
      const matchesOrg = selOrg === "all" || cardOrg === selOrg
      const matchesTopic = selTopic === "all" || cardTopic === selTopic
      const matchesQuery = !query || cardText.includes(query)

      const show = matchesDate && matchesOrg && matchesTopic && matchesQuery
      card.style.display = show ? "block" : "none"
      if (show) visibleCount += 1
    })

    if (this.hasTotalCountTarget) {
      this.totalCountTarget.textContent = visibleCount
    }

    if (this.leafletMap) {
      this.syncMapMarkers()
    }
  }

  initLeafletMap() {
    if (this.leafletMap || !this.hasMapCanvasTarget || typeof window.L === "undefined") {
      return
    }

    this.leafletMap = window.L.map(this.mapCanvasTarget, { zoomControl: true }).setView(
      [this.defaultLatValue, this.defaultLngValue],
      this.defaultZoomValue
    )

    window.L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19,
      attribution: "© OpenStreetMap • Decidim::Map::DynamicMap"
    }).addTo(this.leafletMap)

    this.markersLayer = window.L.layerGroup().addTo(this.leafletMap)
    this.syncMapMarkers()
  }

  syncMapMarkers() {
    if (!this.leafletMap || !this.markersLayer || typeof window.L === "undefined") {
      return
    }

    this.markersLayer.clearLayers()
    const bounds = []

    this.eventCardTargets.forEach((card) => {
      if (card.style.display === "none") return

      const lat = parseFloat(card.dataset.lat || "37.7651")
      const lng = parseFloat(card.dataset.lng || "-122.1755")
      const titleEl = card.querySelector(".pantry-title")
      const badgeEl = card.querySelector(".olive-badge")
      const loc = card.dataset.location || "Oakland Local Hub"
      const title = titleEl ? titleEl.textContent : "Partner Event"
      const when = badgeEl ? badgeEl.textContent : ""

      const marker = window.L.marker([lat, lng])
      marker.bindPopup(`<strong>${title}</strong><br>${when}<br>📍 ${loc}`)
      marker.addTo(this.markersLayer)
      bounds.push([lat, lng])
    })

    if (bounds.length > 0) {
      this.leafletMap.fitBounds(bounds, { padding: [24, 24], maxZoom: 14 })
    }
  }

  resetMapBounds() {
    this.syncMapMarkers()
    if (typeof window.showToast === "function") {
      window.showToast("Centered map on all visible partner event locations in #OAK-01.")
    }
  }
}
