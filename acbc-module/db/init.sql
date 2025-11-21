-- ACBC Voter Intelligence Module - Database Schema
-- Version: 1.0
-- Created for Campaign Stack integration

-- Use the limesurvey database (created by main container)
USE limesurvey;

-- ============================================================================
-- Core ACBC Tables
-- ============================================================================

-- Survey responses with utility calculations
CREATE TABLE IF NOT EXISTS acbc_surveys (
    id INT AUTO_INCREMENT PRIMARY KEY,
    respondent_id VARCHAR(100) NOT NULL,
    limesurvey_response_id INT,
    voter_file_match_id INT,
    civicrm_contact_id INT,
    completion_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    utilities JSON COMMENT 'Format: {attribute: {level: score}}',
    engagement_tier INT COMMENT '1-5 scale, 5 = highest engagement',
    trust_affiliations JSON COMMENT 'Organizations/leaders the voter trusts',
    match_confidence DECIMAL(3,2) COMMENT '0.00-1.00 confidence in voter match',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_respondent (respondent_id),
    INDEX idx_civicrm (civicrm_contact_id),
    INDEX idx_completion (completion_date),
    INDEX idx_engagement (engagement_tier)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Voter segments based on utility profiles
CREATE TABLE IF NOT EXISTS acbc_segments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    segment_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    definition JSON COMMENT 'Utility thresholds + demographic filters',
    size INT DEFAULT 0 COMMENT 'Number of contacts in segment',
    civicrm_group_id INT COMMENT 'Linked CiviCRM group ID',
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_active (active),
    INDEX idx_size (size)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Segment membership (many-to-many)
CREATE TABLE IF NOT EXISTS acbc_segment_members (
    id INT AUTO_INCREMENT PRIMARY KEY,
    segment_id INT NOT NULL,
    civicrm_contact_id INT NOT NULL,
    survey_id INT NOT NULL,
    match_score DECIMAL(5,4) COMMENT 'How well contact matches segment',
    added_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (segment_id) REFERENCES acbc_segments(id) ON DELETE CASCADE,
    FOREIGN KEY (survey_id) REFERENCES acbc_surveys(id) ON DELETE CASCADE,
    UNIQUE KEY unique_segment_contact (segment_id, civicrm_contact_id),
    INDEX idx_contact (civicrm_contact_id),
    INDEX idx_segment (segment_id),
    INDEX idx_score (match_score)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Personalization rules
CREATE TABLE IF NOT EXISTS acbc_personalization_rules (
    id INT AUTO_INCREMENT PRIMARY KEY,
    rule_name VARCHAR(100) NOT NULL,
    segment_id INT,
    content_type ENUM('email', 'social', 'web', 'sms') NOT NULL,
    content_template VARCHAR(255) COMMENT 'Template ID or file path',
    priority_order INT DEFAULT 100,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (segment_id) REFERENCES acbc_segments(id) ON DELETE CASCADE,
    INDEX idx_content_type (content_type),
    INDEX idx_active (active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Engagement profiles
CREATE TABLE IF NOT EXISTS acbc_engagement_profiles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    civicrm_contact_id INT NOT NULL UNIQUE,
    donor_tier INT COMMENT '0-5: 0=non-donor, 5=major donor',
    volunteer_capacity INT COMMENT '0-5: 0=none, 5=full-time volunteer',
    influence_potential INT COMMENT '0-5: social/community influence level',
    share_willingness ENUM('private', 'limited', 'public') DEFAULT 'private',
    preferred_contact ENUM('email', 'sms', 'phone', 'social', 'in_person'),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_contact (civicrm_contact_id),
    INDEX idx_donor (donor_tier),
    INDEX idx_volunteer (volunteer_capacity),
    INDEX idx_influence (influence_potential)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Analytics cache for performance
CREATE TABLE IF NOT EXISTS acbc_analytics_cache (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cache_key VARCHAR(255) NOT NULL UNIQUE,
    cache_value LONGTEXT,
    cache_type ENUM('segment_summary', 'utility_distribution', 'engagement_stats') NOT NULL,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_key (cache_key),
    INDEX idx_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Webhook log for debugging
CREATE TABLE IF NOT EXISTS acbc_webhook_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    webhook_type ENUM('survey_complete', 'segment_update', 'personalization_request') NOT NULL,
    payload JSON,
    response JSON,
    status ENUM('success', 'failed', 'pending') DEFAULT 'pending',
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type (webhook_type),
    INDEX idx_status (status),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Initial Data: Default Segments
-- ============================================================================

INSERT INTO acbc_segments (segment_name, description, definition, active) VALUES
('high_engagement', 'Highly engaged supporters',
 '{"engagement_tier": {"min": 4}, "donor_tier": {"min": 3}}', TRUE),

('environmental_focus', 'Environmental policy priorities',
 '{"utilities": {"environmental": {"min": 0.7}}}', TRUE),

('economic_focus', 'Economic policy priorities',
 '{"utilities": {"economic": {"min": 0.7}}}', TRUE),

('healthcare_focus', 'Healthcare policy priorities',
 '{"utilities": {"healthcare": {"min": 0.7}}}', TRUE),

('persuadable_voters', 'Moderate voters open to persuasion',
 '{"engagement_tier": {"range": [2, 4]}, "utilities": {"variance": {"max": 0.3}}}', TRUE),

('volunteer_potential', 'High potential volunteers',
 '{"volunteer_capacity": {"min": 3}, "share_willingness": ["public", "limited"]}', TRUE);

-- ============================================================================
-- Views for Common Queries
-- ============================================================================

-- Segment summary view
CREATE OR REPLACE VIEW v_segment_summary AS
SELECT
    s.segment_name,
    s.description,
    COUNT(DISTINCT sm.civicrm_contact_id) as member_count,
    AVG(sm.match_score) as avg_match_score,
    s.last_updated
FROM acbc_segments s
LEFT JOIN acbc_segment_members sm ON s.id = sm.segment_id
WHERE s.active = TRUE
GROUP BY s.id, s.segment_name, s.description, s.last_updated;

-- Engagement overview
CREATE OR REPLACE VIEW v_engagement_overview AS
SELECT
    COUNT(*) as total_contacts,
    AVG(donor_tier) as avg_donor_tier,
    AVG(volunteer_capacity) as avg_volunteer_capacity,
    AVG(influence_potential) as avg_influence,
    COUNT(CASE WHEN donor_tier >= 4 THEN 1 END) as high_donors,
    COUNT(CASE WHEN volunteer_capacity >= 4 THEN 1 END) as active_volunteers,
    COUNT(CASE WHEN influence_potential >= 4 THEN 1 END) as influencers
FROM acbc_engagement_profiles;

-- Recent survey completions
CREATE OR REPLACE VIEW v_recent_surveys AS
SELECT
    s.id,
    s.respondent_id,
    s.civicrm_contact_id,
    s.completion_date,
    s.engagement_tier,
    s.match_confidence,
    COUNT(DISTINCT sm.segment_id) as segment_matches
FROM acbc_surveys s
LEFT JOIN acbc_segment_members sm ON s.civicrm_contact_id = sm.civicrm_contact_id
WHERE s.completion_date >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY s.id
ORDER BY s.completion_date DESC;

-- ============================================================================
-- Stored Procedures
-- ============================================================================

DELIMITER //

-- Calculate and update segment membership for a contact
CREATE PROCEDURE sp_update_segment_membership(IN p_contact_id INT, IN p_survey_id INT)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_segment_id INT;
    DECLARE v_match_score DECIMAL(5,4);
    DECLARE cur CURSOR FOR
        SELECT id FROM acbc_segments WHERE active = TRUE;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Remove existing memberships for this contact
    DELETE FROM acbc_segment_members WHERE civicrm_contact_id = p_contact_id;

    -- Calculate match for each active segment
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_segment_id;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Simplified match calculation (would be more complex in production)
        SET v_match_score = 0.5; -- Placeholder

        -- Insert if match score is significant
        IF v_match_score > 0.3 THEN
            INSERT INTO acbc_segment_members (segment_id, civicrm_contact_id, survey_id, match_score)
            VALUES (v_segment_id, p_contact_id, p_survey_id, v_match_score);
        END IF;
    END LOOP;
    CLOSE cur;

    -- Update segment sizes
    UPDATE acbc_segments s
    SET size = (SELECT COUNT(DISTINCT civicrm_contact_id)
                FROM acbc_segment_members
                WHERE segment_id = s.id)
    WHERE active = TRUE;
END//

DELIMITER ;

-- ============================================================================
-- Indexes for Performance
-- ============================================================================

-- Additional composite indexes
CREATE INDEX idx_survey_match ON acbc_surveys(civicrm_contact_id, completion_date);
CREATE INDEX idx_segment_active_size ON acbc_segments(active, size);
CREATE INDEX idx_engagement_composite ON acbc_engagement_profiles(donor_tier, volunteer_capacity, influence_potential);

-- ============================================================================
-- Completion Message
-- ============================================================================

SELECT 'ACBC Database Schema Initialized Successfully' AS Status;
SELECT COUNT(*) AS DefaultSegments FROM acbc_segments;
