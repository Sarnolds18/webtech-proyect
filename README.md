# Roomies

Roomies is a platform that connects people with a free room in a shared home to people looking for a place to live. This repository holds all the deliverables for the Web Technologies course project and will be used for every assignment throughout the term.

## Group Members

- Matías Veto
- Santiago Arnolds
- Lucas Nestler

## Repository Structure

```
webtech-proyect/
├── app/                      # Assignment 2 — Rails application
│   ├── models/               #   13 models (associations, validations, enums, scopes)
│   ├── controllers/          #   read-only controllers (home, listings, properties, neighborhoods, applications)
│   ├── views/                #   ERB views, partials and layout
│   ├── helpers/              #   view helpers
│   └── assets/               #   Bootstrap (Sass) and images
├── config/                   # Assignment 2 — routes and Rails configuration
├── db/                       # Assignment 2 — migrations, schema and seeds
│   ├── migrate/
│   ├── schema.rb
│   └── seeds.rb              #   sample data for every table
├── test/
│   └── models/               #   model tests (validations, scopes, database constraints)
├── landing/                  # Assignment 1 — static landing page (kept as history; `/` is now its Rails version)
│   ├── index.html
│   ├── css/
│   │   └── styles.css
│   └── assets/                # images used by the landing page
├── docs/
│   ├── USER_STORIES.md       # Assignment 1 — user stories (visitor, member, moderator)
│   ├── domain-model.dbml     # domain model source (dbdiagram.io / DBML format), updated in Assignment 2
│   ├── domain-model.png      # domain model diagram (exported image), updated in Assignment 2
│   └── design-decisions.md   # modeling decisions, and what changed since Assignment 1
└── README.md                 # this file
```

## Getting Started

### Requirements

- Ruby 4.0.4 (see `.ruby-version`)
- Node.js and Yarn (Bootstrap is compiled from Sass with `cssbundling-rails`)
- PostgreSQL, running locally

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

The model tests cover validations, enums, scopes and database constraints (for example, only one accepted application per listing).

### Reset the data

To reset the database to its initial sample data at any time:

```bash
bin/rails db:drop db:create db:migrate db:seed
```

### Test users

Every seeded user has the password **`password123`**. Login arrives in Assignment 4, so for now these accounts only identify the sample data.

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
| `/listings` | Published listings, with filters by neighborhood, maximum rent and availability date |
| `/listings/:id` | Listing details (any status) |
| `/properties`, `/properties/:id` | Properties, their listings and reviews |
| `/neighborhoods`, `/neighborhoods/:id` | Neighborhoods and their listings |
| `/applications`, `/applications/:id` | Applications and their visits |

The application is **read-only** in Assignment 2: nothing can be created, edited or deleted from the browser yet. The applications pages are public until login and permissions arrive in Assignment 4 (an application should only be visible to its seeker and the host of the listing).

### Common problems

- **PostgreSQL is not running**: start it with `sudo service postgresql start`.
- **`yarn: command not found`**: run `corepack enable` (or `npm install -g yarn`).
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

## After Pulling Changes

Run these two commands every time you pull, before starting the application:

```bash
bundle install        # installs any gem that was added or updated in Gemfile.lock
bin/rails db:migrate  # applies any new migration
```

## Course

Web Technologies — 2026
