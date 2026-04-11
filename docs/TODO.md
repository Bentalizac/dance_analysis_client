End of work session 2-Apr-2026

-Invite acceptance page needs to go live, or local dev needs to reference it to localhost. Invites need to be accepted.

TODO as of 10-Apr-2026:
Refactor to add FirstName and LastName. Determine whether this is a change to the Users table, or if we should add a UserInfo table for this.

Web interface flow. Current UI flow is App-centric and is unintuitive as the landing page of the website. Should the whole site be Flutter? Or should dance-note.com at root be a TS page, and app.dance-note.com be the current Flutter client? There should be a login feature on the main page, but does that login route to the Flutter client?

Determine costs for running backend API in cloud instead of on local hardware. It's okay for the analysis to be slower running and that can cover for potential downtime. It can be set up to poll the job table in the DB, then pull those videos down to process them.
