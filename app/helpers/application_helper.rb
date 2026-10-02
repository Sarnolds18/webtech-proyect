module ApplicationHelper
  # Navbar link that marks itself as the current section, on the index page and on every page below it.
  def nav_link_to(name, path)
    active = current_page?(path) || request.path.start_with?("#{path}/")

    link_to name, path, class: class_names("nav-link", active: active), aria: { current: ("page" if active) }
  end
end
