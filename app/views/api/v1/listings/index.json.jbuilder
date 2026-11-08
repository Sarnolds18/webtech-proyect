json.data @listings, partial: "api/v1/listings/listing", as: :listing, ratings: @ratings
json.meta do
  json.page @page
  json.per_page @per_page
  json.total @total
  json.total_pages (@total.to_f / @per_page).ceil
end
json.links do
  query = request.query_parameters
  json.self api_v1_listings_url(query)
  json.next(@page * @per_page < @total ? api_v1_listings_url(query.merge(page: @page + 1)) : nil)
  json.prev(@page > 1 ? api_v1_listings_url(query.merge(page: @page - 1)) : nil)
end
