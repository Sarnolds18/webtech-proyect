import { Controller } from "@hotwired/stimulus"

// Search without reloading: every change of the filters asks the public JSON API (/api/v1/listings)
// with fetch and redraws the cards. Without JavaScript the form still works as a normal GET.
export default class extends Controller {
  static targets = ["form", "section", "results", "count", "error", "empty", "more", "template"]
  static values = { url: String }

  static PER_PAGE = "12"

  connect() {
    this.nextUrl = null
    this.lastQuery = this.query().toString()
    this.clp = new Intl.NumberFormat("es-CL", { style: "currency", currency: "CLP", maximumFractionDigits: 0 })
    this.dates = new Intl.DateTimeFormat("en-US", { month: "long", day: "numeric", year: "numeric", timeZone: "UTC" })
  }

  disconnect() {
    clearTimeout(this.timer)
    this.abort?.abort()
  }

  // Pressing Enter or the button searches right away, without the browser leaving the page.
  submit(event) {
    event.preventDefault()
    clearTimeout(this.timer)
    this.fetchPage(this.apiUrl(), { append: false })
  }

  // Debounced so typing a rent does not send one request per key. `input` and `change` both fire
  // for the same edit, so a search with the same filters as the last one is skipped.
  search() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => {
      if (this.query().toString() === this.lastQuery) return
      this.fetchPage(this.apiUrl(), { append: false })
    }, 300)
  }

  loadMore() {
    if (this.nextUrl) this.fetchPage(this.nextUrl, { append: true })
  }

  apiUrl() {
    const query = this.query()
    query.set("per_page", this.constructor.PER_PAGE)
    return `${this.urlValue}?${query}`
  }

  // The filled-in form fields. The form calls the date `available_from`; the API calls it `available_by`.
  query({ forApi = true } = {}) {
    const query = new URLSearchParams()
    for (const [name, value] of new FormData(this.formTarget)) {
      if (!value) continue
      query.append(forApi && name === "available_from" ? "available_by" : name, value)
    }
    return query
  }

  async fetchPage(url, { append }) {
    this.abort?.abort()
    this.abort = new AbortController()
    this.sectionTarget.setAttribute("aria-busy", "true")
    this.moreTarget.disabled = true

    try {
      const response = await fetch(url, { headers: { Accept: "application/json" }, signal: this.abort.signal })
      const body = await response.json().catch(() => ({}))
      if (!response.ok) throw new Error(body.error?.message || "The search failed. Please try again.")

      this.render(body, { append })
      if (!append) {
        this.lastQuery = this.query().toString()
        const pageQuery = this.query({ forApi: false }).toString()
        history.replaceState(history.state, "", pageQuery ? `${location.pathname}?${pageQuery}` : location.pathname)
      }
    } catch (error) {
      if (error.name === "AbortError") return
      this.errorTarget.textContent = error.message === "Failed to fetch" ? "The search failed. Check your connection." : error.message
      this.errorTarget.classList.remove("d-none")
    } finally {
      this.sectionTarget.removeAttribute("aria-busy")
      this.moreTarget.disabled = false
    }
  }

  render({ data, meta, links }, { append }) {
    this.errorTarget.classList.add("d-none")
    if (!append) this.resultsTarget.replaceChildren()
    this.resultsTarget.append(...data.map((listing) => this.card(listing)))

    this.countTarget.textContent = `${meta.total} ${meta.total === 1 ? "room" : "rooms"} found`
    this.emptyTarget.classList.toggle("d-none", meta.total > 0)
    this.nextUrl = links.next
    this.moreTarget.classList.toggle("d-none", !links.next)
  }

  // textContent only, never innerHTML: titles and names are written by users.
  card(listing) {
    const card = this.templateTarget.content.cloneNode(true)
    const field = (name) => card.querySelector(`[data-field="${name}"]`)

    field("neighborhood").textContent = listing.neighborhood.name
    field("rent").textContent = this.clp.format(listing.monthly_rent)
    field("title").textContent = listing.title
    field("title").href = listing.links.html
    field("property").textContent = listing.property.title
    field("available").textContent = this.dates.format(new Date(listing.available_from))

    const photo = field("photo")
    const alt = `Room in ${listing.neighborhood.name}`
    if (listing.cover_photo_url) {
      photo.src = listing.cover_photo_url
      photo.alt = alt
    } else {
      photo.replaceWith(this.placeholder(alt))
    }
    return card
  }

  placeholder(alt) {
    const div = document.createElement("div")
    div.className = "card-img-top listing-photo-placeholder d-flex align-items-center justify-content-center"
    div.setAttribute("role", "img")
    div.setAttribute("aria-label", `${alt}: no photographs yet`)
    const icon = document.createElement("i")
    icon.className = "bi bi-image fs-1"
    icon.setAttribute("aria-hidden", "true")
    div.append(icon)
    return div
  }
}
