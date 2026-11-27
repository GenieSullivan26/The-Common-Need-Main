import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["searchInput", "pill", "hubCard", "itemCard", "turboFrame"]
  static values = {
    activeCategory: { type: String, default: "all" },
    catalogUrl: { type: String, default: "/member/catalog" }
  }

  connect() {
    this.updateHubCardVisibility()
  }

  filterByPill(event) {
    const button = event.currentTarget
    const category = button.dataset.category || "all"
    this.activeCategoryValue = category

    this.pillTargets.forEach((pill) => {
      pill.classList.toggle("active", pill === button)
    })

    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = ""
    }

    this.itemCardTargets.forEach((card) => {
      const matches = category === "all" || card.dataset.category === category
      card.style.display = matches ? "flex" : "none"
    })

    this.updateHubCardVisibility()

    if (this.hasTurboFrameTarget && button.dataset.turboSync === "true") {
      const url = new URL(this.catalogUrlValue, window.location.origin)
      url.searchParams.set("category", category)
      this.turboFrameTarget.src = url.toString()
    }
  }

  search(event) {
    const query = (event.currentTarget.value || "").toLowerCase().trim()

    this.itemCardTargets.forEach((card) => {
      const text = card.textContent.toLowerCase()
      const category = (card.dataset.category || "").toLowerCase().replace(/_/g, " ")
      const matches = !query || text.includes(query) || category.includes(query)
      card.style.display = matches ? "flex" : "none"
    })

    this.updateHubCardVisibility()
  }

  updateHubCardVisibility() {
    this.hubCardTargets.forEach((hubCard) => {
      const visibleItems = Array.from(hubCard.querySelectorAll(".item-lime-card")).filter(
        (item) => item.style.display !== "none"
      )
      hubCard.style.display = visibleItems.length > 0 ? "block" : "none"
    })
  }
}
