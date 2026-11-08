# Roomies

Roomies is a platform that connects people with a free room in a shared home to people looking for a place to live. This repository holds all the deliverables for the Web Technologies course project and will be used for every assignment throughout the term.

## Group Members

- Matías Veto
- Santiago Arnolds
- Lucas Nestler

## Repository Structure

```
webtech-proyect/
├── app/
│   ├── models/               # 13 domain models, Session and Current
│   ├── controllers/          # Public browsing, CRUD, accounts and profile
│   ├── mailers/              # Password reset and application notifications
│   ├── views/                # Bootstrap ERB views, email templates and shared partials
│   ├── javascript/           # Turbo, Stimulus and importmap entry points
│   ├── helpers/              # Formatting, photos and validation errors
│   └── assets/               # Bootstrap Sass, icons and images
├── config/                   # Routes, PostgreSQL, email, jobs and Kamal configuration
├── db/
│   ├── migrate/              # Domain tables, Active Storage, Action Text and sessions
│   ├── schema.rb
│   └── seeds.rb              # Repeatable sample data and permission verification URLs
├── test/                     # Model, controller, helper and mailer tests; email previews
├── landing/                  # Assignment 1 static page, kept as history
├── docs/
│   ├── USER_STORIES.md
│   ├── domain-model.dbml     # Domain model source for dbdiagram.io
│   ├── domain-model.png
│   └── design-decisions.md
└── README.md
```

Authorization lives in `app/policies/` (one Pundit policy per model, all inheriting from
`BasePolicy`) and `app/controllers/concerns/authorization.rb`. The versioned public JSON API
lives in `app/controllers/api/v1/` and `app/views/api/v1/` (see [API](#api)).

## Getting Started

### Requirements

- Ruby 4.0.4 (see `.ruby-version`)
- Node.js and Yarn (Bootstrap is compiled from Sass with `cssbundling-rails`)
- PostgreSQL, running locally
- libvips, used by Active Storage to resize photographs (`sudo apt install libvips42` on Ubuntu/WSL, `brew install vips` on macOS)

### Setup

```bash
git clone https://github.com/Sarnolds18/webtech-proyect.git
cd webtech-proyect

bundle install                 # install gems
yarn install                   # install JavaScript dependencies (Bootstrap, Bootstrap Icons)
bin/rails db:create db:migrate # create the database and its tables
bin/rails db:seed              # fill it with sample data
```

### Run the app

```bash
bin/dev
```

`bin/dev` starts the Rails server and the CSS watcher together. Then open <http://localhost:3000>.

### Run the tests

```bash
bin/rails test
```

The suite covers model validations and database constraints, CRUD and Hotwire flows, sign up,
sessions, password reset, profile ownership, notification emails, every Pundit policy and the
privacy of applications by URL. The test scenario is built
with `create!` in `test/test_helper.rb`, rather than YAML fixtures.

Additional local checks:

```bash
bin/rubocop
bin/brakeman --no-pager
bin/bundler-audit
```

### Photographs

Listing photographs are stored with Active Storage (on disk, in `storage/`). Each listing can have up to
**10 photographs**, and the uploads are validated in the `Listing` model:

- **Only images**: JPEG, PNG or WebP.
- **Size limit: 5 MB per photograph.**

Cards show a 600×400 variant of the first photograph, and the listing page shows every photograph at a
1600×1200 maximum, so no page downloads an original upload. The sample photographs used by the seeds
live in [`db/seeds/photos`](./db/seeds/photos).

### Reset the data

To reset the database to its initial sample data at any time:

```bash
bin/rails db:drop db:create db:migrate db:seed
```

### Test users

Sign in at **`/session/new`**. Every seeded user has the password **`password123`**.
For the required role checks, use **Sofía Araya** (`sofia.araya@roomies.test`) as a member and
**Camila Rojas** (`camila.rojas@roomies.test`) as a moderator. Martín Silva is suspended and
cannot sign in. Sign out to browse as a visitor; the acting user selector has been removed.

Host and seeker describe how a member uses the app; they are not additional values of `User.role`.

| Role | Name | Email |
|---|---|---|
| Moderator | Camila Rojas | `camila.rojas@roomies.test` |
| Moderator | Tomás Fuentes | `tomas.fuentes@roomies.test` |
| Host | Valentina Soto | `valentina.soto@roomies.test` |
| Host | Matías Pérez | `matias.perez@roomies.test` |
| Host (also applies as a seeker) | Javiera Muñoz | `javiera.munoz@roomies.test` |
| Host | Diego Contreras | `diego.contreras@roomies.test` |
| Seeker | Sofía Araya | `sofia.araya@roomies.test` |
| Seeker | Benjamín Vera | `benjamin.vera@roomies.test` |
| Seeker | Francisca Lagos | `francisca.lagos@roomies.test` |
| Seeker | Nicolás Herrera | `nicolas.herrera@roomies.test` |
| Seeker | Isidora Campos | `isidora.campos@roomies.test` |
| Suspended | Martín Silva | `martin.silva@roomies.test` |

### Routes

| Path | Page |
|---|---|
| `/` | Home (the landing page) |
| `/listings` | Published listings, with filters by neighborhood, maximum rent, availability date and amenities; updates without reloading through the API |
| `/listings/:id` | Listing details; a draft is restricted to its host and the moderators |
| `/properties`, `/properties/:id` | Properties, their listings and reviews |
| `/neighborhoods`, `/neighborhoods/:id` | Neighborhoods and their listings |
| `/applications`, `/applications/:id` | "My applications": the ones you sent and the ones your listings received (moderators see all) |
| `/listings/:listing_id/inbox` | Host inbox, with Turbo Stream answers |
| `/amenities` | Amenity catalog (moderators) |
| `/reports`, `/reports/:id` | Reported listings, dismissed or acted on by moderators |
| `/session/new` | Sign in; sign out is available in the user menu |
| `/sign_up` | Create an active member account |
| `/passwords/new` | Request a password reset email |
| `/profile`, `/profile/edit` | View and edit the signed-in member's profile |
| `/rails/mailers` | Email previews in development |

The app supports create, edit and delete flows, listing lifecycle actions, applications, visits
and reviews. Profile changes accept only name, email, phone, bio and optional password fields.
Passwords need at least 8 characters; changing one in the profile requires the current password.
A bio may contain up to 500 characters. Phone numbers are optional and accept a leading `+`,
digits, spaces and hyphens (7–20 characters).

The public JSON API is served under `/api/v1`: `/api/v1/listings`, `/api/v1/listings/:id`,
`/api/v1/neighborhoods` and `/api/v1/amenities`. See [API](#api).

## Roles and permissions

Every rule below is a Pundit policy in `app/policies/`, and every controller action calls
`authorize` (checked by `verify_authorized`), so hiding a button is only a courtesy: typing a URL or
sending a request by hand is blocked too. Lists of private records (the applications page, the host
inbox, the listings of a property) come from policy scopes, so the query itself returns only what the
user may see. A visitor who tries a protected action is sent to sign in; a signed-in member gets an
**Access denied** page (HTTP 403) that explains why, or the same message inside the Turbo Frame when
the request came from one. Moderators' withdrawals, report decisions and review deletions are
recorded as moderation actions.

| Action | Visitor | Member | Moderator |
|---|---|---|---|
| Browse and search published listings | Yes | Yes | Yes |
| See a draft listing | No | Own only | Any |
| Create a property or listing | No | Yes; a listing belongs to their property | Same as member |
| Edit or delete a property or listing | No | Own only | Any, subject to model lifecycle rules |
| Apply to a published listing | No | Except their own | Same as member |
| See applications | No | Their own submissions and applications to their listings | Any |
| Shortlist, reject or accept | No | Host of the listing | No extra permission from the moderator role |
| Arrange visits | No | Host proposes/reschedules/completes; applicant confirms; either may cancel | No extra permission from the moderator role |
| Write a review | No | After their own completed visit, never on their own property | No extra permission from the moderator role |
| Delete a review | No | Own only | Any |
| Report a listing | No | Except their own | Same as member |
| Resolve reports | No | No | Yes |
| Manage neighborhoods and amenities | No | No | Yes |

A visitor is someone who is signed out, not a stored role. Members can act as hosts and seekers
under the same account. Ownership determines most permissions.

## How to verify the permissions

`bin/rails db:seed` prints actual URLs for the records below; ids change when the seed is rerun.
Every account uses `password123`.

1. As a visitor, open the home page, listings, properties and reviews. Creating a property or
   opening `/profile` must redirect to sign in. Create an account at `/sign_up`, edit its profile,
   sign out and sign back in. Supplying a role during registration must not create a moderator.
2. Sign in as Valentina. Her draft is **Valentina's draft room in Providencia**, linked from her
   property page. Save its URL, open it as Sofía and expect access denied. Repeat with Matías's
   draft in Ñuñoa. Camila, as a moderator, can view either draft.
3. Sign in as Matías and open the printed inbox URL for **Large room with private bathroom**.
   Shortlist a pending application, propose a visit, then accept an applicant. The listing must
   become reserved and the other pending/shortlisted applications must become rejected together.
   Check that the Turbo Stream updates the rows, counter and listing status.
4. Sign in as Sofía. Check her sent applications and save one of their URLs. Sign in as Isidora
   (a member without properties): the URL of Sofía's application must be denied and its message
   must not appear in Isidora's list.
5. Sign in as Isidora to confirm her proposed visit, or as Francisca to write a review on
   **Bright apartment near Metro Pedro de Valdivia**. Francisca already has a completed visit
   without a review; the printed property URL leads to the review form.
6. Sign in as Camila to resolve an open report, withdraw a reported listing, delete a review and
   manage catalogs (**Reports** in the navbar shows the open ones). She can read any inbox, but
   accepting another host's applicant is denied. Each decision appears in the report's
   moderation log.
7. Try signing in as Martín: his suspended account must be refused. Request a password reset for
   Sofía, open the email, change her password and check that previous sessions stop working.

## Emails

Password resets and application notifications use Action Mailer with `deliver_later` through
Active Job. A new application emails its host; a shortlist, acceptance or rejection emails the
seeker. Accepting an applicant also emails every automatically rejected seeker. Notifications
are enqueued after commit, so a rolled-back acceptance sends no answer emails.

In development, messages are written to **`tmp/mails/`** rather than sent by SMTP. Restart
`bin/dev` after email configuration changes. Visit **`/rails/mailers`** for password reset and
application notification previews; the previews use the seeded Sofía account and her applications.
The development queue adapter is `:async`, which runs jobs inside the Rails process without a
separate worker. Seeding also runs the application's notification callbacks, so sample-data
emails can appear in `tmp/mails/`.

Production uses Solid Queue. The Kamal configuration sets `SOLID_QUEUE_IN_PUMA: true` to start
its supervisor in Puma. Before deployment, configure the production mail host, sender and SMTP
credentials; the current production configuration still contains placeholder values.

### Common problems

- **PostgreSQL is not running**: start it with `sudo service postgresql start`.
- **`yarn: command not found`** or **`cssbundling-rails: No suitable tool found for installing JavaScript dependencies`**: install Yarn with `npm install -g yarn`, then run `yarn install`. (`corepack enable` also works, but only on Node.js 24 or older: Node.js 25 stopped shipping Corepack.)
- **`Could not open library 'vips'`** or photographs not showing: install libvips (see Requirements).
- **Ruby version mismatch**: install the version in `.ruby-version`, e.g. `rbenv install 4.0.4`.

## Assignment 1 — User Stories, Domain Model, and Landing Page

- **Landing page**: [`landing/index.html`](./landing/index.html) — a static Bootstrap page with a navbar, hero section, search block, and how-it-works section.
- **User stories**: [`USER_STORIES.md`](./docs/USER_STORIES.md) — covers publishing properties/listings, searching as a visitor, applying/withdrawing, shortlisting/visits/acceptance, reviews, saving/reporting listings, and moderation, from the visitor, member, and moderator perspectives.
- **Domain model**: [`domain-model.dbml`](./docs/domain-model.dbml) (source) and [`domain-model.png`](./docs/domain-model.png) (diagram). Open the `.dbml` file's contents in [dbdiagram.io](https://dbdiagram.io) to view or edit it interactively.
- **Design decisions**: [`design-decisions.md`](./docs/design-decisions.md) — explains entities added beyond the project description, the lifecycle of listings and applications, and modeling assumptions.

## Assignment 2 — Rails Models, Read-only Views, and Seeds

- **Models**: 13 Active Record models with associations (including the many-to-many ones), validations, enums, scopes and database constraints. See [`db/schema.rb`](./db/schema.rb).
- **Read-only views**: index and show pages for listings, properties, neighborhoods and applications, with a shared layout, partials and Bootstrap 5.
- **Domain model update**: the diagram and [`design-decisions.md`](./docs/design-decisions.md) were updated; its section *What changed since Assignment 1* explains each change.
- **Model tests**: [`test/models`](./test/models) — run them with `bin/rails test`.
- **Seeds**: [`db/seeds.rb`](./db/seeds.rb) populates every table with realistic Santiago data: listings in every lifecycle state, applications in every status, completed visits, reviews with host replies, saved listings, reports and moderation actions.

The static landing page in [`landing/`](./landing) is kept as history; the app's root page (`/`) is now its Rails version.

## Assignment 3 — CRUD, Photographs, Rich Text, and Hotwire

- Property and listing forms, amenity selection, catalog CRUD and inline validation errors.
- Multiple validated photographs with Active Storage variants, and Action Text for descriptions
  and house rules.
- Applications created on the listing page inside a Turbo Frame; the host inbox answers them
  with Turbo Streams that update all affected rows and the pending counter.
- Atomic applicant acceptance, listing lifecycle actions, visits and reviews after completed visits.

## Assignment 4 — Accounts, Permissions, API, and Notifications

- Native Rails 8 authentication, sign up/in/out and password reset by email. The acting user
  selector is removed; suspended members cannot sign in or resume a session.
- An editable profile for the signed-in member, with current-password verification for password changes.
- Notification emails through Active Job, HTML/text templates, development file delivery and previews.
- Seeds with members and moderators, separate hosts' drafts, competing applicants, a completed
  visit without a review, open reports and printed verification URLs.
- Pundit authorization: a policy for every model (`BasePolicy` is the shared base, since
  `ApplicationPolicy` is the policy of the `Application` model), policy scopes for the applications
  page and the host inbox, `authorize` in every controller action and an explanatory Access denied
  page.
- Moderation: members report listings; moderators dismiss reports or withdraw the listing, delete
  any review, and every decision is logged as a moderation action.
- Search by amenities: a listing matches when its property has every amenity checked, on the
  home page and on `/listings`.
- A versioned, public JSON API (`/api/v1`) for published listings, neighborhoods and amenities,
  with filters, sorting, pagination, JSON errors (400/404) and no personal data. See [API](#api).
- The `/listings` search page consumes that API with `fetch` and redraws the results without
  reloading; without JavaScript it still works as a normal form.

## After Pulling Changes

Run these two commands every time you pull, before starting the application:

```bash
bundle install        # installs any gem that was added or updated in Gemfile.lock
bin/rails db:migrate  # applies any new migration
```

## API

Roomies has a public, read-only JSON API for the published listings and the catalogs used to
filter them. It needs no account and no token, and it never returns personal data.

- **Base URL:** `/api/v1` (e.g. `http://localhost:3000/api/v1` in development). The version is
  part of the path, so a future `/api/v2` can change the format without breaking `/api/v1` clients.
- **Format:** JSON (`Content-Type: application/json`) for every response, errors included.
- **Methods:** only `GET`. Any other path or method under `/api/v1` answers a JSON 404.
- **Code:** `app/controllers/api/v1/` (controllers) and `app/views/api/v1/` (Jbuilder views). The
  API controllers inherit from `ActionController::API`, so sessions and Pundit do not apply: the
  queries themselves only read public records.

### Endpoints

| Method | Path | Returns |
|---|---|---|
| `GET` | `/api/v1/listings` | Published listings, filtered, sorted and paginated |
| `GET` | `/api/v1/listings/:id` | One published listing, with its description, house rules and photos |
| `GET` | `/api/v1/neighborhoods` | Active neighborhoods (`id`, `name`, `city`), to build the neighborhood filter |
| `GET` | `/api/v1/amenities` | Active amenities (`id`, `name`, `icon`), to build the amenity filter |

Only **published** listings exist for the API: a draft, reserved, rented or withdrawn listing
answers 404 on `/api/v1/listings/:id`, exactly like an id that does not exist.

### Parameters of `GET /api/v1/listings`

Every parameter is optional; filters combine with AND.

| Parameter | Type | Example | Default | Meaning |
|---|---|---|---|---|
| `neighborhood_id` | positive integer | `3` | — | Only listings in this neighborhood |
| `max_rent` | positive integer (CLP) | `350000` | — | Monthly rent at most this amount |
| `available_by` | date `YYYY-MM-DD` | `2026-12-01` | — | Rooms available on or before this date |
| `amenity_ids` | list of positive integers | `amenity_ids=1,3` or `amenity_ids[]=1&amenity_ids[]=3` | — | The property has **every** amenity listed |
| `furnished` | `true` / `false` (`1` / `0`) | `true` | `false` | `true`: only furnished rooms |
| `private_bathroom` | `true` / `false` (`1` / `0`) | `true` | `false` | `true`: only rooms with a private bathroom |
| `sort` | `soonest`, `cheapest`, `newest` | `cheapest` | `soonest` | Earliest availability, lowest rent, or most recently created first |
| `page` | positive integer | `2` | `1` | Page number; a page past the end returns an empty `data` |
| `per_page` | integer 1–50 | `20` | `12` | Listings per page |

An invalid value never falls back silently to a default: it answers 400 and names the parameter.

### Responses

`GET /api/v1/listings?per_page=1&sort=cheapest` (real response from the seeds, the amenities
list and photo URL shortened):

```json
{
  "data": [
    {
      "id": 18,
      "title": "Budget room near Plaza Ñuñoa",
      "status": "published",
      "monthly_rent": 210000,
      "deposit": 0,
      "currency": "CLP",
      "available_from": "2026-11-13",
      "minimum_stay_months": 1,
      "furnished": true,
      "private_bathroom": false,
      "neighborhood": { "id": 11, "name": "Ñuñoa", "city": "Santiago" },
      "property": {
        "id": 8,
        "title": "Garden house in Plaza Ñuñoa",
        "property_type": "house",
        "bedrooms": 4,
        "bathrooms": 2,
        "amenities": [
          { "id": 13, "name": "WiFi", "icon": "bi-wifi" },
          { "id": 14, "name": "Washing machine", "icon": "bi-water" }
        ]
      },
      "rating": { "average": 4.5, "count": 2 },
      "cover_photo_url": "http://localhost:3000/rails/active_storage/representations/redirect/.../nunoa.jpg",
      "links": {
        "self": "http://localhost:3000/api/v1/listings/18",
        "html": "http://localhost:3000/listings/18"
      }
    }
  ],
  "meta": { "page": 1, "per_page": 1, "total": 8, "total_pages": 8 },
  "links": {
    "self": "http://localhost:3000/api/v1/listings?per_page=1&sort=cheapest",
    "next": "http://localhost:3000/api/v1/listings?page=2&per_page=1&sort=cheapest",
    "prev": null
  }
}
```

- `data`: the listings of the page. `rating.average` is `null` when the property has no reviews;
  `cover_photo_url` is `null` when the listing has no photographs (it is a small 600×400 variant).
- `meta`: the page, the page size, the total number of listings that match and the number of pages.
- `links`: absolute URLs of this page and of the next and previous ones (`null` at the ends). They
  keep the filters, so a client follows `links.next` until it is `null`.

`GET /api/v1/listings/:id` answers `{ "data": { ... } }` with the same fields, plus
`description` and `house_rules` as **plain text** (the HTML formatting stays on the listing page),
and `photos`: a list of `{ "card_url", "large_url" }` for every photograph.

`GET /api/v1/neighborhoods` and `GET /api/v1/amenities` answer
`{ "data": [{ "id": 15, "name": "La Reina", "city": "Santiago" }, ...] }` and
`{ "data": [{ "id": 13, "name": "WiFi", "icon": "bi-wifi" }, ...] }`, in alphabetical order.

### Errors and status codes

Every error has the same shape:

```json
{ "error": { "status": 400, "code": "invalid_parameter", "message": "max_rent must be a positive integer", "parameter": "max_rent" } }
```

| Status | `code` | When |
|---|---|---|
| `200 OK` | — | The request worked (also when no listing matches: `data` is `[]`) |
| `400 Bad Request` | `invalid_parameter` | A parameter has a wrong value, e.g. `max_rent=abc`, `available_by=31-12-2026`, `per_page=500`, `sort=price`. `parameter` names it |
| `404 Not Found` | `not_found` | The listing does not exist or is not published, or the endpoint does not exist (e.g. `/api/v1/users`) |

### What the API never exposes, and why

Applications are private and Roomies' listings are public, so the API returns the room and never
the people around it:

- **Hosts:** no name, email, phone or id. A seeker contacts the host by applying on the site.
- **Property address:** only the neighborhood and city; the exact address is not public data.
- **Applications and applicants:** not even how many there are (the project rule is that visitors
  never see who applied to a listing).
- **Reviews:** only the average rating and the number of reviews, never their authors or text.
- **Reports, moderation actions and non-published listings** (drafts included).

The controller tests in `test/controllers/api/v1/` check this on every response: no emails,
addresses or names, and no `host`, `address`, `email_address`, `phone`, `applications` or
`author` keys.

### Examples

```bash
# Rooms in neighborhood 1 under $350.000 whose property has amenities 1 and 3, cheapest first
curl "http://localhost:3000/api/v1/listings?neighborhood_id=1&max_rent=350000&amenity_ids=1,3&sort=cheapest"

# Furnished rooms available by December 1st, 5 per page, second page
curl "http://localhost:3000/api/v1/listings?furnished=true&available_by=2026-12-01&per_page=5&page=2"

# One listing, and the catalogs used to build the filters
curl http://localhost:3000/api/v1/listings/18
curl http://localhost:3000/api/v1/neighborhoods
curl http://localhost:3000/api/v1/amenities

# Errors: a 400 that names the parameter, and a 404 (-i shows the status line)
curl -i "http://localhost:3000/api/v1/listings?max_rent=abc"
curl -i http://localhost:3000/api/v1/listings/999999
```

Ids change every time the seeds run: take them from `/api/v1/neighborhoods`, `/api/v1/amenities`
or the first `/api/v1/listings` response.

### The search page uses this API

The `/listings` page is first rendered by the server, so it works without JavaScript. With
JavaScript, `app/javascript/controllers/listing_search_controller.js` (Stimulus) sends every change
of the filters to `GET /api/v1/listings` with `fetch`, redraws the cards from the JSON without
reloading the page, shows the API's error messages, loads more rooms by following `links.next`, and
keeps the filters in the address bar so a reload or a shared link shows the same search.

## Course

Web Technologies — 2026
