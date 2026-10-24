# Rails wraps every field with errors in <div class="field_with_errors">, which breaks Bootstrap's
# form layout. Instead, mark the input itself with Bootstrap's `is-invalid` class and leave labels
# untouched; the message is printed next to the field by `field_error` (see FormErrorsHelper).
ActionView::Base.field_error_proc = proc do |html_tag, _instance|
  fragment = Nokogiri::HTML5::DocumentFragment.parse(html_tag)
  field = fragment.at_css("input:not([type=hidden]), select, textarea")

  if field
    field["class"] = [ field["class"], "is-invalid" ].compact.join(" ")
    fragment.to_html.html_safe
  else
    html_tag
  end
end
