#!/bin/bash

# Import projects with bestofex_ prefix
PGPASSWORD=hanwuji.2012 psql -h aws-0-us-west-1.pooler.supabase.com -p 5432 -U postgres.lkgesolebdfrrtuuivbm -d postgres << 'EOF'
INSERT INTO bestofex_projects (name, full_name, description, repo_url, homepage_url, avatar_url, stars, open_issues, pushed_at, license) VALUES
('test', 'test/test', 'test desc', 'https://github.com/test/test', NULL, NULL, 100, 0, NULL, NULL),
('elixir', 'elixir-lang/elixir', 'Elixir is a dynamic, functional language for building scalable and maintainable applications', 'https://github.com/elixir-lang/elixir', 'https://elixir-lang.org/', 'https://avatars.githubusercontent.com/u/1481354?v=4', 26355, 28, '2026-02-09T11:49:54', 'Apache-2.0'),
('analytics', 'plausible/analytics', 'Simple, open source, lightweight and privacy-friendly web analytics alternative to Google Analytics.', 'https://github.com/plausible/analytics', 'https://plausible.io', 'https://avatars.githubusercontent.com/u/54802774?v=4', 24203, 52, '2026-02-10T14:57:37', 'AGPL-3.0'),
('phoenix', 'phoenixframework/phoenix', 'Peace of mind from prototype to production', 'https://github.com/phoenixframework/phoenix', 'https://www.phoenixframework.org', 'https://avatars.githubusercontent.com/u/6510388?v=4', 22791, 49, '2026-02-04T13:25:39', 'MIT'),
('awesome-elixir', 'h4cc/awesome-elixir', 'A curated list of amazingly awesome Elixir and Erlang libraries, resources and shiny things.', 'https://github.com/h4cc/awesome-elixir', 'https://twitter.com/AwesomeElixir', 'https://avatars.githubusercontent.com/u/2981491?v=4', 13083, 8, '2025-10-12T18:06:13', 'MIT'),
('electric', 'electric-sql/electric', 'Read-path sync engine for Postgres that handles partial replication, data delivery and fan-out.', 'https://github.com/electric-sql/electric', 'https://electric-sql.com', 'https://avatars.githubusercontent.com/u/96433696?v=4', 9868, 237, '2026-02-10T15:11:13', 'Apache-2.0'),
('firezone', 'firezone/firezone', 'Enterprise-ready zero-trust access platform built on WireGuard.', 'https://github.com/firezone/firezone', 'https://www.firezone.dev', 'https://avatars.githubusercontent.com/u/87211124?v=4', 8393, 475, '2026-02-10T13:08:25', 'Apache-2.0'),
('teslamate', 'teslamate-org/teslamate', 'A self-hosted data logger for your Tesla', 'https://github.com/teslamate-org/teslamate', 'https://docs.teslamate.org', 'https://avatars.githubusercontent.com/u/150616486?v=4', 7620, 61, '2026-02-10T14:11:35', 'MIT'),
('realtime', 'supabase/realtime', 'Broadcast, Presence, and Postgres Changes via WebSockets', 'https://github.com/supabase/realtime', 'https://supabase.com/realtime', 'https://avatars.githubusercontent.com/u/54469796?v=4', 7483, 56, '2026-02-10T13:53:23', 'Apache-2.0'),
('phoenix_live_view', 'phoenixframework/phoenix_live_view', 'Rich, real-time user experiences with server-rendered HTML', 'https://github.com/phoenixframework/phoenix_live_view', 'https://hex.pm/packages/phoenix_live_view', 'https://avatars.githubusercontent.com/u/6510388?v=4', 6719, 77, '2026-02-09T17:48:37', 'MIT'),
('ecto', 'elixir-ecto/ecto', 'A toolkit for data mapping and language integrated query.', 'https://github.com/elixir-ecto/ecto', 'https://hexdocs.pm/ecto', 'https://avatars.githubusercontent.com/u/19973437?v=4', 6434, 10, '2026-01-30T17:05:38', 'Apache-2.0'),
('papercups', 'papercups-io/papercups', 'Open-source live customer chat', 'https://github.com/papercups-io/papercups', 'https://app.papercups.io/demo', 'https://avatars.githubusercontent.com/u/68310464?v=4', 5922, 173, '2024-02-15T05:21:47', 'MIT'),
('livebook', 'livebook-dev/livebook', 'Automate code & data workflows with interactive Elixir notebooks', 'https://github.com/livebook-dev/livebook', 'https://livebook.dev', 'https://avatars.githubusercontent.com/u/87464290?v=4', 5695, 29, '2026-02-10T14:46:45', 'Apache-2.0'),
('credo', 'rrrene/credo', 'A static code analysis tool for the Elixir language with a focus on code consistency and teaching.', 'https://github.com/rrrene/credo', 'http://credo-ci.org/', 'https://avatars.githubusercontent.com/u/311914?v=4', 5140, 31, '2026-02-08T19:53:01', 'MIT')
ON CONFLICT (repo_url) DO NOTHING;

INSERT INTO bestofex_tags (name, slug) VALUES
('Crypto', 'crypto'),
('Database', 'database'),
('Real-time', 'real-time'),
('Web Framework', 'web-framework'),
('Deployment', 'deployment'),
('Monitoring', 'monitoring'),
('DevTools', 'devtools')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO bestofex_project_tags (project_id, tag_id) VALUES
(2, 1), (6, 2), (7, 3), (7, 4), (13, 4), (13, 3), (12, 4), (12, 5),
(4, 4), (4, 3), (3, 4), (3, 2), (3, 6), (14, 7), (9, 2), (9, 3),
(9, 4), (8, 5)
ON CONFLICT (project_id, tag_id) DO NOTHING;

SELECT COUNT(*) as projects FROM bestofex_projects;
SELECT COUNT(*) as tags FROM bestofex_tags;
SELECT COUNT(*) as project_tags FROM bestofex_project_tags;
EOF
