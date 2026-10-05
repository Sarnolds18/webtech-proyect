ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # The sample data is built with `create!` instead of YAML fixtures: fixtures load in alphabetical
    # order (applications before listings), which only works when the PostgreSQL role is a superuser.
    setup :create_scenario

    # A small Providencia/Ñuñoa scenario: one host with two properties, two published listings and a
    # draft, a pending application with an upcoming visit, and a shortlisted one with a completed,
    # reviewed visit.
    def create_scenario
      @records = Hash.new { |hash, model| hash[model] = {} }

      password = "password123"
      users = @records[:users]
      users[:host] = User.create!(name: "Valentina Soto", email_address: "valentina.soto@roomies.test", password:)
      users[:seeker] = User.create!(name: "Sofía Araya", email_address: "sofia.araya@roomies.test", password:)
      users[:other_seeker] = User.create!(name: "Benjamín Vera", email_address: "benjamin.vera@roomies.test", password:)
      users[:moderator] = User.create!(name: "Camila Rojas", email_address: "camila.rojas@roomies.test", password:,
                                       role: :moderator)

      neighborhoods = @records[:neighborhoods]
      neighborhoods[:providencia] = Neighborhood.create!(name: "Providencia", city: "Santiago")
      neighborhoods[:nunoa] = Neighborhood.create!(name: "Ñuñoa", city: "Santiago")

      amenities = @records[:amenities]
      amenities[:wifi] = Amenity.create!(name: "WiFi", icon: "bi-wifi")
      amenities[:washer] = Amenity.create!(name: "Washing machine", icon: "bi-water")

      properties = @records[:properties]
      properties[:flat] = Property.create!(
        host: users[:host], neighborhood: neighborhoods[:providencia], title: "Bright flat near Metro Los Leones",
        address: "Av. Providencia 2133, depto 504", property_type: :apartment, bedrooms: 3, bathrooms: 2,
        amenities: [ amenities[:wifi] ]
      )
      properties[:house] = Property.create!(
        host: users[:host], neighborhood: neighborhoods[:nunoa], title: "Garden house in Plaza Ñuñoa",
        address: "Jorge Washington 120", property_type: :house, bedrooms: 4, bathrooms: 2
      )

      listings = @records[:listings]
      listings[:cheap] = Listing.create!(
        property: properties[:flat], title: "Cozy room in Providencia", status: :published,
        monthly_rent: 250_000, deposit: 250_000, available_from: 10.days.from_now.to_date, minimum_stay_months: 6
      )
      listings[:pricey] = Listing.create!(
        property: properties[:house], title: "Large room with private bathroom", status: :published,
        monthly_rent: 400_000, deposit: 400_000, available_from: 40.days.from_now.to_date, minimum_stay_months: 12,
        private_bathroom: true
      )
      listings[:draft] = Listing.create!(
        property: properties[:flat], title: "Small room, still being written",
        monthly_rent: 200_000, deposit: 0, available_from: 5.days.from_now.to_date
      )

      applications = @records[:applications]
      applications[:pending] = Application.create!(
        listing: listings[:cheap], seeker: users[:seeker], created_at: 10.days.ago,
        message: "Hi! I study at the university nearby and I am very tidy.",
        move_in_date: 15.days.from_now.to_date, stay_months: 6
      )
      applications[:shortlisted] = Application.create!(
        listing: listings[:pricey], seeker: users[:seeker], status: :shortlisted, created_at: 20.days.ago,
        message: "I work remotely and I would love a room with a private bathroom.",
        move_in_date: 45.days.from_now.to_date, stay_months: 12
      )

      visits = @records[:visits]
      visits[:completed] = applications[:shortlisted].visits.create!(scheduled_at: 10.days.ago, status: :completed)
      visits[:proposed] = applications[:pending].visits.create!(scheduled_at: 3.days.from_now)

      @records[:reviews][:house_review] = Review.create!(
        visit: visits[:completed], author: users[:seeker], rating: 4, comment: "Lovely garden and a very kind host."
      )
    end

    # Fixture-style accessors, e.g. `listings(:cheap)` or `users(:host)`.
    %i[users neighborhoods amenities properties listings applications visits reviews].each do |model|
      define_method(model) { |name| @records[model].fetch(name) }
    end
  end
end
