# Design Decisions

Reasoning behind the model in [`domain-model.dbml`](./domain-model.dbml).

## Entities not named explicitly in the description

- **`property_amenities`** — pure join table for the properties↔amenities many-to-many. Amenities describe the home, so they hang from the property, not from each listing.
- **`visits`** — "arranging a visit" has its own lifecycle and timestamps, distinct from the application; a completed visit also anchors review eligibility.
- **`review_replies`** — lets a host answer a review, as its own table so author and timestamp are unambiguous (one reply per review).
- **`saved_listings`** — join table for the users↔listings many-to-many.
- **`reports` vs. `moderation_actions`** — a report says *why* a listing looks wrong; an action log says *what a moderator did*. They are separate because not every action stems from a report, and moderation must be traceable.
- **`neighborhoods` / `amenities` as catalogs**, not free text, because moderators manage them. They are deactivated (`active = false`), never deleted.

## Lifecycle of a listing

`draft → published → reserved → rented`, with `withdrawn` reachable from any state (by the host or a moderator), which voids pending applications. Stored as one `status` enum column. `reserved` is set automatically when the host accepts an applicant; `rented` when the new housemate moves in. `withdrawn` stays distinct from `rented` so "filled" and "taken down" never look alike.

## Lifecycle of an application

`pending → shortlisted → accepted / rejected`, with `withdrawn` available to the seeker while `pending` or `shortlisted`. Visit progress is **not** duplicated here: it lives in `visits` (`proposed → confirmed → completed`, or `cancelled`). An application is its own entity — not a bare link — because it carries a message, a desired move-in date, a stay length, and its own status. Accepting one application is atomic: it becomes `accepted`, every other open application of the listing becomes `rejected`, and the listing becomes `reserved`. A unique `(listing_id, seeker_id)` index blocks duplicate applications, and a partial unique index on `listing_id WHERE status = 'accepted'` makes two accepted applications impossible at the database level.

## Assumptions

- A property can hold several listings; each listing belongs to exactly one property (the room is the unit applied to).
- A host or seeker is not an account type: any `member` can be both. `moderator` is the only privileged role; `visitor` is simply being signed out. `users.status` (`active`/`suspended`) supports account suspension.
- Reviews belong to the **property**, granted by a **completed visit** (`reviews.visit_id` is unique: one review per visit). `property_id` is denormalized onto the review so a property's reviews can be listed directly.
- A host cannot review their own property, and only the host can reply to a review of it.
- An application can have several visits (the host can cancel one and propose another).
- A report always targets a listing, and a member reports a given listing once. Actions against a user or a review are recorded in `moderation_actions`; a removed review is described in `notes`, since its row is deleted.
- Photos and rich text (description, house rules) are handled by Active Storage and Action Text in Assignment 3, so there are no photo tables.

## What changed since Assignment 1

Writing the models showed the first diagram was heavier than the domain needs:

| Assignment 1 | Now | Why |
|---|---|---|
| `property_photos`, `listing_photos` | removed | Active Storage attachments replace them; no custom tables needed. |
| `listing_amenities` | `property_amenities` | Amenities are a trait of the home, shared by all its rooms. |
| Listing `draft/active/paused/closed/removed` | `draft/published/reserved/rented/withdrawn` | Matches the project description; "paused" and "removed" collapse into `withdrawn`, and `reserved`/`rented` separate "accepted" from "moved in". |
| Application `…/visit_scheduled/…`, `applied_at` | status without `visit_scheduled`; `created_at` | Visit progress belongs to `visits`; the creation timestamp is the application date. |
| Visit 1-to-1 with application | many visits per application | Redoing a cancelled visit keeps the history. |
| — | `users.status`, `reports.reason/status` enums, DB `CHECK` constraints, partial unique index | Support suspension, moderation queues, and enforce business rules in the database. |

## Why the landing page keeps 4 "how it works" steps

The brief describes three steps — *publish or search, apply, visit and move in* — with the last one combined. The landing page keeps **Visit** and **Move in** as separate cards because they are distinct moments with their own state: a visit (`proposed/confirmed/completed`) happens before the decision, while moving in only follows an `accepted` application and a `reserved` listing. Merging them would hide that an applicant can be rejected after a visit. This is a minor, deliberate deviation from the brief's wording.
