-- TrendLens Database Maintenance Jobs
-- Migration: 002_cron_jobs
-- Date: 2026-02-25
--
-- STATUS: pg_cron NOT available on Supabase free tier.
-- These queries will be executed by the Python backend scheduler instead.
-- This file serves as reference SQL for the cleanup logic.

-- Daily cleanup at 03:00 UTC
SELECT cron.schedule('daily-cleanup', '0 3 * * *', $$

  -- 1. Delete off-list topics older than 90 days
  DELETE FROM topics
  WHERE is_on_list = FALSE
    AND last_seen_at < NOW() - INTERVAL '90 days';

  -- 2. Downsample heat_history older than 7 days (keep hourly)
  DELETE FROM heat_history
  WHERE timestamp < NOW() - INTERVAL '7 days'
    AND timestamp > NOW() - INTERVAL '90 days'
    AND id NOT IN (
      SELECT DISTINCT ON (topic_key, date_trunc('hour', timestamp))
        id FROM heat_history
      WHERE timestamp < NOW() - INTERVAL '7 days'
        AND timestamp > NOW() - INTERVAL '90 days'
      ORDER BY topic_key, date_trunc('hour', timestamp), timestamp
    );

  -- 3. Delete heat_history older than 90 days
  DELETE FROM heat_history
  WHERE timestamp < NOW() - INTERVAL '90 days';

  -- 4. Delete old snapshot metadata
  DELETE FROM snapshots_meta
  WHERE fetched_at < NOW() - INTERVAL '14 days';

  -- 5. Deactivate clusters with no active topics
  UPDATE event_clusters SET is_active = FALSE, last_updated_at = NOW()
  WHERE is_active = TRUE
    AND cluster_id NOT IN (
      SELECT DISTINCT cluster_id FROM topics
      WHERE is_on_list = TRUE AND cluster_id IS NOT NULL
    );

  -- 6. Delete inactive clusters older than 90 days
  DELETE FROM event_clusters
  WHERE is_active = FALSE
    AND last_updated_at < NOW() - INTERVAL '90 days';

$$);
