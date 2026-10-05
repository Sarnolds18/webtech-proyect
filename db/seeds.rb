# Sample data for Roomies. Populates all 13 tables with a realistic Santiago, Chile scenario.
#
# Safe to re-run: it wipes every table first, so running it twice leaves the same data.
# All users share the password "password123" (see README for the list of emails).
#
#   bin/rails db:seed

puts "Cleaning database..."

# Delete in reverse dependency order because of the foreign keys.
[
  ModerationAction, Report, SavedListing, ReviewReply, Review, Visit, Application, Listing,
  PropertyAmenity, Property, Amenity, Neighborhood, User
].each(&:delete_all)

# --- Neighborhoods ---------------------------------------------------------------------------

puts "Seeding neighborhoods..."

providencia    = Neighborhood.create!(name: "Providencia", city: "Santiago")
nunoa          = Neighborhood.create!(name: "Ñuñoa", city: "Santiago")
las_condes     = Neighborhood.create!(name: "Las Condes", city: "Santiago")
centro         = Neighborhood.create!(name: "Santiago Centro", city: "Santiago")
vitacura       = Neighborhood.create!(name: "Vitacura", city: "Santiago")
la_reina       = Neighborhood.create!(name: "La Reina", city: "Santiago")
macul          = Neighborhood.create!(name: "Macul", city: "Santiago")
san_miguel     = Neighborhood.create!(name: "San Miguel", city: "Santiago")
# Deactivated by a moderator: kept in the catalog but no longer offered.
Neighborhood.create!(name: "Lo Barnechea", city: "Santiago", active: false)

# --- Amenities -------------------------------------------------------------------------------

puts "Seeding amenities..."

wifi     = Amenity.create!(name: "WiFi", icon: "bi-wifi")
washer   = Amenity.create!(name: "Washing machine", icon: "bi-water")
dryer    = Amenity.create!(name: "Dryer", icon: "bi-wind")
kitchen  = Amenity.create!(name: "Full kitchen", icon: "bi-egg-fried")
balcony  = Amenity.create!(name: "Balcony", icon: "bi-building")
heating  = Amenity.create!(name: "Heating", icon: "bi-thermometer-sun")
ac       = Amenity.create!(name: "Air conditioning", icon: "bi-snow")
parking  = Amenity.create!(name: "Parking", icon: "bi-car-front")
pets     = Amenity.create!(name: "Pets allowed", icon: "bi-heart")
bikes    = Amenity.create!(name: "Bike storage", icon: "bi-bicycle")
elevator = Amenity.create!(name: "Elevator", icon: "bi-arrow-up-square")
# Deactivated amenity: exists in the catalog but is not used by any property.
Amenity.create!(name: "Swimming pool", icon: "bi-droplet", active: false)

# --- Users -----------------------------------------------------------------------------------

puts "Seeding users..."

PASSWORD = "password123".freeze

# Moderators
camila = User.create!(
  name: "Camila Rojas", email_address: "camila.rojas@roomies.test", password: PASSWORD, role: :moderator,
  phone: "+56 9 5550 1001", bio: "Community moderator. I keep Roomies safe and the listings honest."
)
tomas = User.create!(
  name: "Tomás Fuentes", email_address: "tomas.fuentes@roomies.test", password: PASSWORD, role: :moderator,
  phone: "+56 9 5550 1002", bio: "Moderator and former housemate. I review reports every morning."
)

# Hosts (they also act as seekers when they apply to somebody else's room)
valentina = User.create!(
  name: "Valentina Soto", email_address: "valentina.soto@roomies.test", password: PASSWORD,
  phone: "+56 9 5550 2001", bio: "Architect who loves sharing a home. I rent rooms in Providencia and Macul."
)
matias = User.create!(
  name: "Matías Pérez", email_address: "matias.perez@roomies.test", password: PASSWORD,
  phone: "+56 9 5550 2002", bio: "Software engineer and plant lover. I host in Ñuñoa and La Reina."
)
javiera = User.create!(
  name: "Javiera Muñoz", email_address: "javiera.munoz@roomies.test", password: PASSWORD,
  phone: "+56 9 5550 2003", bio: "I rent a room in my Las Condes flat, and I am also looking for a place near the Andes."
)
diego = User.create!(
  name: "Diego Contreras", email_address: "diego.contreras@roomies.test", password: PASSWORD,
  phone: "+56 9 5550 2004", bio: "Teacher living downtown. Quiet, tidy and always up for a barbecue."
)

# Seekers
sofia = User.create!(
  name: "Sofía Araya", email_address: "sofia.araya@roomies.test", password: PASSWORD,
  phone: "+56 9 5550 3001", bio: "Master's student in economics. Early riser, no smoking, loves cooking."
)
benjamin = User.create!(
  name: "Benjamín Vera", email_address: "benjamin.vera@roomies.test", password: PASSWORD,
  phone: "+56 9 5550 3002", bio: "Junior developer moving to Santiago for my first job."
)
francisca = User.create!(
  name: "Francisca Lagos", email_address: "francisca.lagos@roomies.test", password: PASSWORD,
  phone: "+56 9 5550 3003", bio: "Exchange student from Valparaíso. I play the cello, with headphones on."
)
nicolas = User.create!(
  name: "Nicolás Herrera", email_address: "nicolas.herrera@roomies.test", password: PASSWORD,
  phone: "+56 9 5550 3004", bio: "Nurse working night shifts at Clínica Alemana."
)
isidora = User.create!(
  name: "Isidora Campos", email_address: "isidora.campos@roomies.test", password: PASSWORD,
  phone: "+56 9 5550 3005", bio: "Graphic designer, remote worker, and owner of one very calm cat."
)

# Suspended account (the moderators suspended it after a fraud report)
martin = User.create!(
  name: "Martín Silva", email_address: "martin.silva@roomies.test", password: PASSWORD, status: :suspended,
  phone: "+56 9 5550 4001"
)

# --- Properties ------------------------------------------------------------------------------

puts "Seeding properties and their amenities..."

p1 = Property.create!(
  host: valentina, neighborhood: providencia, property_type: :apartment, bedrooms: 3, bathrooms: 2,
  title: "Bright apartment near Metro Pedro de Valdivia",
  address: "Av. Providencia 2133, Providencia",
  shared_spaces: "Living room, dining room, full kitchen and a sunny balcony.",
  description: "Third-floor apartment, two blocks from the metro and the Costanera bike path. " \
               "Two of us live here and we share the common areas. Building has 24/7 concierge."
)
p1.amenities << [ wifi, washer, kitchen, balcony, elevator, heating ]

p2 = Property.create!(
  host: matias, neighborhood: nunoa, property_type: :house, bedrooms: 4, bathrooms: 2,
  title: "Garden house in Plaza Ñuñoa",
  address: "Av. Irarrázaval 3150, Ñuñoa",
  shared_spaces: "Living room, kitchen, backyard with grill, laundry room.",
  description: "Old family house with a big backyard, ten minutes on foot from Plaza Ñuñoa. " \
               "Friendly atmosphere, pets are welcome, and we do a house dinner every Sunday."
)
p2.amenities << [ wifi, washer, dryer, kitchen, heating, bikes, pets ]

p3 = Property.create!(
  host: javiera, neighborhood: las_condes, property_type: :apartment, bedrooms: 2, bathrooms: 1,
  title: "Modern flat in El Golf",
  address: "Av. Apoquindo 4500, Las Condes",
  shared_spaces: "Open living and dining room, kitchen.",
  description: "Modern flat with air conditioning in the middle of El Golf. " \
               "Walking distance from Metro Escuela Militar and plenty of cafés."
)
p3.amenities << [ wifi, ac, elevator, parking ]

p4 = Property.create!(
  host: diego, neighborhood: centro, property_type: :apartment, bedrooms: 2, bathrooms: 1,
  title: "Downtown flat by Parque Forestal",
  address: "Merced 350, Santiago Centro",
  shared_spaces: "Living room and kitchen.",
  description: "Classic downtown flat facing Parque Forestal and the Bellas Artes museum. " \
               "Walk to Cerro Santa Lucía, universities and three metro lines."
)
p4.amenities << [ wifi, kitchen, elevator ]

p5 = Property.create!(
  host: valentina, neighborhood: macul, property_type: :house, bedrooms: 3, bathrooms: 1,
  title: "Cozy house close to Campus San Joaquín",
  address: "Av. Macul 5100, Macul",
  shared_spaces: "Kitchen, living room, small garden with parking for two cars.",
  description: "Quiet house ten minutes from Campus San Joaquín. " \
               "Ideal for students: shared study room, fast internet and a very relaxed neighborhood."
)
p5.amenities << [ wifi, washer, kitchen, bikes, pets, parking ]

p6 = Property.create!(
  host: matias, neighborhood: la_reina, property_type: :house, bedrooms: 3, bathrooms: 2,
  title: "Family house with a view of the Andes",
  address: "Av. Larraín 7800, La Reina",
  shared_spaces: "Living room, kitchen, terrace and laundry area.",
  description: "Spacious house on the foothills with a terrace that looks onto the mountains. " \
               "Calm, green and safe; the bus to Metro Plaza Egaña stops at the corner."
)
p6.amenities << [ wifi, washer, dryer, kitchen, parking ]

# --- Listings --------------------------------------------------------------------------------

puts "Seeding listings..."

# Property 1 (Providencia): two open rooms and one already reserved.
l1a = Listing.create!(
  property: p1, status: :published, title: "Sunny room with private bathroom",
  description: "Large room with a south-facing window and its own bathroom. Furnished with a double bed, desk and wardrobe.",
  house_rules: "No smoking indoors. Quiet hours after 11 pm. Guests are welcome with advance notice.",
  monthly_rent: 380_000, deposit: 380_000, minimum_stay_months: 6,
  furnished: true, private_bathroom: true, available_from: Date.current + 12
)
l1b = Listing.create!(
  property: p1, status: :published, title: "Small room next to the metro",
  description: "Cozy single room, perfect for a student or someone who works long hours. Shares one bathroom with a housemate.",
  house_rules: "Clean up after cooking. No pets because one housemate is allergic.",
  monthly_rent: 260_000, deposit: 260_000, minimum_stay_months: 3,
  furnished: true, private_bathroom: false, available_from: Date.current + 30
)
l1c = Listing.create!(
  property: p1, status: :reserved, title: "Room with balcony access",
  description: "Medium room with direct access to the balcony. Already promised to the selected applicant.",
  house_rules: "No smoking. Share the cleaning of common areas every week.",
  monthly_rent: 320_000, deposit: 320_000, minimum_stay_months: 6,
  furnished: false, private_bathroom: false, available_from: Date.current + 20
)

# Property 2 (Ñuñoa): two open rooms (one with several applicants) and one already rented.
l2a = Listing.create!(
  property: p2, status: :published, title: "Large room with private bathroom",
  description: "The biggest room of the house, on the ground floor, with its own bathroom and a door to the garden. Unfurnished, so bring your own style.",
  house_rules: "Pets are welcome. Sunday dinner is optional but highly recommended. Quiet after midnight.",
  monthly_rent: 340_000, deposit: 340_000, minimum_stay_months: 6,
  furnished: false, private_bathroom: true, available_from: Date.current + 15
)
l2b = Listing.create!(
  property: p2, status: :published, title: "Budget room near Plaza Ñuñoa",
  description: "Simple and bright room in the second floor, shared bathroom with one housemate. Great for a short stay.",
  house_rules: "No smoking indoors. Keep shared spaces tidy.",
  monthly_rent: 210_000, deposit: 0, minimum_stay_months: 1,
  furnished: true, private_bathroom: false, available_from: Date.current + 5
)
l2c = Listing.create!(
  property: p2, status: :rented, title: "Garden-view room",
  description: "Quiet room overlooking the backyard. Taken by a new housemate who moved in recently.",
  house_rules: "No smoking indoors. Share the grocery staples.",
  monthly_rent: 280_000, deposit: 280_000, minimum_stay_months: 6,
  furnished: true, private_bathroom: false, available_from: Date.current + 10
)

# Property 3 (Las Condes)
l3 = Listing.create!(
  property: p3, status: :published, title: "Furnished room in El Golf",
  description: "Furnished room with air conditioning in a modern building with a gym on the ground floor. Ideal for professionals.",
  house_rules: "No parties. Guests can stay up to three nights a month.",
  monthly_rent: 450_000, deposit: 450_000, minimum_stay_months: 12,
  furnished: true, private_bathroom: false, available_from: Date.current + 40
)

# Property 4 (Santiago Centro): one draft and one withdrawn after a moderation action.
l4a = Listing.create!(
  property: p4, status: :draft, title: "Room facing Parque Forestal",
  description: "Draft: still need to add photos and fix the description.",
  house_rules: "To be defined.",
  monthly_rent: 230_000, deposit: 230_000, minimum_stay_months: 3,
  furnished: true, private_bathroom: false, available_from: Date.current + 60
)
l4b = Listing.create!(
  property: p4, status: :withdrawn, title: "Studio-style room downtown",
  description: "Promised a private studio with a full kitchen, but the pictures did not match the real room.",
  house_rules: "No restrictions.",
  monthly_rent: 180_000, deposit: 180_000, minimum_stay_months: 1,
  furnished: true, private_bathroom: true, available_from: Date.current + 7
)

# Property 5 (Macul)
l5a = Listing.create!(
  property: p5, status: :published, title: "Student room near Campus San Joaquín",
  description: "Furnished room with a desk and a shelf for your books. Fast internet and a quiet study room downstairs.",
  house_rules: "Quiet hours from 10 pm during exam season. No smoking.",
  monthly_rent: 220_000, deposit: 220_000, minimum_stay_months: 5,
  furnished: true, private_bathroom: false, available_from: Date.current + 18
)
l5b = Listing.create!(
  property: p5, status: :published, title: "Room with parking spot",
  description: "Unfurnished room with a dedicated parking spot in the front garden. Great if you commute by car.",
  house_rules: "Pets welcome with the host's approval. Keep the garden tidy.",
  monthly_rent: 240_000, deposit: 240_000, minimum_stay_months: 6,
  furnished: false, private_bathroom: false, available_from: Date.current + 25
)

# Property 6 (La Reina)
l6 = Listing.create!(
  property: p6, status: :published, title: "Room with Andes view in La Reina",
  description: "Spacious room with a terrace overlooking the mountains. Private bathroom and parking included.",
  house_rules: "No smoking. Respect quiet hours after 11 pm. Weekly cleaning rota.",
  monthly_rent: 400_000, deposit: 400_000, minimum_stay_months: 9,
  furnished: true, private_bathroom: true, available_from: Date.current + 45
)

# The model does not allow creating a listing whose `available_from` is in the past, but these
# listings were available some time ago (they already have a housemate or were taken down). So
# they are created with a future date and then moved back in time, skipping the validation.
l1c.update_columns(available_from: Date.current - 20)
l2c.update_columns(available_from: Date.current - 45)
l4b.update_columns(available_from: Date.current - 10)

# --- Applications ----------------------------------------------------------------------------

puts "Seeding applications..."

# Applications are created already in their final status (accepting one is app logic that comes
# later), with `created_at` in the past so that visits and reviews can be dated coherently.
apply = lambda do |listing, seeker, status, message:, days_ago:, stay: nil, move_in: nil|
  Application.create!(
    listing: listing, seeker: seeker, status: status, message: message,
    move_in_date: move_in || [ listing.available_from, Date.current ].max,
    stay_months: stay || listing.minimum_stay_months,
    created_at: days_ago.days.ago, updated_at: days_ago.days.ago
  )
end

# "Large room with private bathroom" (published): four applicants competing for the same room.
a_l2a_sofia = apply.call(
  l2a, sofia, :pending, days_ago: 6, stay: 10,
  message: "Hi Matías! I am a master's student at Universidad de Chile and your garden room looks perfect. " \
           "I am tidy, I cook a lot and I would love to join the Sunday dinners."
)
a_l2a_benjamin = apply.call(
  l2a, benjamin, :pending, days_ago: 5, stay: 12,
  message: "I just got a job in Santiago and need a stable place for a year. I work from the office, " \
           "so I would only be home in the evenings. I can send references from my last landlord."
)
a_l2a_francisca = apply.call(
  l2a, francisca, :shortlisted, days_ago: 9, stay: 6,
  message: "I am an exchange student and I am staying six months. I play the cello, always with headphones " \
           "or at the university. I would also love a place that accepts my small dog."
)
a_l2a_nicolas = apply.call(
  l2a, nicolas, :rejected, days_ago: 12, stay: 6,
  message: "I work night shifts as a nurse, so I sleep during the day. I am quiet, but I understand if " \
           "a room with a garden door is too noisy for that schedule."
)

# Another published listing with two applicants.
a_l1a_isidora = apply.call(
  l1a, isidora, :shortlisted, days_ago: 8, stay: 8,
  message: "I am a freelance designer working from home, so a bright room is very important to me. " \
           "I have one quiet cat; I can bring vaccination records if needed."
)
apply.call(
  l1a, nicolas, :pending, days_ago: 3, stay: 6,
  message: "Looking for a room near the metro because I have long shifts. I can pay the deposit " \
           "right away and I am available for a visit on any weekday afternoon."
)

# Reserved listing: one accepted applicant, everybody else rejected.
a_l1c_sofia = apply.call(
  l1c, sofia, :accepted, days_ago: 50, stay: 12, move_in: Date.current + 3,
  message: "I would love the room with the balcony: I need a calm place to study for my thesis. " \
           "I am organized, non-smoker and happy to share cleaning duties."
)
a_l1c_benjamin = apply.call(
  l1c, benjamin, :rejected, days_ago: 48, stay: 6, move_in: Date.current + 3,
  message: "I would like to rent this room for at least six months while I settle into my new job."
)
a_l1c_francisca = apply.call(
  l1c, francisca, :rejected, days_ago: 47, stay: 6, move_in: Date.current + 3,
  message: "Your apartment is close to my university and the metro. I am a quiet student and I travel " \
           "home to Valparaíso most weekends."
)

# Rented listing: the accepted housemate already moved in.
a_l2c_nicolas = apply.call(
  l2c, nicolas, :accepted, days_ago: 80, stay: 12, move_in: Date.current - 45,
  message: "I need a quiet room with a garden view to rest after my shifts. I am clean, respectful " \
           "and I can sign a one-year contract."
)
a_l2c_isidora = apply.call(
  l2c, isidora, :rejected, days_ago: 78, stay: 6, move_in: Date.current - 45,
  message: "The house looks lovely and my cat would be happy in the garden. I can move in the same week."
)

# Withdrawn listing: one applicant gave up, the other was rejected before the listing was taken down.
a_l4b_benjamin = apply.call(
  l4b, benjamin, :withdrawn, days_ago: 30, stay: 3, move_in: Date.current - 10,
  message: "The studio sounds like exactly what I need for my first months in the city."
)
a_l4b_francisca = apply.call(
  l4b, francisca, :rejected, days_ago: 29, stay: 2, move_in: Date.current - 10,
  message: "I would stay only two months during my exchange semester. Is the studio close to Bellas Artes?"
)

# A seeker who changed their mind about a published listing.
apply.call(
  l5a, isidora, :withdrawn, days_ago: 4,
  message: "Interested in the student room, although I am a designer, not a student. I work from home most days."
)

# Double role: Javiera is a host (Las Condes) and also applies to somebody else's room.
apply.call(
  l6, javiera, :pending, days_ago: 2, stay: 12,
  message: "I host a room in my own flat, but I am moving to La Reina for work. I know how shared living works " \
           "and I am a very considerate housemate."
)

# More competition on a cheaper room, plus an old rejected application from the now suspended user.
a_l2b_benjamin = apply.call(
  l2b, benjamin, :shortlisted, days_ago: 7, stay: 3,
  message: "I need a room for three months while I find a permanent place. I am flexible with the date."
)
apply.call(
  l3, martin, :rejected, days_ago: 90, stay: 12,
  message: "Professional looking for a long-term room in Las Condes. I can pay six months in advance."
)
apply.call(
  l5b, sofia, :pending, days_ago: 1, stay: 8,
  message: "I have a small car and this room with a parking spot would be perfect for my commute to campus."
)

# --- Visits ----------------------------------------------------------------------------------

puts "Seeding visits..."

# Past visits happen a few days after the application was created, so they always come after it.
past_visit = lambda do |application, status, days_after|
  Visit.create!(application: application, status: status, scheduled_at: application.created_at + days_after.days)
end

# Future visits, one per shortlisted application: proposed, rescheduled and confirmed.
Visit.create!(application: a_l1a_isidora, status: :proposed,
              scheduled_at: (Date.current + 2).in_time_zone.change(hour: 18))
past_visit.call(a_l2a_francisca, :cancelled, 3)
Visit.create!(application: a_l2a_francisca, status: :proposed,
              scheduled_at: (Date.current + 4).in_time_zone.change(hour: 11))
Visit.create!(application: a_l2b_benjamin, status: :confirmed,
              scheduled_at: (Date.current + 3).in_time_zone.change(hour: 17))

# Completed visits: the applicants of the reserved, rented and withdrawn listings who went to see the room.
v_l1c_sofia     = past_visit.call(a_l1c_sofia, :completed, 4)
v_l1c_benjamin  = past_visit.call(a_l1c_benjamin, :completed, 3)
past_visit.call(a_l1c_francisca, :completed, 5)
v_l2c_nicolas   = past_visit.call(a_l2c_nicolas, :completed, 5)
v_l2c_isidora   = past_visit.call(a_l2c_isidora, :completed, 4)
v_l4b_benjamin  = past_visit.call(a_l4b_benjamin, :completed, 2)
v_l4b_francisca = past_visit.call(a_l4b_francisca, :completed, 3)

# --- Reviews and host replies ----------------------------------------------------------------

puts "Seeding reviews and replies..."

# A review always comes from the seeker who made the (completed) visit, a day after it happened.
review = lambda do |visit, rating, comment|
  Review.create!(
    visit: visit, author: visit.application.seeker, rating: rating, comment: comment,
    created_at: visit.scheduled_at + 1.day, updated_at: visit.scheduled_at + 1.day
  )
end
reply = lambda do |review, comment|
  ReviewReply.create!(
    review: review, author: review.property.host, comment: comment,
    created_at: review.created_at + 1.day, updated_at: review.created_at + 1.day
  )
end

r_sofia = review.call(
  v_l1c_sofia, 5,
  "The apartment is exactly as described: bright, clean and a two-minute walk from the metro. " \
  "Valentina answered all my questions before the visit and the housemate was very friendly."
)
reply.call(r_sofia, "Thank you Sofía, it was a pleasure to meet you! Welcome to the flat.")

r_benjamin_p1 = review.call(
  v_l1c_benjamin, 2,
  "The apartment itself is nice, but the room was smaller than in the photos and the balcony is shared " \
  "with the neighbors. The street is also quite noisy at night."
)
reply.call(r_benjamin_p1, "Sorry the room was not what you expected, Benjamín. I will add the exact room size and a note about street noise to the next listings.")

r_nicolas = review.call(
  v_l2c_nicolas, 4,
  "Lovely house with a huge backyard and very relaxed people. The room is quiet during the day, " \
  "which is perfect for my night shifts. Only downside is that the bus stop is a bit far."
)
reply.call(r_nicolas, "Glad you like it, Nicolás! Plenty of housemates use bikes, so there is space for yours too.")

r_isidora = review.call(
  v_l2c_isidora, 5,
  "The house feels like a real home and Matías is a great host. I did not get the room, but I would " \
  "recommend the place to anyone looking in Ñuñoa."
)
reply.call(r_isidora, "Thanks for the kind words, Isidora! We will keep you in mind if another room opens up.")

review.call(
  v_l4b_francisca, 3,
  "Great location by Parque Forestal, but the room is small and the building is old. " \
  "It is okay for a short stay, although it was different from what the listing promised."
)

r_benjamin_p4 = review.call(
  v_l4b_benjamin, 2,
  "The listing promised a private studio with a full kitchen and a private bathroom. In reality, " \
  "it is a normal room and the bathroom is shared. I decided not to continue."
)
reply.call(r_benjamin_p4, "I am updating the description. The studio was a mistake in the title, and the listing has been withdrawn.")

# --- Saved listings --------------------------------------------------------------------------

puts "Seeding saved listings..."

{
  sofia => [ l1a, l2a, l6 ],
  benjamin => [ l2a, l5a, l4a ], # l4a is still a draft: saving an unpublished listing is allowed
  isidora => [ l1b, l3 ],
  nicolas => [ l1a, l2b ],
  javiera => [ l6, l5b ]
}.each do |user, listings|
  listings.each { |listing| SavedListing.create!(user: user, listing: listing) }
end

# --- Reports ---------------------------------------------------------------------------------

puts "Seeding reports..."

report_l4b_benjamin = Report.create!(
  listing: l4b, reporter: benjamin, reason: :fraudulent, status: :action_taken, created_at: 27.days.ago,
  details: "The listing promises a private studio with a full kitchen, but it is just a shared room. " \
           "I visited it and nothing matches the description."
)
Report.create!(
  listing: l4b, reporter: francisca, reason: :misleading, status: :action_taken, created_at: 26.days.ago,
  details: "Same problem as the other report: the pictures show a different room from the one on offer."
)
report_l3_nicolas = Report.create!(
  listing: l3, reporter: nicolas, reason: :misleading, status: :dismissed, created_at: 15.days.ago,
  details: "The title says furnished room but the description does not mention that it has no TV or desk."
)
Report.create!(
  listing: l6, reporter: sofia, reason: :offensive, status: :open, created_at: 2.days.ago,
  details: "One of the house rules is written in a rude way and discourages people with pets from applying."
)
Report.create!(
  listing: l2b, reporter: isidora, reason: :fraudulent, status: :open, created_at: 1.day.ago,
  details: "The rent looks too good for the area and the host asked me for a deposit before the visit."
)
report_l5a_benjamin = Report.create!(
  listing: l5a, reporter: benjamin, reason: :offensive, status: :dismissed, created_at: 20.days.ago,
  details: "The description says 'no noisy students', which sounds disrespectful to students."
)

# --- Moderation actions ----------------------------------------------------------------------

puts "Seeding moderation actions..."

ModerationAction.create!(
  moderator: tomas, action_type: :dismiss_report, report: report_l3_nicolas, created_at: 14.days.ago,
  notes: "The listing is accurate: it is furnished with bed and wardrobe. Missing a TV is not misleading."
)
ModerationAction.create!(
  moderator: camila, action_type: :dismiss_report, report: report_l5a_benjamin, created_at: 19.days.ago,
  notes: "Reviewed the text: the phrase asks for quiet hours, not for excluding students."
)
ModerationAction.create!(
  moderator: camila, action_type: :withdraw_listing, report: report_l4b_benjamin, target_listing: l4b,
  created_at: 24.days.ago,
  notes: "Two independent reports and a 2-star review confirm the listing does not match the room."
)
ModerationAction.create!(
  moderator: tomas, action_type: :remove_review, created_at: 21.days.ago,
  notes: "Removed a 1-star review that contained personal insults towards a host. " \
         "The visitor was allowed to post a new, respectful one."
)
ModerationAction.create!(
  moderator: camila, action_type: :suspend_user, target_user: martin, created_at: 22.days.ago,
  notes: "Account suspended: three members reported asking for payments outside the platform."
)

# --- Summary ---------------------------------------------------------------------------------

puts "\nSeed complete:"
[
  User, Neighborhood, Amenity, Property, PropertyAmenity, Listing, Application, Visit, Review,
  ReviewReply, SavedListing, Report, ModerationAction
].each { |model| puts format("  %-18<name>s %<count>d", name: model.name, count: model.count) }
