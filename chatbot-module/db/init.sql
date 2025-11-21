-- AI Policy Chatbot Module - Database Schema
-- Version: 1.0
-- Created for Campaign Stack integration

-- Create dedicated database for chatbot
CREATE DATABASE IF NOT EXISTS chatbot;
USE chatbot;

-- ============================================================================
-- Core Chatbot Tables
-- ============================================================================

-- Conversation sessions
CREATE TABLE IF NOT EXISTS chatbot_conversations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    session_id VARCHAR(100) NOT NULL UNIQUE,
    civicrm_contact_id INT COMMENT 'Linked contact if authenticated',
    consent_given BOOLEAN DEFAULT FALSE,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP NULL,
    total_messages INT DEFAULT 0,
    detected_sophistication ENUM('low', 'medium', 'high') COMMENT 'Overall conversation sophistication',
    primary_topics JSON COMMENT 'Array of discussed topics',
    region VARCHAR(100) COMMENT 'Voter region/district',
    user_agent TEXT,
    ip_address VARCHAR(45) COMMENT 'Anonymized if no consent',
    INDEX idx_contact (civicrm_contact_id),
    INDEX idx_session (session_id),
    INDEX idx_started (started_at),
    INDEX idx_sophistication (detected_sophistication)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Individual messages within conversations
CREATE TABLE IF NOT EXISTS chatbot_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    conversation_id INT NOT NULL,
    message_type ENUM('user', 'assistant') NOT NULL,
    message_text TEXT NOT NULL,
    response_sophistication ENUM('low', 'medium', 'high') COMMENT 'Explanation level provided',
    ai_backend ENUM('ollama', 'anthropic', 'openai', 'google') COMMENT 'Which AI processed this',
    cost DECIMAL(10,6) DEFAULT 0.000000 COMMENT 'Cost in USD for this message',
    tokens_used INT COMMENT 'Total tokens (prompt + completion)',
    processing_time_ms INT COMMENT 'Response generation time',
    wikijs_sources JSON COMMENT 'Wiki.js pages referenced',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES chatbot_conversations(id) ON DELETE CASCADE,
    INDEX idx_conversation (conversation_id),
    INDEX idx_type (message_type),
    INDEX idx_backend (ai_backend),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tracked misconceptions
CREATE TABLE IF NOT EXISTS chatbot_misconceptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    misconception_key VARCHAR(100) NOT NULL UNIQUE,
    false_belief TEXT NOT NULL,
    correct_explanation TEXT NOT NULL,
    policy_area VARCHAR(100) COMMENT 'healthcare, economy, environment, etc.',
    detection_count INT DEFAULT 0,
    regions JSON COMMENT 'Districts/regions where this appears',
    first_detected TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_detected TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    correction_effectiveness DECIMAL(3,2) COMMENT '0.00-1.00 how well correction works',
    active BOOLEAN DEFAULT TRUE,
    INDEX idx_key (misconception_key),
    INDEX idx_policy (policy_area),
    INDEX idx_count (detection_count),
    INDEX idx_active (active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Misconception occurrences (many-to-many with conversations)
CREATE TABLE IF NOT EXISTS chatbot_misconception_occurrences (
    id INT AUTO_INCREMENT PRIMARY KEY,
    misconception_id INT NOT NULL,
    conversation_id INT NOT NULL,
    message_id INT NOT NULL,
    corrected BOOLEAN DEFAULT FALSE COMMENT 'Was correction provided in conversation?',
    user_satisfied BOOLEAN COMMENT 'Follow-up suggests understanding',
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (misconception_id) REFERENCES chatbot_misconceptions(id) ON DELETE CASCADE,
    FOREIGN KEY (conversation_id) REFERENCES chatbot_conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (message_id) REFERENCES chatbot_messages(id) ON DELETE CASCADE,
    INDEX idx_misconception (misconception_id),
    INDEX idx_conversation (conversation_id),
    INDEX idx_corrected (corrected)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Cost tracking and budget management
CREATE TABLE IF NOT EXISTS chatbot_costs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    backend ENUM('ollama', 'anthropic', 'openai', 'google') NOT NULL,
    cost_usd DECIMAL(10,6) NOT NULL,
    tokens_used INT NOT NULL,
    message_id INT COMMENT 'Link to specific message',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (message_id) REFERENCES chatbot_messages(id) ON DELETE SET NULL,
    INDEX idx_backend (backend),
    INDEX idx_created (created_at),
    INDEX idx_message (message_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Monthly budget tracking
CREATE TABLE IF NOT EXISTS chatbot_budget_tracking (
    id INT AUTO_INCREMENT PRIMARY KEY,
    month_year VARCHAR(7) NOT NULL COMMENT 'Format: YYYY-MM',
    backend ENUM('ollama', 'anthropic', 'openai', 'google', 'total') NOT NULL,
    budget_limit DECIMAL(10,2) NOT NULL,
    current_spend DECIMAL(10,6) DEFAULT 0.000000,
    query_count INT DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_month_backend (month_year, backend),
    INDEX idx_month (month_year),
    INDEX idx_backend (backend)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- A/B message testing
CREATE TABLE IF NOT EXISTS chatbot_ab_tests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    test_name VARCHAR(100) NOT NULL,
    policy_area VARCHAR(100) NOT NULL,
    variant_a TEXT NOT NULL COMMENT 'Explanation variant A',
    variant_b TEXT NOT NULL COMMENT 'Explanation variant B',
    variant_a_uses INT DEFAULT 0,
    variant_b_uses INT DEFAULT 0,
    variant_a_satisfaction DECIMAL(3,2) DEFAULT 0.00 COMMENT 'Avg satisfaction 0.00-1.00',
    variant_b_satisfaction DECIMAL(3,2) DEFAULT 0.00,
    variant_a_followups DECIMAL(5,2) DEFAULT 0.00 COMMENT 'Avg follow-up questions',
    variant_b_followups DECIMAL(5,2) DEFAULT 0.00,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP NULL,
    winner ENUM('a', 'b', 'tie', 'undetermined') COMMENT 'Statistical winner',
    INDEX idx_test_name (test_name),
    INDEX idx_policy (policy_area),
    INDEX idx_active (active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Analytics aggregations (for performance)
CREATE TABLE IF NOT EXISTS chatbot_analytics_daily (
    id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL,
    total_conversations INT DEFAULT 0,
    total_messages INT DEFAULT 0,
    avg_messages_per_conversation DECIMAL(5,2) DEFAULT 0.00,
    unique_contacts INT DEFAULT 0,
    consent_rate DECIMAL(3,2) DEFAULT 0.00 COMMENT 'Percentage who consented',
    sophistication_low INT DEFAULT 0,
    sophistication_medium INT DEFAULT 0,
    sophistication_high INT DEFAULT 0,
    total_cost DECIMAL(10,6) DEFAULT 0.000000,
    ollama_queries INT DEFAULT 0,
    anthropic_queries INT DEFAULT 0,
    openai_queries INT DEFAULT 0,
    google_queries INT DEFAULT 0,
    top_topics JSON COMMENT 'Array of {topic: count}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_date (date),
    INDEX idx_date (date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Wiki.js content cache
CREATE TABLE IF NOT EXISTS chatbot_wikijs_cache (
    id INT AUTO_INCREMENT PRIMARY KEY,
    page_id INT NOT NULL COMMENT 'Wiki.js page ID',
    page_path VARCHAR(255) NOT NULL,
    page_title VARCHAR(255) NOT NULL,
    content_simple TEXT COMMENT 'Low-sophistication content',
    content_medium TEXT COMMENT 'Medium-sophistication content',
    content_detailed TEXT COMMENT 'High-sophistication content',
    tags JSON COMMENT 'Page tags from Wiki.js',
    region VARCHAR(100) COMMENT 'Regional context if applicable',
    last_fetched TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    expires_at TIMESTAMP COMMENT 'Cache expiration',
    version INT DEFAULT 1 COMMENT 'Wiki.js page version',
    UNIQUE KEY unique_page (page_id),
    INDEX idx_path (page_path),
    INDEX idx_tags (tags(255)),
    INDEX idx_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Privacy and consent logs
CREATE TABLE IF NOT EXISTS chatbot_consent_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    session_id VARCHAR(100) NOT NULL,
    civicrm_contact_id INT COMMENT 'If authenticated',
    consent_given BOOLEAN NOT NULL,
    consent_type ENUM('full', 'anonymous', 'declined') NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP NULL,
    FOREIGN KEY (session_id) REFERENCES chatbot_conversations(session_id) ON DELETE CASCADE,
    INDEX idx_session (session_id),
    INDEX idx_contact (civicrm_contact_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Initial Data: Default Misconceptions
-- ============================================================================

INSERT INTO chatbot_misconceptions (misconception_key, false_belief, correct_explanation, policy_area) VALUES
('hc_eliminate_private',
 'The healthcare plan eliminates private insurance',
 'The plan creates a public option that competes alongside private insurance. You can choose to keep your current insurance or switch to the public option.',
 'healthcare'),

('env_job_loss',
 'Environmental policies will eliminate jobs',
 'Our climate plan creates 2 million new jobs in clean energy, infrastructure, and manufacturing. We provide job training and transition support for workers in traditional energy sectors.',
 'environment'),

('tax_middle_class',
 'Tax plan raises taxes on middle class',
 'The tax plan only affects individuals earning over $400,000/year. 95% of families will see no tax increase, and many will receive tax credits.',
 'economy'),

('edu_free_unfair',
 'Free college is unfair to those who already paid',
 'Just as public high school didn''t diminish the value of earlier private education, expanding educational access benefits everyone through a more skilled workforce and stronger economy.',
 'education');

-- ============================================================================
-- Views for Common Queries
-- ============================================================================

-- Active conversations summary
CREATE OR REPLACE VIEW v_active_conversations AS
SELECT
    c.id,
    c.session_id,
    c.civicrm_contact_id,
    c.started_at,
    c.total_messages,
    c.detected_sophistication,
    c.primary_topics,
    COUNT(DISTINCT m.id) as message_count,
    MAX(m.created_at) as last_message_at
FROM chatbot_conversations c
LEFT JOIN chatbot_messages m ON c.id = m.conversation_id
WHERE c.ended_at IS NULL
GROUP BY c.id
ORDER BY c.started_at DESC;

-- Daily cost summary
CREATE OR REPLACE VIEW v_daily_costs AS
SELECT
    DATE(created_at) as date,
    backend,
    COUNT(*) as query_count,
    SUM(cost_usd) as total_cost,
    AVG(cost_usd) as avg_cost_per_query,
    SUM(tokens_used) as total_tokens
FROM chatbot_costs
GROUP BY DATE(created_at), backend
ORDER BY date DESC, backend;

-- Misconception leaderboard
CREATE OR REPLACE VIEW v_top_misconceptions AS
SELECT
    m.misconception_key,
    m.false_belief,
    m.policy_area,
    COUNT(o.id) as occurrence_count,
    COUNT(CASE WHEN o.corrected = TRUE THEN 1 END) as correction_count,
    COUNT(CASE WHEN o.user_satisfied = TRUE THEN 1 END) as satisfied_count,
    m.correction_effectiveness,
    MAX(o.detected_at) as last_seen
FROM chatbot_misconceptions m
LEFT JOIN chatbot_misconception_occurrences o ON m.id = o.misconception_id
WHERE m.active = TRUE
GROUP BY m.id
ORDER BY occurrence_count DESC
LIMIT 20;

-- Sophistication distribution
CREATE OR REPLACE VIEW v_sophistication_stats AS
SELECT
    detected_sophistication as level,
    COUNT(*) as conversation_count,
    AVG(total_messages) as avg_messages,
    COUNT(DISTINCT civicrm_contact_id) as unique_contacts
FROM chatbot_conversations
WHERE detected_sophistication IS NOT NULL
GROUP BY detected_sophistication;

-- ============================================================================
-- Stored Procedures
-- ============================================================================

DELIMITER //

-- Update conversation totals
CREATE PROCEDURE sp_update_conversation_stats(IN p_conversation_id INT)
BEGIN
    UPDATE chatbot_conversations c
    SET total_messages = (
        SELECT COUNT(*)
        FROM chatbot_messages
        WHERE conversation_id = p_conversation_id
    )
    WHERE c.id = p_conversation_id;
END//

-- Check and enforce budget limits
CREATE PROCEDURE sp_check_budget(
    IN p_backend VARCHAR(20),
    IN p_month_year VARCHAR(7),
    OUT p_budget_available BOOLEAN
)
BEGIN
    DECLARE v_budget_limit DECIMAL(10,2);
    DECLARE v_current_spend DECIMAL(10,6);

    SELECT budget_limit, current_spend
    INTO v_budget_limit, v_current_spend
    FROM chatbot_budget_tracking
    WHERE month_year = p_month_year
    AND backend = p_backend;

    IF v_current_spend < v_budget_limit THEN
        SET p_budget_available = TRUE;
    ELSE
        SET p_budget_available = FALSE;
    END IF;
END//

-- Log message cost and update budget
CREATE PROCEDURE sp_log_message_cost(
    IN p_message_id INT,
    IN p_backend VARCHAR(20),
    IN p_cost DECIMAL(10,6),
    IN p_tokens INT
)
BEGIN
    DECLARE v_month_year VARCHAR(7);
    SET v_month_year = DATE_FORMAT(NOW(), '%Y-%m');

    -- Insert cost record
    INSERT INTO chatbot_costs (backend, cost_usd, tokens_used, message_id)
    VALUES (p_backend, p_cost, p_tokens, p_message_id);

    -- Update budget tracking
    INSERT INTO chatbot_budget_tracking (month_year, backend, budget_limit, current_spend, query_count)
    VALUES (v_month_year, p_backend, 100.00, p_cost, 1)
    ON DUPLICATE KEY UPDATE
        current_spend = current_spend + p_cost,
        query_count = query_count + 1;

    -- Update total budget
    INSERT INTO chatbot_budget_tracking (month_year, backend, budget_limit, current_spend, query_count)
    VALUES (v_month_year, 'total', 100.00, p_cost, 1)
    ON DUPLICATE KEY UPDATE
        current_spend = current_spend + p_cost,
        query_count = query_count + 1;
END//

-- Generate daily analytics
CREATE PROCEDURE sp_generate_daily_analytics(IN p_date DATE)
BEGIN
    INSERT INTO chatbot_analytics_daily (
        date,
        total_conversations,
        total_messages,
        avg_messages_per_conversation,
        unique_contacts,
        consent_rate,
        sophistication_low,
        sophistication_medium,
        sophistication_high,
        total_cost,
        ollama_queries,
        anthropic_queries,
        openai_queries,
        google_queries
    )
    SELECT
        p_date,
        COUNT(DISTINCT c.id),
        COUNT(m.id),
        COALESCE(AVG(c.total_messages), 0),
        COUNT(DISTINCT c.civicrm_contact_id),
        AVG(CASE WHEN c.consent_given = TRUE THEN 1.0 ELSE 0.0 END),
        SUM(CASE WHEN c.detected_sophistication = 'low' THEN 1 ELSE 0 END),
        SUM(CASE WHEN c.detected_sophistication = 'medium' THEN 1 ELSE 0 END),
        SUM(CASE WHEN c.detected_sophistication = 'high' THEN 1 ELSE 0 END),
        COALESCE(SUM(cost.cost_usd), 0),
        SUM(CASE WHEN m.ai_backend = 'ollama' THEN 1 ELSE 0 END),
        SUM(CASE WHEN m.ai_backend = 'anthropic' THEN 1 ELSE 0 END),
        SUM(CASE WHEN m.ai_backend = 'openai' THEN 1 ELSE 0 END),
        SUM(CASE WHEN m.ai_backend = 'google' THEN 1 ELSE 0 END)
    FROM chatbot_conversations c
    LEFT JOIN chatbot_messages m ON c.id = m.conversation_id
    LEFT JOIN chatbot_costs cost ON cost.message_id = m.id
    WHERE DATE(c.started_at) = p_date
    ON DUPLICATE KEY UPDATE
        total_conversations = VALUES(total_conversations),
        total_messages = VALUES(total_messages),
        avg_messages_per_conversation = VALUES(avg_messages_per_conversation);
END//

DELIMITER ;

-- ============================================================================
-- Indexes for Performance
-- ============================================================================

-- Composite indexes for common queries
CREATE INDEX idx_conversation_contact_date ON chatbot_conversations(civicrm_contact_id, started_at);
CREATE INDEX idx_message_conversation_created ON chatbot_messages(conversation_id, created_at);
CREATE INDEX idx_cost_backend_created ON chatbot_costs(backend, created_at);

-- ============================================================================
-- Completion Message
-- ============================================================================

SELECT 'Chatbot Database Schema Initialized Successfully' AS Status;
SELECT COUNT(*) AS DefaultMisconceptions FROM chatbot_misconceptions;
