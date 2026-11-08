json.id listing.id
json.title listing.title
json.status listing.status
json.monthly_rent listing.monthly_rent
json.deposit listing.deposit
json.currency "CLP"
json.available_from listing.available_from
json.minimum_stay_months listing.minimum_stay_months
json.furnished listing.furnished
json.private_bathroom listing.private_bathroom
json.neighborhood do
  json.extract! listing.property.neighborhood, :id, :name, :city
end
# The property without its address or its host: no personal data in the public API.
json.property do
  json.extract! listing.property, :id, :title, :property_type, :bedrooms, :bathrooms
  json.amenities listing.property.amenities, :id, :name, :icon
end
# Only the average and the count: review authors are not exposed.
json.rating ratings.fetch(listing.property_id)
json.cover_photo_url(listing.photos.attached? ? rails_representation_url(listing.photos.first.variant(:card)) : nil)
json.links do
  json.self api_v1_listing_url(listing)
  json.html listing_url(listing)
end
