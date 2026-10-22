# Roster Desk

A tidy shared directory for managing people and access. Sign up, select users, and block, unblock, or delete accounts from one toolbar. Every member has the same management permissions.

With [mise](https://mise.jdx.dev/) installed:

```sh
mise trust
mise install
mise run setup
mise run pg-start
mise run db
mise run dev
```

Open **http://localhost:3000** and create an account. PostgreSQL runs locally on port 55434; use `mise run pg-stop` when finished.

Run `mise run check` for tests, coverage, formatting, linting, and privacy checks. Browser tests need Chrome. Any non-empty password is accepted and stored using Argon2.

Ask the directory for counts, lists, or grouped totals—or ask it to filter and select users. Set `OPENAI_API_KEY` privately to enable chat; `OPENAI_MODEL` defaults to `gpt-4.1-mini`. Questions go to OpenAI; Rails validates the query and calculates the answer. The interpreted query is visible beneath each answer.

[Deploy on Render](https://dashboard.render.com/blueprint/new?repo=https://github.com/aemorvayne/roster-desk) using the included Blueprint. It provisions the web app and PostgreSQL and prompts for your OpenAI key. Free databases expire after 30 days; free web services sleep when idle. Keep a backup or upgrade before the database expires.

To populate an **empty** directory, run `CONTACTS_PATH=/absolute/path/to/contacts.json mise run import`. Keep that file outside the repository. Records use `full_name`, `email`, `job_position`, `last_seen` (ISO 8601), and `status` (`active` or `blocked`). Imported accounts receive random passwords; no existing accounts are overwritten.
