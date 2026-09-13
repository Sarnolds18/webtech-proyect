# Roomies — User Stories

This document lists the user stories that define the functionality of Roomies. Each story follows the format:

> As a **[type of user]**, I want to **[do something]**, so that **[reason/benefit]**.

Stories are grouped by feature area and tagged with the role that benefits from them:

- **Visitor** — a person browsing the platform who is not signed in.
- **Member (Host)** — a signed-in member acting as the owner/manager of a property.
- **Member (Seeker)** — a signed-in member acting as someone looking for a room.
- **Moderator** — a signed-in member with moderation privileges.

Some stories apply to any signed-in member regardless of the role they are playing at that moment; these are tagged **Member**.

---

## 1. Publishing Properties and Listings

1.1. As a **host**, I want to **create a property with its address, description, and photos**, so that **I can start publishing rooms available inside it**.

1.2. As a **host**, I want to **add one or more room listings to a property, each with its own rent, availability date, and description**, so that **I can offer several rooms in the same house independently**.

1.3. As a **host**, I want to **assign a neighborhood and a set of amenities (from the platform's catalogs) to a listing**, so that **seekers can find it through relevant filters**.

1.4. As a **host**, I want to **upload multiple photos for a listing**, so that **seekers can see what the room and common areas look like before applying**.

1.5. As a **host**, I want to **publish a listing as a draft and then activate it when it's ready**, so that **I can prepare the listing without exposing incomplete information**.

1.6. As a **host**, I want to **edit a listing's information after publishing it**, so that **I can correct mistakes or update the rent and availability**.

1.7. As a **host**, I want to **pause or close a listing**, so that **it stops appearing in search results once the room is no longer available**.

1.8. As a **host**, I want to **see a list of all my properties and their listings in one place**, so that **I can manage everything I have published**.

---

## 2. Searching and Browsing Listings

2.1. As a **visitor**, I want to **browse active listings without creating an account**, so that **I can explore what's available before deciding to sign up**.

2.2. As a **visitor**, I want to **filter listings by neighborhood, maximum rent, and availability date**, so that **I can narrow down results to what fits my needs**.

2.3. As a **visitor**, I want to **filter listings by amenities**, so that **I only see rooms that have what matters to me (e.g. private bathroom, furnished)**.

2.4. As a **visitor**, I want to **view the full detail of a listing, including photos, description, rent, availability, amenities, and neighborhood**, so that **I can decide whether it's worth applying to**.

2.5. As a **visitor**, I want to **be prompted to sign up or log in when I try to apply, save, or report a listing**, so that **I understand an account is required for those actions**.

2.6. As a **seeker**, I want to **sort search results (by rent or by availability date)**, so that **I can quickly find the options that best match my priorities**.

---

## 3. Applying to Listings

3.1. As a **seeker**, I want to **apply to a listing with a short message to the host**, so that **I can introduce myself and express interest in the room**.

3.2. As a **seeker**, I want to **see the current status of each application I've sent (pending, shortlisted, visit scheduled, accepted, rejected, withdrawn)**, so that **I know where I stand with each listing**.

3.3. As a **seeker**, I want to **withdraw an application I previously sent**, so that **I can back out if I'm no longer interested or already found a room**.

3.4. As a **seeker**, I want to **be prevented from applying twice to the same active listing**, so that **the host doesn't receive duplicate applications from me**.

3.5. As a **host**, I want to **see all applications received for a listing, along with each applicant's message**, so that **I can evaluate who might be a good fit**.

---

## 4. Shortlisting, Visits, and Acceptance

4.1. As a **host**, I want to **mark an application as shortlisted**, so that **I can keep track of the candidates I'm seriously considering**.

4.2. As a **host**, I want to **propose a visit date and time to a shortlisted applicant**, so that **we can coordinate an in-person visit to the room**.

4.3. As a **seeker**, I want to **confirm or request a change to a proposed visit date**, so that **the scheduled visit actually works for my availability**.

4.4. As a **host**, I want to **mark a visit as completed**, so that **the applicant becomes eligible to leave a review of the property afterward**.

4.5. As a **host**, I want to **accept one applicant for a listing**, so that **I can finalize who will move in**.

4.6. As a **host**, I want to **have the listing automatically close and the remaining applications automatically rejected once I accept an applicant**, so that **I don't have to manually reject everyone else**.

4.7. As a **seeker**, I want to **be notified when my application is shortlisted, scheduled for a visit, accepted, or rejected**, so that **I always know the outcome without having to check manually**.

---

## 5. Reviews

5.1. As a **seeker**, I want to **leave a review of a property after visiting it, with a rating and a comment**, so that **I can share my experience with future seekers**.

5.2. As a **seeker**, I want to **be limited to reviewing a property only after I've completed a visit to one of its listings**, so that **reviews reflect genuine first-hand experience**.

5.3. As a **visitor**, I want to **read the reviews left on a property**, so that **I can judge its reputation before deciding to apply**.

5.4. As a **host**, I want to **reply to a review left on my property**, so that **I can respond publicly to feedback or clarify a situation**.

---

## 6. Saving and Reporting Listings

6.1. As a **seeker**, I want to **save a listing to a personal list**, so that **I can easily come back to it later without searching again**.

6.2. As a **seeker**, I want to **remove a listing from my saved list**, so that **I can keep my saved list relevant to what I'm still considering**.

6.3. **Member** As a **member**, I want to **report a listing that looks fraudulent, misleading, or inappropriate, with a reason**, so that **moderators can review it and take action**.

6.4. **Member** As a **member**, I want to **see that my report was submitted successfully**, so that **I know it will be reviewed even if I don't hear back immediately**.

---

## 7. Moderation

7.1. As a **moderator**, I want to **see a queue of all reported listings with the reason for each report**, so that **I can review them in order of priority**.

7.2. As a **moderator**, I want to **view the full detail of a reported listing**, so that **I can judge whether the report is valid**.

7.3. As a **moderator**, I want to **dismiss a report that turns out to be unfounded**, so that **the listing keeps operating normally and the report is closed**.

7.4. As a **moderator**, I want to **suspend or remove a listing that violates platform rules**, so that **it stops being visible to seekers**.

7.5. As a **moderator**, I want to **suspend a member's account in cases of repeated or serious violations**, so that **I can protect the integrity of the platform**.

7.6. As a **moderator**, I want to **manage the catalog of neighborhoods (add, edit, deactivate)**, so that **the search filters stay accurate and up to date**.

7.7. As a **moderator**, I want to **manage the catalog of amenities (add, edit, deactivate)**, so that **hosts describe their listings using a consistent, controlled vocabulary**.

7.8. As a **moderator**, I want to **see a history of moderation actions taken**, so that **decisions are traceable and can be reviewed later if disputed**.

---

## 8. Account and General

8.1. As a **visitor**, I want to **sign up with my basic information**, so that **I can become a member and access host and seeker features**.

8.2. **Member** As a **member**, I want to **log in and log out of my account**, so that **my sessions and data stay secure and private**.

8.3. **Member** As a **member**, I want to **edit my profile information**, so that **hosts and seekers I interact with see accurate, up-to-date information about me**.

8.4. **Member** As a **member**, I want to **act as both host and seeker under the same account**, so that **I can publish a room I have available while also looking for one elsewhere**.
