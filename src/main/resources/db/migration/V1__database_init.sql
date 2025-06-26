-- =====================================================
-- ZIMCHE Audit System Database Migration Script
-- =====================================================
-- This script creates the complete database schema for the ZIMCHE Audit System
-- Run this script against your PostgreSQL database

-- Create extensions for additional functionality
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- =====================================================
-- 1. CREATE UNIVERSITIES TABLE
-- =====================================================
CREATE TABLE universities (
                              id BIGSERIAL PRIMARY KEY,
                              name VARCHAR(255) NOT NULL,
                              code VARCHAR(50) UNIQUE NOT NULL,
                              address TEXT NOT NULL,
                              contact_email VARCHAR(255) NOT NULL,
                              contact_phone VARCHAR(20),
                              website VARCHAR(255),
                              established_year INTEGER,
                              is_active BOOLEAN DEFAULT true,
                              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                              updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for universities
CREATE INDEX idx_universities_code ON universities(code);
CREATE INDEX idx_universities_active ON universities(is_active);
CREATE INDEX idx_universities_name ON universities USING gin(to_tsvector('english', name));

-- =====================================================
-- 2. CREATE USERS TABLE
-- =====================================================
CREATE TABLE users (
                       id BIGSERIAL PRIMARY KEY,
                       email VARCHAR(255) UNIQUE NOT NULL,
                       password VARCHAR(255) NOT NULL,
                       first_name VARCHAR(100) NOT NULL,
                       last_name VARCHAR(100) NOT NULL,
                       role VARCHAR(50) NOT NULL CHECK (role IN ('ADMIN', 'UNIVERSITY_STAFF', 'PEER_REVIEWER', 'SUPER_USER')),
                       phone_number VARCHAR(20),
                       is_active BOOLEAN DEFAULT true,
                       is_email_verified BOOLEAN DEFAULT false,
                       university_id BIGINT,
                       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                       updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

                       CONSTRAINT fk_users_university FOREIGN KEY (university_id) REFERENCES universities(id) ON DELETE SET NULL
);

-- Create indexes for users
CREATE UNIQUE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_university ON users(university_id);
CREATE INDEX idx_users_active ON users(is_active);
CREATE INDEX idx_users_name ON users(first_name, last_name);

-- =====================================================
-- 3. CREATE DOCUMENTS TABLE
-- =====================================================
CREATE TABLE documents (
                           id BIGSERIAL PRIMARY KEY,
                           title VARCHAR(255) NOT NULL,
                           file_name VARCHAR(255) NOT NULL,
                           file_url VARCHAR(500) NOT NULL,
                           file_size BIGINT NOT NULL,
                           content_type VARCHAR(100),
                           description TEXT,
                           status VARCHAR(50) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'REQUIRES_REVISION')),
                           university_id BIGINT NOT NULL,
                           uploaded_by BIGINT NOT NULL,
                           reviewed_by BIGINT,
                           reviewed_at TIMESTAMP,
                           review_comments TEXT,
                           created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                           updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

                           CONSTRAINT fk_documents_university FOREIGN KEY (university_id) REFERENCES universities(id) ON DELETE CASCADE,
                           CONSTRAINT fk_documents_uploaded_by FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE CASCADE,
                           CONSTRAINT fk_documents_reviewed_by FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL
);

-- Create indexes for documents
CREATE INDEX idx_documents_university ON documents(university_id);
CREATE INDEX idx_documents_uploaded_by ON documents(uploaded_by);
CREATE INDEX idx_documents_status ON documents(status);
CREATE INDEX idx_documents_title ON documents USING gin(to_tsvector('english', title));
CREATE INDEX idx_documents_created ON documents(created_at);

-- =====================================================
-- 4. CREATE AUDITS TABLE
-- =====================================================
CREATE TABLE audits (
                        id BIGSERIAL PRIMARY KEY,
                        title VARCHAR(255) NOT NULL,
                        description TEXT,
                        status VARCHAR(50) NOT NULL DEFAULT 'SCHEDULED' CHECK (status IN ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'ON_HOLD')),
                        scheduled_date TIMESTAMP NOT NULL,
                        start_date TIMESTAMP,
                        end_date TIMESTAMP,
                        university_id BIGINT NOT NULL,
                        assigned_to BIGINT,
                        created_by BIGINT NOT NULL,
                        final_report TEXT,
                        compliance_score DECIMAL(5,2) CHECK (compliance_score >= 0 AND compliance_score <= 100),
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

                        CONSTRAINT fk_audits_university FOREIGN KEY (university_id) REFERENCES universities(id) ON DELETE CASCADE,
                        CONSTRAINT fk_audits_assigned_to FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL,
                        CONSTRAINT fk_audits_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for audits
CREATE INDEX idx_audits_university ON audits(university_id);
CREATE INDEX idx_audits_status ON audits(status);
CREATE INDEX idx_audits_assigned_to ON audits(assigned_to);
CREATE INDEX idx_audits_scheduled_date ON audits(scheduled_date);
CREATE INDEX idx_audits_created_by ON audits(created_by);

-- =====================================================
-- 5. CREATE AUDIT_STEPS TABLE
-- =====================================================
CREATE TABLE audit_steps (
                             id BIGSERIAL PRIMARY KEY,
                             title VARCHAR(255) NOT NULL,
                             description TEXT,
                             step_order INTEGER NOT NULL,
                             is_completed BOOLEAN DEFAULT false,
                             completed_at TIMESTAMP,
                             comments TEXT,
                             audit_id BIGINT NOT NULL,
                             assigned_to BIGINT,
                             completed_by BIGINT,
                             created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                             updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

                             CONSTRAINT fk_audit_steps_audit FOREIGN KEY (audit_id) REFERENCES audits(id) ON DELETE CASCADE,
                             CONSTRAINT fk_audit_steps_assigned_to FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL,
                             CONSTRAINT fk_audit_steps_completed_by FOREIGN KEY (completed_by) REFERENCES users(id) ON DELETE SET NULL
);

-- Create indexes for audit_steps
CREATE INDEX idx_audit_steps_audit ON audit_steps(audit_id);
CREATE INDEX idx_audit_steps_order ON audit_steps(audit_id, step_order);
CREATE INDEX idx_audit_steps_assigned ON audit_steps(assigned_to);
CREATE INDEX idx_audit_steps_completed ON audit_steps(is_completed);

-- =====================================================
-- 6. CREATE MESSAGES TABLE
-- =====================================================
CREATE TABLE messages (
                          id BIGSERIAL PRIMARY KEY,
                          subject VARCHAR(255) NOT NULL,
                          content TEXT NOT NULL,
                          type VARCHAR(50) NOT NULL CHECK (type IN ('NOTIFICATION', 'ALERT', 'REMINDER', 'CHAT', 'SYSTEM')),
                          is_read BOOLEAN DEFAULT false,
                          read_at TIMESTAMP,
                          sender_id BIGINT NOT NULL,
                          recipient_id BIGINT NOT NULL,
                          related_document_id BIGINT,
                          related_audit_id BIGINT,
                          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

                          CONSTRAINT fk_messages_sender FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
                          CONSTRAINT fk_messages_recipient FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE CASCADE,
                          CONSTRAINT fk_messages_document FOREIGN KEY (related_document_id) REFERENCES documents(id) ON DELETE SET NULL,
                          CONSTRAINT fk_messages_audit FOREIGN KEY (related_audit_id) REFERENCES audits(id) ON DELETE SET NULL
);

-- Create indexes for messages
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_recipient ON messages(recipient_id);
CREATE INDEX idx_messages_type ON messages(type);
CREATE INDEX idx_messages_read ON messages(is_read);
CREATE INDEX idx_messages_created ON messages(created_at);

-- =====================================================
-- 7. CREATE AI_ANALYSES TABLE
-- =====================================================
CREATE TABLE ai_analyses (
                             id BIGSERIAL PRIMARY KEY,
                             analysis_type VARCHAR(100) NOT NULL,
                             prompt TEXT NOT NULL,
                             result TEXT NOT NULL,
                             confidence_score DECIMAL(5,4) CHECK (confidence_score >= 0 AND confidence_score <= 1),
                             tokens_used INTEGER,
                             processing_time_ms BIGINT,
                             model_version VARCHAR(50),
                             document_id BIGINT NOT NULL,
                             requested_by BIGINT NOT NULL,
                             created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

                             CONSTRAINT fk_ai_analyses_document FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE,
                             CONSTRAINT fk_ai_analyses_requested_by FOREIGN KEY (requested_by) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for ai_analyses
CREATE INDEX idx_ai_analyses_document ON ai_analyses(document_id);
CREATE INDEX idx_ai_analyses_type ON ai_analyses(analysis_type);
CREATE INDEX idx_ai_analyses_requested_by ON ai_analyses(requested_by);
CREATE INDEX idx_ai_analyses_created ON ai_analyses(created_at);

-- =====================================================
-- 8. CREATE TRIGGERS FOR UPDATED_AT TIMESTAMPS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for all tables with updated_at columns
CREATE TRIGGER trigger_universities_updated_at
    BEFORE UPDATE ON universities
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_documents_updated_at
    BEFORE UPDATE ON documents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_audits_updated_at
    BEFORE UPDATE ON audits
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_audit_steps_updated_at
    BEFORE UPDATE ON audit_steps
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 9. INSERT SAMPLE DATA (OPTIONAL)
-- =====================================================

-- Insert sample universities
INSERT INTO universities (name, code, address, contact_email, contact_phone, website, established_year, is_active) VALUES
                                                                                                                       ('University of Zimbabwe', 'UZ', '167 Mt Pleasant Road, Harare, Zimbabwe', 'registrar@uz.ac.zw', '+263-4-303211', 'https://www.uz.ac.zw', 1952, true),
                                                                                                                       ('National University of Science and Technology', 'NUST', 'Bulawayo, Zimbabwe', 'registrar@nust.ac.zw', '+263-9-282842', 'https://www.nust.ac.zw', 1990, true),
                                                                                                                       ('Midlands State University', 'MSU', 'Gweru, Zimbabwe', 'registrar@msu.ac.zw', '+263-54-260404', 'https://www.msu.ac.zw', 1999, true),
                                                                                                                       ('Africa University', 'AU', 'Mutare, Zimbabwe', 'registrar@africau.edu', '+263-20-60201', 'https://www.africau.edu', 1992, true),
                                                                                                                       ('Chinhoyi University of Technology', 'CUT', 'Chinhoyi, Zimbabwe', 'registrar@cut.ac.zw', '+263-67-22681', 'https://www.cut.ac.zw', 2001, true);

-- Insert default admin user (password: admin123 - change this in production!)
INSERT INTO users (email, password, first_name, last_name, role, is_active, is_email_verified) VALUES
    ('admin@zimche.gov.zw', '$2a$10$N7ZE4DfePKzI7c7WZIvVne7YCBWo6V4L6VzOeU5N.Y1ZDV3PeINiq', 'System', 'Administrator', 'SUPER_USER', true, true);

-- =====================================================
-- 10. CREATE VIEWS FOR REPORTING
-- =====================================================

-- View for audit progress
CREATE VIEW v_audit_progress AS
SELECT
    a.id as audit_id,
    a.title as audit_title,
    a.status as audit_status,
    u.name as university_name,
    COUNT(ast.id) as total_steps,
    COUNT(CASE WHEN ast.is_completed = true THEN 1 END) as completed_steps,
    ROUND((COUNT(CASE WHEN ast.is_completed = true THEN 1 END) * 100.0 / COUNT(ast.id)), 2) as completion_percentage,
    a.scheduled_date,
    a.start_date,
    a.end_date
FROM audits a
         LEFT JOIN audit_steps ast ON a.id = ast.audit_id
         LEFT JOIN universities u ON a.university_id = u.id
GROUP BY a.id, a.title, a.status, u.name, a.scheduled_date, a.start_date, a.end_date;

-- View for university statistics
CREATE VIEW v_university_stats AS
SELECT
    u.id as university_id,
    u.name as university_name,
    u.code as university_code,
    COUNT(DISTINCT usr.id) as total_users,
    COUNT(DISTINCT d.id) as total_documents,
    COUNT(DISTINCT a.id) as total_audits,
    COUNT(CASE WHEN a.status = 'COMPLETED' THEN 1 END) as completed_audits,
    COUNT(CASE WHEN a.status = 'IN_PROGRESS' THEN 1 END) as active_audits,
    AVG(a.compliance_score) as avg_compliance_score
FROM universities u
         LEFT JOIN users usr ON u.id = usr.university_id
         LEFT JOIN documents d ON u.id = d.university_id
         LEFT JOIN audits a ON u.id = a.university_id
WHERE u.is_active = true
GROUP BY u.id, u.name, u.code;

-- =====================================================
-- 11. CREATE PERFORMANCE OPTIMIZATION FUNCTIONS
-- =====================================================

-- Function to analyze table statistics
CREATE OR REPLACE FUNCTION analyze_zimche_tables()
RETURNS void AS $$
BEGIN
    ANALYZE universities;
    ANALYZE users;
    ANALYZE documents;
    ANALYZE audits;
    ANALYZE audit_steps;
    ANALYZE messages;
    ANALYZE ai_analyses;

    RAISE NOTICE 'All ZIMCHE tables analyzed successfully';
END;
$$ LANGUAGE plpgsql;

-- Function to check database health
CREATE OR REPLACE FUNCTION check_zimche_db_health()
RETURNS TABLE(
    table_name text,
    row_count bigint,
    table_size text,
    index_size text
) AS $$
BEGIN
RETURN QUERY
SELECT
    schemaname||'.'||tablename as table_name,
    n_tup_ins - n_tup_del as row_count,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as table_size,
    pg_size_pretty(pg_indexes_size(schemaname||'.'||tablename)) as index_size
FROM pg_stat_user_tables
WHERE schemaname = 'public'
  AND tablename IN ('universities', 'users', 'documents', 'audits', 'audit_steps', 'messages', 'ai_analyses')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 12. GRANT PERMISSIONS (Adjust based on your user setup)
-- =====================================================

-- If you have a specific application user, grant permissions:
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO zimche_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO zimche_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO zimche_user;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================

-- Run the analyze function to update table statistics
SELECT analyze_zimche_tables();

-- Display database health report
SELECT * FROM check_zimche_db_health();

-- Final message
DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'ZIMCHE Audit Database Migration Completed!';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Tables created: 7';
    RAISE NOTICE 'Indexes created: 25+';
    RAISE NOTICE 'Views created: 2';
    RAISE NOTICE 'Functions created: 3';
    RAISE NOTICE 'Triggers created: 5';
    RAISE NOTICE 'Sample data: 5 universities, 1 admin user';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Default admin credentials:';
    RAISE NOTICE 'Email: admin@zimche.gov.zw';
    RAISE NOTICE 'Password: admin123';
    RAISE NOTICE 'IMPORTANT: Change the admin password in production!';
    RAISE NOTICE '==============================================';
END $$;