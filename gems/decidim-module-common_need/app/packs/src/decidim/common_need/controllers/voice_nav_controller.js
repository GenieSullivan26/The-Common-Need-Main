import { Controller } from "@hotwired/stimulus"

const DEFAULT_MANEUVERS = [
  {
    counter: "[ ↱ ] LEG 1 OF 3 • STEP 1/4",
    dist: "5.8 mi (9 min)",
    text: "Head northwest on MacArthur Blvd and merge onto I-580 W toward West Oakland."
  },
  {
    counter: "[ ↖ ] LEG 1 OF 3 • STEP 2/4",
    dist: "0.6 mi (2 min)",
    text: "Take Exit 19C toward West St / San Pablo Ave and merge onto 36th St toward Stop #2."
  },
  {
    counter: "[ ↰ ] LEG 1 OF 3 • STEP 3/4",
    dist: "0.4 mi (1 min)",
    text: "Turn left onto San Pablo Ave toward 31st St."
  },
  {
    counter: "[ 🏁 ] LEG 1 OF 3 • STEP 4/4",
    dist: "0.0 mi (Arrive)",
    text: "Arrive at Stop #2: West County Mutual Aid Care Hub (3115 San Pablo Ave) on right."
  }
]

const DEFAULT_ROUTE_COORDS = [
  [37.7651, -122.1755], // Stop 1: East Oakland Collective Pantry (7800 MacArthur Blvd)
  [37.8215, -122.2769], // Stop 2: West County Mutual Aid Care Hub (3115 San Pablo Ave)
  [37.7685, -122.1960]  // Stop 3: Member Household (1400 Block of 62nd Ave)
]

export default class extends Controller {
  static targets = ["mapCanvas", "stepCounter", "stepDist", "instructionText"]
  static values = {
    currentStepIndex: { type: Number, default: 1 },
    maneuvers: { type: Array, default: DEFAULT_MANEUVERS },
    routeCoords: { type: Array, default: DEFAULT_ROUTE_COORDS }
  }

  connect() {
    this.leafletMap = null
    this.renderCurrentStep()
    this.initRouteMap()
  }

  prevStep() {
    this.step(-1)
  }

  nextStep() {
    this.step(1)
  }

  step(delta) {
    const steps = this.maneuversValue.length ? this.maneuversValue : DEFAULT_MANEUVERS
    this.currentStepIndexValue = (this.currentStepIndexValue + delta + steps.length) % steps.length
    this.renderCurrentStep()
  }

  renderCurrentStep() {
    const steps = this.maneuversValue.length ? this.maneuversValue : DEFAULT_MANEUVERS
    const step = steps[this.currentStepIndexValue] || steps[0]
    if (!step) return

    if (this.hasStepCounterTarget) this.stepCounterTarget.textContent = step.counter
    if (this.hasStepDistTarget) this.stepDistTarget.textContent = step.dist
    if (this.hasInstructionTextTarget) this.instructionTextTarget.textContent = step.text
  }

  speakCurrentStep() {
    const steps = this.maneuversValue.length ? this.maneuversValue : DEFAULT_MANEUVERS
    const step = steps[this.currentStepIndexValue] || steps[0]
    if (!step) return

    if ("speechSynthesis" in window && typeof window.SpeechSynthesisUtterance !== "undefined") {
      window.speechSynthesis.cancel()
      const utterance = new window.SpeechSynthesisUtterance(step.text)
      utterance.rate = 1.0
      window.speechSynthesis.speak(utterance)
    }

    if (typeof window.showToast === "function") {
      window.showToast(`🔊 Voice Navigation: "${step.text}"`)
    }
  }

  initRouteMap() {
    if (this.leafletMap || !this.hasMapCanvasTarget || typeof window.L === "undefined") {
      return
    }

    const coords = this.routeCoordsValue.length ? this.routeCoordsValue : DEFAULT_ROUTE_COORDS
    this.leafletMap = window.L.map(this.mapCanvasTarget, { zoomControl: true }).setView([37.785, -122.225], 12)

    window.L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19,
      attribution: "© OpenStreetMap • Local OSRM"
    }).addTo(this.leafletMap)

    window.L.polyline(coords, { color: "#C5FF29", weight: 4 }).addTo(this.leafletMap)
    coords.forEach((coord, idx) => {
      window.L.marker(coord).addTo(this.leafletMap).bindPopup(`Stop #${idx + 1}`)
    })
    this.leafletMap.fitBounds(coords, { padding: [20, 20] })
  }
}
