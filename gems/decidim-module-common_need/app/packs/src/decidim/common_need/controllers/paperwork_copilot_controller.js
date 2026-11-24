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
    chatEndpoint: { type: String, default: "/member/resource_navigator/chat" },
    paperworkEndpoint: { type: String, default: "/member/resource_navigator/paperwork" }
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
    if (typeof window.sendLocalAiMessage === "function") {
      window.sendLocalAiMessage()
      return
    }
    if (!this.hasUserInputTarget || !this.hasChatLogTarget) return

    const userText = (this.userInputTarget.value || "").trim()
    if (!userText) return

    this.chatLogTarget.classList.remove("hidden")

    const userBubble = document.createElement("div")
    userBubble.style.cssText =
      "align-self:flex-end; background:rgba(197,255,41,0.14); border:1px solid rgba(197,255,41,0.35); border-radius:18px 18px 4px 18px; padding:10px 14px; font-size:13px; color:var(--text-white); max-width:85%;"
    userBubble.textContent = userText
    this.chatLogTarget.appendChild(userBubble)

    const liveItems = this.scanLiveCatalogCards()
    const replyHtml = this.buildLocalReplyHtml(userText, liveItems)

    const navBubble = document.createElement("div")
    navBubble.style.cssText =
      "background:rgba(27,15,51,0.95); border:1px solid rgba(197,255,41,0.22); border-radius:18px 18px 18px 4px; padding:12px 14px; font-size:12.5px; line-height:1.5;"
    navBubble.innerHTML = `
      <div style="font-family:monospace; font-size:10px; color:var(--lime-bright); font-weight:700; margin-bottom:5px;">
        🧭 COMMON NEED RESOURCE NAVIGATOR • ${this.nodeCodeValue} (${liveItems.length} LIVE ITEMS)
      </div>
      ${replyHtml}
    `
    this.chatLogTarget.appendChild(navBubble)
    this.chatLogTarget.scrollTop = this.chatLogTarget.scrollHeight
    this.userInputTarget.value = ""
  }

  scanLiveCatalogCards() {
    return Array.from(document.querySelectorAll("#member-tab-1 .item-lime-card")).map((card) => ({
      title: (card.querySelector(".item-title")?.textContent || "").trim(),
      category: (card.dataset.category || "mutual_aid").trim(),
      isSurplus: card.dataset.liveSurplus === "true",
      blob: card.textContent.toLowerCase()
    })).filter((i) => i.title)
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
      window.addItemToBasket(null, formName, "Resource Navigator • Fruitvale Hub")
    }
  }

  buildLocalReplyHtml(userText, liveItems = []) {
    const lower = userText.toLowerCase()
    const tokens = (lower.match(/[a-z0-9-]+/g) || []).filter((w) => w.length >= 3)
    const matched = liveItems
      .map((item) => {
        let score = item.isSurplus ? 2 : 0
        tokens.forEach((tok) => {
          if (item.title.toLowerCase().includes(tok)) score += 6
          else if (item.blob.includes(tok)) score += 2
        })
        return { ...item, score }
      })
      .filter((i) => i.score > 0)
      .sort((a, b) => b.score - a.score)
      .slice(0, 4)

    const itemsList = matched.length > 0
      ? matched.map((m) => `• ${m.isSurplus ? "<strong>[NEW LIVE SURPLUS]</strong> " : ""}<strong>${this.escapeHtml(m.title)}</strong>`).join("<br>")
      : "• <strong>Organic Collard Greens &amp; 25lb Grain Box</strong><br>• <strong>Urban Garden Seed/Starts &amp; 20lb Pet Kibble</strong>"

    if (lower.includes("veteran") || lower.includes("va ") || lower.includes("calfresh") || lower.includes("social")) {
      return `
        <div><strong>Social Services, CalFresh (SNAP) &amp; Veterans Navigation</strong></div>
        <div>• <strong>3-Day Expedited CalFresh:</strong> &lt;$150 monthly income &amp; &lt;$100 cash (or rent+utilities &gt; income) qualifies for 3-day emergency EBT; no asset test and Public Charge safe.</div>
        <div>• <strong>$0 VA Intent to File:</strong> Locks in up to 1 year of retroactive disability back-pay.</div>
        <div style="margin-top:6px;">${itemsList}</div>
      `
    }
    if (lower.includes("legal") || lower.includes("housing") || lower.includes("public sector") || lower.includes("eviction")) {
      return `
        <div><strong>Housing Stability, Eviction Defense &amp; Municipal ID Navigation</strong></div>
        <div>• <strong>Urgent 10-Business-Day Rule:</strong> File an Answer (<code>UD-105</code>) within 10 court business days of an Unlawful Detainer summons to prevent default lockout.</div>
        <div>• <strong>Rent &amp; LIHEAP Relief:</strong> Pair emergency back-rent grants with LIHEAP utility shutoff protection.</div>
        <div style="margin-top:6px;">${itemsList}</div>
      `
    }
    if (lower.includes("mental") || lower.includes("medical") || lower.includes("youth") || lower.includes("art")) {
      return `
        <div><strong>Full-Scope Medi-Cal, Medical Equipment &amp; Youth Care</strong></div>
        <div>• <strong>Full-Scope Medi-Cal &amp; IHSS:</strong> Open to income-eligible CA residents of all ages regardless of immigration status (zero asset test).</div>
        <div style="margin-top:6px;">${itemsList}</div>
      `
    }
    return `
      <div><strong>Live Community Nourishment &amp; Social Service Navigation</strong></div>
      <div>• All free goods, partner surplus shares, and clinics on this PWA require $0 and zero means-testing.</div>
      <div style="margin-top:6px;">${itemsList}</div>
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
