# Design Decisions

Reasoning behind the model in [`domain-model.dbml`](./domain-model.dbml).

## Entities not named explicitly in the description

- **`property_photos` / `listing_photos`** — split into two galleries (common areas vs. the specific room) instead of one generic table.
- **`listing_amenities`** — a pure join table for the listing↔amenity many-to-many.
- **`visits`** — "arranging a visit" implies its own lifecycle and timestamps, distinct from the application; it also anchors review eligibility.
- **`review_replies`** — lets a host respond to a review, as its own table so author/timestamp aren't ambiguous.
- **`reports` vs. `moderation_actions`** — a report says *why* something looks wrong; an action log says *what a moderator did*, kept separate since not every action stems from a report, and story 7.8 asks for a traceable history.
- **`neighborhoods` / `amenities` as catalogs**, not free text, since moderators explicitly manage them.

## Lifecycle of a listing

`draft → active → paused → closed`, with `removed` reachable from any state via moderation. `draft` is prep-only (1.5); `active` is searchable; `paused` hides it without deleting (1.7); `closed` fires automatically when a host accepts an applicant (4.6), which also auto-rejects the rest; `removed` is moderator-driven (7.4), kept distinct from `closed` so "filled" and "taken down" don't look the same in an audit. A single `status` column was enough since no story asks for a visible status-change timeline.

## Lifecycle of an application

`pending → shortlisted → visit_scheduled → accepted / rejected`, with `withdrawn` reachable any time by the seeker (3.3). `visit_scheduled` is set once a `visits` row exists; the visit's own status tracks proposed/confirmed/completed so the application doesn't duplicate that detail. `accepted` (4.5) triggers the listing's closing and the auto-rejection cascade. An application is its own entity — not a bare link table — because it carries a `message`, `applied_at`, and this status; a unique `(listing_id, seeker_id)` index enforces "no duplicate active applications" (3.4).

## Assumptions

- A property can hold several listings, but each listing belongs to exactly one property (rooms are the unit applied to).
- Reviews are tied to the **property** via the completed `visit` that grants eligibility, not freely to any past interaction.
- Host/seeker are not stored as an account type — any `member` can do both (8.4); `moderator` is the one privileged role kept as an explicit flag.
- A visit is 1-to-1 with its application; redoing a visit updates the same row rather than creating a new one.
- Saved listings carry no metadata beyond a timestamp.
- A report always targets a listing (the only reportable object named in the brief); action against a user is recorded on `moderation_actions`, not on the report itself.
