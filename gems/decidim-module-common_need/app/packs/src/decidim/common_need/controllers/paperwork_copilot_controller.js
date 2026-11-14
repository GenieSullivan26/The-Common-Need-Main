import { Controller } from "@hotwired/stimulus"

export const PAPERWORK_TEMPLATES = [
  "Social Services: CalFresh / SNAP, Medi-Cal & LIHEAP Packet",
  "Legal Aid: Eviction Defense & Record Expungement Intake",
  "Housing: Emergency Rent Relief & Habitability Packet",
  "Public Sector: Municipal ID & Paratransit Fee Waiver",
  "Veteran Services: VA Disability Claim & DD-214 Support Packet"
]

export default class extends Controller {
  static targets = [
    "chatLog",
    "userInput",
    "templateSelect",
    "householdInput",
    "languageInput",
    "situationInput",
    "previewText"
  ]

  static values = {
    nodeCode: { type: String, default: "#OAK-01" },
    chatEndpoint: { type: String, default: "/member/ai_assistant/chat" },
    paperworkEndpoint: { type: String, default: "/member/ai_assistant/paperwork" }
  }

  sendQuickPrompt(event) {
    const promptText = event.currentTarget.dataset.prompt || event.currentTarget.textContent
    if (this.hasUserInputTarget) {
      this.userInputTarget.value = promptText
    }
    this.sendMessage()
  }

  openPaperworkFor(event) {
    const formTitle = event.currentTarget.dataset.paperworkTitle || PAPERWORK_TEMPLATES[0]
    if (typeof window.switchMemberTab === "function") {
      window.switchMemberTab(5)
    }

    if (this.hasTemplateSelectTarget) {
      const keyword = formTitle.split(" ")[0].toLowerCase()
      for (let i = 0; i < this.templateSelectTarget.options.length; i += 1) {
        if (this.templateSelectTarget.options[i].value.toLowerCase().includes(keyword)) {
          this.templateSelectTarget.selectedIndex = i
          break
        }
      }
      this.updatePreview()
    }

    if (this.hasUserInputTarget) {
      this.userInputTarget.value = `Help me complete the ${formTitle} on our local server`
      this.sendMessage()
    }
  }

  sendMessage(event) {
    if (event) event.preventDefault()
    if (!this.hasUserInputTarget || !this.hasChatLogTarget) return

    const userText = (this.userInputTarget.value || "").trim()
    if (!userText) return

    const userBubble = document.createElement("div")
    userBubble.style.cssText =
      "align-self:flex-end; background:var(--olive-badge); border:1px solid var(--olive-border); border-radius:12px; padding:8px 10px; font-size:12px; max-width:88%;"
    userBubble.innerHTML = `<div style="font-family:monospace; font-size:9.5px; color:var(--lime-bright);">YOU (MEMBER)</div>${this.escapeHtml(userText)}`
    this.chatLogTarget.appendChild(userBubble)

    const aiBubble = document.createElement("div")
    aiBubble.style.cssText =
      "background:var(--bg-outer); border:1px solid var(--lime-bright); border-radius:12px; padding:10px; font-size:12px; line-height:1.45;"
    aiBubble.innerHTML = `
      <div style="font-family:monospace; font-size:10px; color:var(--lime-bright); font-weight:700; margin-bottom:4px;">
        🤖 ${this.nodeCodeValue} LOCAL SERVER AI • 19-CATEGORY MATCH
      </div>
      ${this.buildLocalReplyHtml(userText)}
    `
    this.chatLogTarget.appendChild(aiBubble)
    this.chatLogTarget.scrollTop = this.chatLogTarget.scrollHeight
    this.userInputTarget.value = ""
  }

  updatePreview() {
    if (!this.hasPreviewTextTarget) return

    const formName = this.hasTemplateSelectTarget
      ? this.templateSelectTarget.value
      : PAPERWORK_TEMPLATES[0]
    const hh = this.hasHouseholdInputTarget
      ? this.householdInputTarget.value || "Household Size: 3"
      : "Household Size: 3"
    const lang = this.hasLanguageInputTarget
      ? this.languageInputTarget.value || "Language: English"
      : "Language: English"
    const sit = this.hasSituationInputTarget
      ? this.situationInputTarget.value || "Standard expedited filing"
      : "Standard expedited filing"

    this.previewTextTarget.innerHTML = `
      • Form: <strong>${this.escapeHtml(formName)}</strong><br>
      • Local Vault: 1400 Block of 62nd Ave (${this.escapeHtml(hh)} • ${this.escapeHtml(lang)})<br>
      • Notes: ${this.escapeHtml(sit)}<br>
      • Privacy: Encrypted on ${this.nodeCodeValue} Local Server (0 Bytes sent externally) ✓
    `
  }

  completePaperwork(event) {
    const mode = event.currentTarget.dataset.deliveryMode || "pdf"
    const formName = this.hasTemplateSelectTarget
      ? this.templateSelectTarget.value
      : PAPERWORK_TEMPLATES[0]

    if (mode === "pdf") {
      if (typeof window.showToast === "function") {
        window.showToast(`Generated encrypted PDF for "${formName}" in your local ${this.nodeCodeValue} vault!`)
      }
    } else if (typeof window.addItemToBasket === "function") {
      window.addItemToBasket(null, formName, "Paperwork Co-Pilot • Fruitvale Hub")
    }
  }

  buildLocalReplyHtml(userText) {
    const lower = userText.toLowerCase()
    if (lower.includes("veteran") || lower.includes("va ") || lower.includes("calfresh") || lower.includes("social")) {
      return `
        Matched in <strong>Social services & Veteran services</strong> at Fruitvale Resource Hub:
        <br>• Pre-filled <strong>CalFresh/Medi-Cal/LIHEAP</strong> and <strong>VA Disability Claim / DD-214</strong> packets in the local Paperwork Co-Pilot below.
        <br>• <button class="olive-badge" style="margin-top:6px; cursor:pointer;" onclick="addItemToBasket(this, 'Veteran & Social Services Care Packet', 'Veteran & Social Services')">+ Add Printed Packet & Veteran Care Tote</button>
      `
    }
    if (lower.includes("legal") || lower.includes("housing") || lower.includes("public sector") || lower.includes("eviction")) {
      return `
        Matched in <strong>Legal aid, Housing & Public sector</strong>:
        <br>• <strong>Eviction Defense & Expungement Clinic</strong> + <strong>Emergency Rent Relief & Weatherization Kit</strong> + <strong>Municipal ID / Paratransit Waiver</strong>.
        <br>• <button class="olive-badge" style="margin-top:6px; cursor:pointer;" onclick="addItemToBasket(this, 'Legal Aid, Housing Weatherization & Municipal ID Packet', 'Legal & Housing Hub')">+ Add Housing Kit & Legal Packet</button>
      `
    }
    if (lower.includes("mental") || lower.includes("medical") || lower.includes("youth") || lower.includes("art")) {
      return `
        Matched across <strong>Mental health, Medical, Youth services & Arts</strong>:
        <br>• <strong>Bilingual Peer Counseling & Weighted Grounding Kit</strong>
        <br>• <strong>Folding Mobility Walker & BP Cuff</strong>
        <br>• <strong>Youth STEM/Diaper Pack & Studio Art Box</strong>
        <br>• <button class="olive-badge" style="margin-top:6px; cursor:pointer;" onclick="addItemToBasket(this, 'Holistic Health, Youth & Arts Bundle', 'Multi-Hub Care Share')">+ Add Matched Care Bundle</button>
      `
    }
    return `
      Matched across <strong>Food, Garden, Pets, Co-ops & Mutual Aid</strong>:
      <br>• <strong>Organic Collard Greens & 25lb Grain Box</strong> (Food)
      <br>• <strong>Urban Garden Seed/Starts & 20lb Pet Kibble</strong> (Garden & Pets)
      <br>• <strong>Worker Co-op Sourdough & Mutual Aid Solar Lantern Kit</strong>
      <br>• <button class="olive-badge" style="margin-top:6px; cursor:pointer;" onclick="addItemToBasket(this, 'Food, Garden, Pet & Co-op Solidarity Bundle', 'East Oakland Commons')">+ Add Matched Items to Care Basket</button>
    `
  }

  escapeHtml(str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }
}
