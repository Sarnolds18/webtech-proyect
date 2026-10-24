require "test_helper"

class FormErrorsHelperTest < ActionView::TestCase
  test "fields with errors get Bootstrap's is-invalid class instead of a wrapper div" do
    listing = Listing.new(monthly_rent: 0)
    listing.validate

    html = form_with(model: listing, url: "/listings") { |form| form.number_field :monthly_rent, class: "form-control" }

    assert_includes html, 'class="form-control is-invalid"'
    assert_not_includes html, "field_with_errors"
  end

  test "field_error prints the attribute's messages below the field" do
    listing = Listing.new(monthly_rent: 0)
    listing.validate

    assert_dom_equal %(<div class="invalid-feedback d-block" id="monthly_rent_error">Monthly rent must be greater than 0</div>),
                     field_error(listing, :monthly_rent)
  end

  test "field_error prints nothing for a valid attribute" do
    listing = Listing.new(title: "Room")
    listing.validate

    assert_nil field_error(listing, :title)
  end
end
