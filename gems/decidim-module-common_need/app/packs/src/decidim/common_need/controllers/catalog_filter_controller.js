import { Controller } from "@hotwired/stimulus"

const CATEGORY_DISPLAY_NAMES = {
  all: "All 19 Decidim Community Categories",
  arts: "🎨 Arts (Studio Supplies, Screenprinting & Community Murals)",
  education: "📚 Education (Refurbished Laptops, ESL/GED & Tutoring)",
  garden: "🌱 Garden (Heirloom Seeds, Vegetable Starts & Compost)",
  pets: "🐾 Pets (Companion Animal Kibble, Flea Care & Leashes)",
  health: "😷 Health (N95 Respirators, Clean Air Filters & Hygiene)",
  mental_health: "🧠 Mental health (Bilingual Peer Counseling & Somatic Care)",
  medical: "🩺 Medical (Mobility Walkers, Blood Pressure Cuffs & Wound Care)",
  legal_aid: "⚖️ Legal aid (Eviction Defense, Expungement & Immigration)",
  employment: "🛠️ Employment (Union Apprenticeship Prep & OSHA Work Boots/PPE)",
  food: "🍎 Food (Organic Produce, Staple Grain Boxes & Nourishment)",
  housing: "🏠 Housing (Emergency Rent Relief & Weatherization/Mold Kits)",
  public_safety: "🛟 Public safety (Narcan Overdose Reversal & Safety Escorts)",
  recreation: "⚽ Recreation (Soccer/Basketball Gear, Yoga Mats & Park Passes)",
  youth_services: "🎒 Youth services (STEM Backpacks, Infant Diapers & Mentorship)",
  social_services: "📋 Social services (CalFresh/SNAP, Medi-Cal, WIC & LIHEAP)",
  public_sector: "🏛️ Public sector (Municipal IDs, Transit Waivers & Paratransit)",
  co_ops: "🌻 Co-ops (Worker Co-op Sourdough, Olive Oil & Roasts)",
  veteran_services: "🎖️ Veteran services (VA Disability Claims, DD-214 & Care Packs)",
  mutual_aid: "🤝 Mutual Aid (Solidarity Hygiene, First-Aid & Power Outage Kits)"
}

export default class extends Controller {
  static targets = ["searchInput", "pill", "hubCard", "itemCard", "bannerText", "turboFrame"]
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

    if (this.hasBannerTextTarget) {
      this.bannerTextTarget.textContent =
        CATEGORY_DISPLAY_NAMES[category] || "Showing matching community offerings"
    }

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
