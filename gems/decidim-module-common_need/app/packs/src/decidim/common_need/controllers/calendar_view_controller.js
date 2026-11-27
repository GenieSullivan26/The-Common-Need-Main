import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modeButton",
    "listContainer",
    "gridContainer",
    "searchInput",
    "dateSelect",
    "orgSelect",
    "topicSelect",
    "totalCount",
    "gridDayCell",
    "gridBanner",
    "eventCard"
  ]

  static values = {
    mode: { type: String, default: "list" }
  }

  switchMode(event) {
    const mode = event.currentTarget.dataset.mode || "list"
    this.modeValue = mode

    this.modeButtonTargets.forEach((btn) => {
      btn.classList.toggle("active", btn.dataset.mode === mode)
    })

    if (this.hasListContainerTarget) {
      this.listContainerTarget.classList.remove("hidden")
    }
    if (this.hasGridContainerTarget) {
      this.gridContainerTarget.classList.toggle("hidden", mode !== "grid")
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
  }
}
