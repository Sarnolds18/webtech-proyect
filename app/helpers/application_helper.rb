module ApplicationHelper
  # Listings have no photographs yet, so each one borrows one of the landing page pictures.
  PLACEHOLDER_PHOTOS = %w[nunoa.jpg providencia.jpg las_condes.jpg].freeze

  # Bootstrap color for each state of a listing, an application or a visit.
  STATUS_COLORS = {
    "draft" => "secondary", "published" => "success", "reserved" => "warning", "rented" => "info",
    "pending" => "secondary", "shortlisted" => "primary", "accepted" => "success", "rejected" => "danger",
    "proposed" => "secondary", "confirmed" => "primary", "completed" => "success", "cancelled" => "danger",
    "withdrawn" => "dark"
  }.freeze

  # Navbar link that marks itself as the current section, on the index page and on every page below it.
  def nav_link_to(name, path)
    active = current_page?(path) || request.path.start_with?("#{path}/")

    link_to name, path, class: class_names("nav-link", active: active), aria: { current: ("page" if active) }
  end

  # Chilean pesos: thousands separated by dots and no decimals, e.g. $320.000.
  def money(amount)
    number_to_currency(amount, unit: "$", precision: 0, delimiter: ".", format: "%u%n")
  end

  def listing_photo(listing)
    PLACEHOLDER_PHOTOS[listing.id % PLACEHOLDER_PHOTOS.size]
  end

  def status_badge(status)
    tag.span status.humanize, class: "badge text-bg-#{STATUS_COLORS.fetch(status.to_s, "secondary")}"
  end

  def yes_no(flag)
    icon = flag ? "bi-check-circle-fill text-success" : "bi-x-circle text-secondary"

    safe_join([ tag.i(class: "bi #{icon} me-1", aria: { hidden: true }), flag ? "Yes" : "No" ])
  end
end
