#!/bin/bash
# Initialize project_stats with current data

PGPASSWORD=hanwuji.2012 psql -h aws-0-us-west-1.pooler.supabase.com -p 5432 -U postgres.lkgesolebdfrrtuuivbm -d postgres << 'EOF'
-- Insert today's snapshot
INSERT INTO bestofex_project_stats (project_id, stars, recorded_at)
SELECT id, stars, CURRENT_DATE
FROM bestofex_projects
ON CONFLICT (project_id, recorded_at) DO NOTHING;

-- Insert yesterday's snapshot (slightly lower stars for demo)
INSERT INTO bestofex_project_stats (project_id, stars, recorded_at)
SELECT id, GREATEST(stars - (stars * 0.001)::INTEGER, 0), CURRENT_DATE - INTERVAL '1 day'
FROM bestofex_projects
ON CONFLICT (project_id, recorded_at) DO NOTHING;

-- Verify
SELECT 
  (SELECT COUNT(*) FROM bestofex_project_stats) as total_stats,
  (SELECT COUNT(DISTINCT recorded_at) FROM bestofex_project_stats) as unique_dates;
EOF
