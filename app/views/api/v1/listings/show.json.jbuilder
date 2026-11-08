json.data do
  json.partial! "api/v1/listings/listing", listing: @listing, ratings: @ratings
  # Plain text: the API does not send HTML. The listing page renders the formatted version.
  json.description @listing.description.to_plain_text
  json.house_rules @listing.house_rules.to_plain_text
  json.photos @listing.photos do |photo|
    json.card_url rails_representation_url(photo.variant(:card))
    json.large_url rails_representation_url(photo.variant(:large))
  end
end
