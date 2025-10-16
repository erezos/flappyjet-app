-- ============================================================================
-- FLAPPYJET STORY MODE - DATABASE SCHEMA
-- ============================================================================
-- Purpose: Track player progress through story mode levels
-- Database: PostgreSQL (Railway)
-- Version: 1.0
-- Created: October 5, 2025
-- ============================================================================

-- ============================================================================
-- TABLE 1: player_level_progress
-- ============================================================================
-- Purpose: Track overall story mode progress for each player
-- One row per player
-- ============================================================================

CREATE TABLE IF NOT EXISTS player_level_progress (
    -- Primary Key
    id SERIAL PRIMARY KEY,
    
    -- Foreign Key to players table
    player_id INTEGER NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    
    -- Progress Tracking
    current_level INTEGER NOT NULL DEFAULT 1,              -- Current level player is on (1-100)
    highest_level_unlocked INTEGER NOT NULL DEFAULT 1,     -- Highest level unlocked (1-100)
    total_levels_completed INTEGER NOT NULL DEFAULT 0,     -- Total levels completed (0-100)
    
    -- Zone Progress
    current_zone INTEGER NOT NULL DEFAULT 1,               -- Current zone (1-10)
    zones_completed INTEGER NOT NULL DEFAULT 0,            -- Total zones completed (0-10)
    
    -- Statistics
    total_stars_earned INTEGER NOT NULL DEFAULT 0,         -- Future: star rating system
    total_coins_earned INTEGER NOT NULL DEFAULT 0,         -- Total coins from story mode
    total_gems_earned INTEGER NOT NULL DEFAULT 0,          -- Total gems from story mode
    
    -- Bot Battles
    bot_battles_won INTEGER NOT NULL DEFAULT 0,            -- Total bot battles won
    bot_battles_lost INTEGER NOT NULL DEFAULT 0,           -- Total bot battles lost
    
    -- Timestamps
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT unique_player_progress UNIQUE(player_id),
    CONSTRAINT valid_current_level CHECK (current_level >= 1 AND current_level <= 100),
    CONSTRAINT valid_highest_level CHECK (highest_level_unlocked >= 1 AND highest_level_unlocked <= 100),
    CONSTRAINT valid_total_completed CHECK (total_levels_completed >= 0 AND total_levels_completed <= 100),
    CONSTRAINT valid_current_zone CHECK (current_zone >= 1 AND current_zone <= 10),
    CONSTRAINT valid_zones_completed CHECK (zones_completed >= 0 AND zones_completed <= 10)
);

-- Indexes for fast lookups
CREATE INDEX idx_player_level_progress_player_id ON player_level_progress(player_id);
CREATE INDEX idx_player_level_progress_current_level ON player_level_progress(current_level);
CREATE INDEX idx_player_level_progress_updated_at ON player_level_progress(updated_at);

-- ============================================================================
-- TABLE 2: level_completions
-- ============================================================================
-- Purpose: Track individual level completion attempts and results
-- Multiple rows per player (one per level completion)
-- INCLUDES CONTINUE TRACKING for difficulty analysis
-- ============================================================================

CREATE TABLE IF NOT EXISTS level_completions (
    -- Primary Key
    id SERIAL PRIMARY KEY,
    
    -- Foreign Keys
    player_id INTEGER NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    level_id INTEGER NOT NULL,                             -- Level number (1-100)
    
    -- Completion Details
    completed BOOLEAN NOT NULL DEFAULT FALSE,              -- TRUE if level was completed
    objective_type VARCHAR(50) NOT NULL,                   -- 'pass_obstacles', 'survive_time', 'beat_bot'
    objective_target INTEGER NOT NULL,                     -- Target value (e.g., 5 obstacles, 30 seconds)
    objective_achieved INTEGER NOT NULL DEFAULT 0,         -- Actual value achieved
    
    -- Performance Metrics
    attempts INTEGER NOT NULL DEFAULT 1,                   -- Number of attempts before completion
    time_taken_seconds INTEGER,                            -- Time to complete (NULL if failed)
    
    -- 🎯 CONTINUE TRACKING (Your Request - for difficulty analysis)
    continues_used INTEGER NOT NULL DEFAULT 0,             -- Total continues used in this attempt
    continues_ad INTEGER NOT NULL DEFAULT 0,               -- Continues via watching ads
    continues_gems INTEGER NOT NULL DEFAULT 0,             -- Continues via spending gems
    
    -- Bot Battle Specific (NULL if not a bot level)
    bot_battle BOOLEAN NOT NULL DEFAULT FALSE,
    bot_defeated BOOLEAN,                                  -- TRUE if player won, FALSE if bot won
    bot_name VARCHAR(100),                                 -- Name of the bot
    
    -- Rewards
    coins_earned INTEGER NOT NULL DEFAULT 0,
    gems_earned INTEGER NOT NULL DEFAULT 0,
    special_reward VARCHAR(100),                           -- e.g., 'exclusive_skin_frozen_ace'
    
    -- Timestamps
    completed_at TIMESTAMP NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_level_id CHECK (level_id >= 1 AND level_id <= 100),
    CONSTRAINT valid_objective_type CHECK (objective_type IN ('pass_obstacles', 'survive_time', 'beat_bot')),
    CONSTRAINT valid_objective_target CHECK (objective_target > 0),
    CONSTRAINT valid_attempts CHECK (attempts > 0),
    CONSTRAINT valid_continues CHECK (continues_used >= 0 AND continues_used <= 5),
    CONSTRAINT valid_continues_breakdown CHECK (continues_ad + continues_gems = continues_used),
    CONSTRAINT valid_coins CHECK (coins_earned >= 0),
    CONSTRAINT valid_gems CHECK (gems_earned >= 0)
);

-- Indexes for analytics and lookups
CREATE INDEX idx_level_completions_player_id ON level_completions(player_id);
CREATE INDEX idx_level_completions_level_id ON level_completions(level_id);
CREATE INDEX idx_level_completions_completed ON level_completions(completed);
CREATE INDEX idx_level_completions_completed_at ON level_completions(completed_at);
CREATE INDEX idx_level_completions_bot_battle ON level_completions(bot_battle);

-- Composite index for player's level history
CREATE INDEX idx_level_completions_player_level ON level_completions(player_id, level_id);

-- Index for difficulty analysis (continues tracking)
CREATE INDEX idx_level_completions_continues ON level_completions(level_id, continues_used);

-- ============================================================================
-- TABLE 3: level_attempts
-- ============================================================================
-- Purpose: Track EVERY attempt at a level (including failures)
-- This gives us granular data for difficulty balancing
-- ============================================================================

CREATE TABLE IF NOT EXISTS level_attempts (
    -- Primary Key
    id SERIAL PRIMARY KEY,
    
    -- Foreign Keys
    player_id INTEGER NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    level_id INTEGER NOT NULL,
    
    -- Attempt Details
    attempt_number INTEGER NOT NULL,                       -- 1st attempt, 2nd attempt, etc.
    success BOOLEAN NOT NULL,                              -- TRUE if completed, FALSE if failed
    
    -- Performance
    score_achieved INTEGER NOT NULL DEFAULT 0,             -- Obstacles passed or seconds survived
    continues_used INTEGER NOT NULL DEFAULT 0,             -- Continues used in this attempt
    continues_ad INTEGER NOT NULL DEFAULT 0,
    continues_gems INTEGER NOT NULL DEFAULT 0,
    
    -- Failure Reason (if failed)
    failure_reason VARCHAR(100),                           -- 'collision', 'out_of_continues', 'quit'
    
    -- Timestamps
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMP,
    duration_seconds INTEGER,
    
    -- Constraints
    CONSTRAINT valid_level_attempt_id CHECK (level_id >= 1 AND level_id <= 100),
    CONSTRAINT valid_attempt_number CHECK (attempt_number > 0),
    CONSTRAINT valid_attempt_continues CHECK (continues_used >= 0 AND continues_used <= 5),
    CONSTRAINT valid_attempt_breakdown CHECK (continues_ad + continues_gems = continues_used)
);

-- Indexes for analytics
CREATE INDEX idx_level_attempts_player_id ON level_attempts(player_id);
CREATE INDEX idx_level_attempts_level_id ON level_attempts(level_id);
CREATE INDEX idx_level_attempts_success ON level_attempts(success);
CREATE INDEX idx_level_attempts_started_at ON level_attempts(started_at);

-- Composite index for player's attempt history
CREATE INDEX idx_level_attempts_player_level ON level_attempts(player_id, level_id);

-- ============================================================================
-- VIEWS FOR ANALYTICS
-- ============================================================================

-- View 1: Level Difficulty Analysis (based on continues used)
CREATE OR REPLACE VIEW level_difficulty_stats AS
SELECT 
    level_id,
    COUNT(*) as total_attempts,
    COUNT(CASE WHEN completed = TRUE THEN 1 END) as completions,
    ROUND(COUNT(CASE WHEN completed = TRUE THEN 1 END)::NUMERIC / COUNT(*)::NUMERIC * 100, 2) as completion_rate,
    ROUND(AVG(continues_used), 2) as avg_continues_used,
    ROUND(AVG(CASE WHEN completed = TRUE THEN continues_used END), 2) as avg_continues_on_success,
    MAX(continues_used) as max_continues_used,
    COUNT(CASE WHEN continues_used = 0 AND completed = TRUE THEN 1 END) as first_try_completions,
    ROUND(AVG(attempts), 2) as avg_attempts_to_complete
FROM level_completions
GROUP BY level_id
ORDER BY level_id;

-- View 2: Player Story Mode Summary
CREATE OR REPLACE VIEW player_story_summary AS
SELECT 
    p.id as player_id,
    p.display_name,
    plp.current_level,
    plp.highest_level_unlocked,
    plp.total_levels_completed,
    plp.current_zone,
    plp.zones_completed,
    plp.total_coins_earned,
    plp.total_gems_earned,
    plp.bot_battles_won,
    plp.bot_battles_lost,
    ROUND(plp.bot_battles_won::NUMERIC / NULLIF(plp.bot_battles_won + plp.bot_battles_lost, 0)::NUMERIC * 100, 2) as bot_win_rate,
    COUNT(lc.id) as total_level_attempts,
    SUM(lc.continues_used) as total_continues_used,
    SUM(lc.continues_ad) as total_continues_ad,
    SUM(lc.continues_gems) as total_continues_gems,
    plp.updated_at as last_played
FROM players p
LEFT JOIN player_level_progress plp ON p.id = plp.player_id
LEFT JOIN level_completions lc ON p.id = lc.player_id
GROUP BY p.id, p.display_name, plp.current_level, plp.highest_level_unlocked, 
         plp.total_levels_completed, plp.current_zone, plp.zones_completed,
         plp.total_coins_earned, plp.total_gems_earned, plp.bot_battles_won, 
         plp.bot_battles_lost, plp.updated_at;

-- View 3: Zone Completion Stats
CREATE OR REPLACE VIEW zone_completion_stats AS
SELECT 
    CASE 
        WHEN level_id BETWEEN 1 AND 10 THEN 1
        WHEN level_id BETWEEN 11 AND 20 THEN 2
        WHEN level_id BETWEEN 21 AND 30 THEN 3
        WHEN level_id BETWEEN 31 AND 40 THEN 4
        WHEN level_id BETWEEN 41 AND 50 THEN 5
    END as zone,
    COUNT(DISTINCT player_id) as players_reached,
    COUNT(CASE WHEN completed = TRUE THEN 1 END) as total_completions,
    ROUND(AVG(continues_used), 2) as avg_continues_per_level,
    ROUND(AVG(time_taken_seconds), 2) as avg_completion_time
FROM level_completions
WHERE level_id <= 50
GROUP BY zone
ORDER BY zone;

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function: Update player progress after level completion
CREATE OR REPLACE FUNCTION update_player_story_progress(
    p_player_id INTEGER,
    p_level_id INTEGER,
    p_completed BOOLEAN,
    p_coins_earned INTEGER,
    p_gems_earned INTEGER,
    p_bot_defeated BOOLEAN DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_new_zone INTEGER;
BEGIN
    -- Calculate new zone based on level
    v_new_zone := CEIL(p_level_id / 10.0)::INTEGER;
    
    -- Update or insert player progress
    INSERT INTO player_level_progress (
        player_id,
        current_level,
        highest_level_unlocked,
        total_levels_completed,
        current_zone,
        total_coins_earned,
        total_gems_earned,
        bot_battles_won,
        bot_battles_lost
    )
    VALUES (
        p_player_id,
        p_level_id,
        p_level_id,
        CASE WHEN p_completed THEN 1 ELSE 0 END,
        v_new_zone,
        p_coins_earned,
        p_gems_earned,
        CASE WHEN p_bot_defeated = TRUE THEN 1 ELSE 0 END,
        CASE WHEN p_bot_defeated = FALSE THEN 1 ELSE 0 END
    )
    ON CONFLICT (player_id) DO UPDATE SET
        current_level = GREATEST(player_level_progress.current_level, p_level_id),
        highest_level_unlocked = GREATEST(player_level_progress.highest_level_unlocked, p_level_id + 1),
        total_levels_completed = player_level_progress.total_levels_completed + CASE WHEN p_completed THEN 1 ELSE 0 END,
        current_zone = GREATEST(player_level_progress.current_zone, v_new_zone),
        zones_completed = CASE WHEN p_level_id % 10 = 0 AND p_completed THEN player_level_progress.zones_completed + 1 ELSE player_level_progress.zones_completed END,
        total_coins_earned = player_level_progress.total_coins_earned + p_coins_earned,
        total_gems_earned = player_level_progress.total_gems_earned + p_gems_earned,
        bot_battles_won = player_level_progress.bot_battles_won + CASE WHEN p_bot_defeated = TRUE THEN 1 ELSE 0 END,
        bot_battles_lost = player_level_progress.bot_battles_lost + CASE WHEN p_bot_defeated = FALSE THEN 1 ELSE 0 END,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Function: Get player's next unlocked level
CREATE OR REPLACE FUNCTION get_next_level(p_player_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
    v_highest_unlocked INTEGER;
BEGIN
    SELECT highest_level_unlocked INTO v_highest_unlocked
    FROM player_level_progress
    WHERE player_id = p_player_id;
    
    -- If player doesn't exist, return level 1
    IF v_highest_unlocked IS NULL THEN
        RETURN 1;
    END IF;
    
    RETURN v_highest_unlocked;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_player_level_progress_updated_at
    BEFORE UPDATE ON player_level_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SAMPLE QUERIES FOR TESTING
-- ============================================================================

-- Query 1: Get player's story mode progress
-- SELECT * FROM player_story_summary WHERE player_id = 1;

-- Query 2: Get difficulty stats for a specific level
-- SELECT * FROM level_difficulty_stats WHERE level_id = 7;

-- Query 3: Find levels that are too hard (high continue usage)
-- SELECT level_id, avg_continues_used, completion_rate 
-- FROM level_difficulty_stats 
-- WHERE avg_continues_used > 2.5 
-- ORDER BY avg_continues_used DESC;

-- Query 4: Find levels that are too easy (low continue usage, high first-try rate)
-- SELECT level_id, avg_continues_used, completion_rate, first_try_completions
-- FROM level_difficulty_stats 
-- WHERE avg_continues_used < 0.5 AND completion_rate > 80
-- ORDER BY completion_rate DESC;

-- Query 5: Get all attempts for a specific player on a specific level
-- SELECT * FROM level_attempts 
-- WHERE player_id = 1 AND level_id = 7 
-- ORDER BY attempt_number;

-- ============================================================================
-- MIGRATION NOTES
-- ============================================================================
-- 
-- To apply this schema to Railway:
-- 1. Connect to Railway PostgreSQL: railway connect
-- 2. Run this SQL file: \i story_mode_schema.sql
-- 3. Verify tables created: \dt
-- 4. Test with sample data
-- 
-- To rollback:
-- DROP TABLE IF EXISTS level_attempts CASCADE;
-- DROP TABLE IF EXISTS level_completions CASCADE;
-- DROP TABLE IF EXISTS player_level_progress CASCADE;
-- DROP VIEW IF EXISTS level_difficulty_stats CASCADE;
-- DROP VIEW IF EXISTS player_story_summary CASCADE;
-- DROP VIEW IF EXISTS zone_completion_stats CASCADE;
-- DROP FUNCTION IF EXISTS update_player_story_progress CASCADE;
-- DROP FUNCTION IF EXISTS get_next_level CASCADE;
-- DROP FUNCTION IF EXISTS update_updated_at_column CASCADE;
-- 
-- ============================================================================
