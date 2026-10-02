# Roomies

Roomies is a platform that connects people with a free room in a shared home to people looking for a place to live. This repository holds all the deliverables for the Web Technologies course project and will be used for every assignment throughout the term.

## Group Members

- Matías Veto
- Santiago Arnolds
- Lucas Nestler

## Repository Structure

```
webtech-proyect/
├── landing/                  # Assignment 1 — static landing page
│   ├── index.html
│   ├── css/
│   │   └── styles.css
│   └── assets/                # images used by the landing page
├── docs/
│   ├── USER_STORIES.md       # Assignment 1 — user stories (visitor, member, moderator)
│   ├── domain-model.dbml     # Assignment 1 — domain model source (dbdiagram.io / DBML format)
│   ├── domain-model.png      # Assignment 1 — domain model diagram (exported image)
│   └── design-decisions.md   # Assignment 1 — modeling decisions and assumptions
└── README.md                 # this file
```

## Assignment 1 — User Stories, Domain Model, and Landing Page

- **Landing page**: [`landing/index.html`](./landing/index.html) — a static Bootstrap page with a navbar, hero section, search block, and how-it-works section.
- **User stories**: [`USER_STORIES.md`](./docs/USER_STORIES.md) — covers publishing properties/listings, searching as a visitor, applying/withdrawing, shortlisting/visits/acceptance, reviews, saving/reporting listings, and moderation, from the visitor, member, and moderator perspectives.
- **Domain model**: [`domain-model.dbml`](./docs/domain-model.dbml) (source) and [`domain-model.png`](./docs/domain-model.png) (diagram). Open the `.dbml` file's contents in [dbdiagram.io](https://dbdiagram.io) to view or edit it interactively.
- **Design decisions**: [`design-decisions.md`](./docs/design-decisions.md) — explains entities added beyond the project description, the lifecycle of listings and applications, and modeling assumptions.

## After Pulling Changes

Run these two commands every time you pull, before starting the application:

```bash
bundle install        # installs any gem that was added or updated in Gemfile.lock
bin/rails db:migrate  # applies any new migration
```

## Course

Web Technologies — 2026
