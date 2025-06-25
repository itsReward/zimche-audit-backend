#!/bin/bash

# Migrate ZIMCHE Audit Backend from MySQL to PostgreSQL

echo "🐘 Migrating from MySQL to PostgreSQL..."

# Update build.gradle.kts - Replace MySQL with PostgreSQL
echo "📝 Updating build.gradle.kts..."
sed -i.bak 's/runtimeOnly("mysql:mysql-connector-java:8.0.33")/runtimeOnly("org.postgresql:postgresql")/' build.gradle.kts
echo "✅ Updated database dependency"

# Update application.yml files
echo "📝 Updating application configuration files..."

# Update main application.yml
cat > src/main/resources/application.yml << 'EOF'
spring:
  profiles:
    active: dev

  servlet:
    multipart:
      max-file-size: 50MB
      max-request-size: 50MB

server:
  port: 8080

app:
  jwt:
    secret: ${JWT_SECRET:zimche-audit-jwt-secret-key-change-in-production}
    expiration: 86400000 # 24 hours

  openai:
    api-key: ${OPENAI_API_KEY:your-openai-api-key}
    model: gpt-3.5-turbo
    max-tokens: 1000

  aws:
    access-key: ${AWS_ACCESS_KEY:your-aws-access-key}
    secret-key: ${AWS_SECRET_KEY:your-aws-secret-key}
    region: ${AWS_REGION:us-east-1}
    s3-bucket: ${S3_BUCKET:zimche-audit-documents}

logging:
  level:
    com.zimche.audit: DEBUG
    org.springframework.security: DEBUG
EOF

# Update application-dev.yml for PostgreSQL
cat > src/main/resources/application-dev.yml << 'EOF'
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/zimche_audit_dev
    username: ${DB_USERNAME:zimche_user}
    password: ${DB_PASSWORD:zimche_password}
    driver-class-name: org.postgresql.Driver

  jpa:
    hibernate:
      ddl-auto: create-drop
    show-sql: true
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
        format_sql: true
        # PostgreSQL specific optimizations
        jdbc:
          lob:
            non_contextual_creation: true
        temp:
          use_jdbc_metadata_defaults: false

  mail:
    host: smtp.gmail.com
    port: 587
    username: ${EMAIL_USERNAME:your-email@gmail.com}
    password: ${EMAIL_PASSWORD:your-app-password}
    properties:
      mail:
        smtp:
          auth: true
          starttls:
            enable: true

logging:
  level:
    org.hibernate.SQL: DEBUG
    org.hibernate.type.descriptor.sql.BasicBinder: TRACE
    org.postgresql: DEBUG
EOF

# Update application-prod.yml for PostgreSQL
cat > src/main/resources/application-prod.yml << 'EOF'
spring:
  datasource:
    url: ${DATABASE_URL}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
    driver-class-name: org.postgresql.Driver
    # PostgreSQL connection pool settings
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      idle-timeout: 300000
      connection-timeout: 30000
      leak-detection-threshold: 60000

  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
        jdbc:
          lob:
            non_contextual_creation: true
        temp:
          use_jdbc_metadata_defaults: false

  mail:
    host: ${EMAIL_HOST}
    port: ${EMAIL_PORT}
    username: ${EMAIL_USERNAME}
    password: ${EMAIL_PASSWORD}
    properties:
      mail:
        smtp:
          auth: true
          starttls:
            enable: true

logging:
  level:
    com.zimche.audit: INFO
    org.springframework.security: WARN
EOF

# Update Docker Compose file
echo "🐳 Updating Docker Compose configuration..."
cat > docker/docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: zimche-postgres
    environment:
      POSTGRES_DB: zimche_audit_dev
      POSTGRES_USER: zimche_user
      POSTGRES_PASSWORD: zimche_password
      POSTGRES_INITDB_ARGS: "--encoding=UTF8 --locale=C"
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d
    command:
      - "postgres"
      - "-c"
      - "max_connections=200"
      - "-c"
      - "shared_buffers=256MB"
      - "-c"
      - "effective_cache_size=1GB"
      - "-c"
      - "work_mem=4MB"
      - "-c"
      - "maintenance_work_mem=64MB"
      - "-c"
      - "checkpoint_completion_target=0.7"
      - "-c"
      - "wal_buffers=16MB"
      - "-c"
      - "default_statistics_target=100"

  app:
    build:
      context: ..
      dockerfile: docker/Dockerfile
    container_name: zimche-audit-app
    depends_on:
      - postgres
    ports:
      - "8080:8080"
    environment:
      SPRING_PROFILES_ACTIVE: dev
      DB_USERNAME: zimche_user
      DB_PASSWORD: zimche_password
      JWT_SECRET: your-jwt-secret-key
      OPENAI_API_KEY: your-openai-api-key

volumes:
  postgres_data:
EOF

# Create PostgreSQL initialization scripts directory
mkdir -p docker/init-scripts

# Create database initialization script
cat > docker/init-scripts/01-init-db.sql << 'EOF'
-- Create extensions that might be useful for the audit system
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create indexes for better performance (will be created after tables are generated)
-- These will be applied after Hibernate creates the tables

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';
EOF

# Create performance optimization script
cat > docker/init-scripts/02-performance.sql << 'EOF'
-- Additional performance configurations
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM SET log_duration = on;
ALTER SYSTEM SET log_min_duration_statement = 1000; -- Log queries taking more than 1 second

-- Create a function for full-text search (useful for document content searching)
CREATE OR REPLACE FUNCTION create_search_indexes()
RETURNS void AS $$
BEGIN
    -- This will be called after tables are created
    -- Add indexes for commonly searched fields
    PERFORM 1;
END;
$$ LANGUAGE plpgsql;
EOF

# Update Entity annotations for PostgreSQL optimizations
echo "📝 Updating Entity classes for PostgreSQL..."

# Update User entity with PostgreSQL optimizations
cat > src/main/kotlin/com/zimche/audit/entity/User.kt << 'EOF'
package com.zimche.audit.entity

import com.zimche.audit.enums.UserRole
import jakarta.persistence.*
import org.hibernate.annotations.GenericGenerator
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.jpa.domain.support.AuditingEntityListener
import java.time.LocalDateTime

@Entity
@Table(
    name = "users",
    indexes = [
        Index(name = "idx_user_email", columnList = "email", unique = true),
        Index(name = "idx_user_role", columnList = "role"),
        Index(name = "idx_user_university", columnList = "university_id"),
        Index(name = "idx_user_active", columnList = "is_active"),
        Index(name = "idx_user_created", columnList = "created_at")
    ]
)
@EntityListeners(AuditingEntityListener::class)
data class User(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @Column(unique = true, nullable = false, length = 255)
    val email: String,

    @Column(nullable = false)
    val password: String,

    @Column(name = "first_name", nullable = false, length = 100)
    val firstName: String,

    @Column(name = "last_name", nullable = false, length = 100)
    val lastName: String,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 50)
    val role: UserRole,

    @Column(name = "phone_number", length = 20)
    val phoneNumber: String? = null,

    @Column(name = "is_active")
    val isActive: Boolean = true,

    @Column(name = "is_email_verified")
    val isEmailVerified: Boolean = false,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "university_id")
    val university: University? = null,

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @LastModifiedDate
    @Column(name = "updated_at")
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    val fullName: String
        get() = "$firstName $lastName"

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as User
        return id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String = "User(id=$id, email='$email', fullName='$fullName')"
}
EOF

# Create a PostgreSQL-specific configuration class
cat > src/main/kotlin/com/zimche/audit/config/PostgreSQLConfig.kt << 'EOF'
package com.zimche.audit.config

import org.springframework.context.annotation.Configuration
import org.springframework.context.annotation.Profile
import jakarta.annotation.PostConstruct
import org.springframework.beans.factory.annotation.Autowired
import javax.sql.DataSource
import java.sql.Connection

@Configuration
@Profile("!test")
class PostgreSQLConfig {

    @Autowired
    private lateinit var dataSource: DataSource

    @PostConstruct
    fun configurePostgreSQL() {
        try {
            dataSource.connection.use { connection ->
                // Set PostgreSQL specific settings
                executeStatement(connection, "SET timezone = 'UTC'")
                executeStatement(connection, "SET statement_timeout = '30s'")
                executeStatement(connection, "SET lock_timeout = '10s'")
            }
        } catch (e: Exception) {
            println("Warning: Could not configure PostgreSQL settings: ${e.message}")
        }
    }

    private fun executeStatement(connection: Connection, sql: String) {
        try {
            connection.createStatement().use { statement ->
                statement.execute(sql)
            }
        } catch (e: Exception) {
            println("Warning: Could not execute SQL: $sql - ${e.message}")
        }
    }
}
EOF

# Update test configuration for PostgreSQL
cat > src/test/resources/application-test.yml << 'EOF'
spring:
  datasource:
    url: jdbc:h2:mem:testdb;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH
    driver-class-name: org.h2.Driver
    username: sa
    password:

  jpa:
    hibernate:
      ddl-auto: create-drop
    properties:
      hibernate:
        dialect: org.hibernate.dialect.H2Dialect
    show-sql: false

  mail:
    host: localhost
    port: 25

logging:
  level:
    com.zimche.audit: WARN
    org.springframework: WARN
    org.hibernate: WARN
EOF

# Create a script to setup local PostgreSQL
cat > scripts/setup-postgres.sh << 'EOF'
#!/bin/bash

echo "🐘 Setting up PostgreSQL for ZIMCHE Audit System..."

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "❌ PostgreSQL is not installed. Please install PostgreSQL first."
    echo ""
    echo "On macOS: brew install postgresql"
    echo "On Ubuntu: sudo apt-get install postgresql postgresql-contrib"
    echo "On CentOS/RHEL: sudo yum install postgresql postgresql-server"
    exit 1
fi

# Check if PostgreSQL is running
if ! pg_isready -q; then
    echo "❌ PostgreSQL is not running. Please start PostgreSQL service."
    echo ""
    echo "On macOS: brew services start postgresql"
    echo "On Ubuntu: sudo systemctl start postgresql"
    echo "On CentOS/RHEL: sudo systemctl start postgresql"
    exit 1
fi

echo "✅ PostgreSQL is installed and running"

# Create database and user
echo "📝 Creating database and user..."

sudo -u postgres psql << EOF
-- Create user
CREATE USER zimche_user WITH PASSWORD 'zimche_password';

-- Create database
CREATE DATABASE zimche_audit_dev WITH OWNER zimche_user;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE zimche_audit_dev TO zimche_user;

-- Connect to the database and grant schema privileges
\c zimche_audit_dev;
GRANT ALL ON SCHEMA public TO zimche_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO zimche_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO zimche_user;

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Exit
\q
EOF

if [ $? -eq 0 ]; then
    echo "✅ Database and user created successfully"
    echo ""
    echo "📊 Database Details:"
    echo "  Host: localhost"
    echo "  Port: 5432"
    echo "  Database: zimche_audit_dev"
    echo "  Username: zimche_user"
    echo "  Password: zimche_password"
    echo ""
    echo "🔗 Connection URL: jdbc:postgresql://localhost:5432/zimche_audit_dev"
else
    echo "❌ Failed to create database and user"
    exit 1
fi
EOF

chmod +x scripts/setup-postgres.sh

# Create environment setup script
cat > scripts/setup-env-postgres.sh << 'EOF'
#!/bin/bash

echo "🔧 Setting up environment variables for PostgreSQL..."

# Create .env file
cat > .env << 'ENV_EOF'
# Database Configuration
DB_USERNAME=zimche_user
DB_PASSWORD=zimche_password
DATABASE_URL=jdbc:postgresql://localhost:5432/zimche_audit_dev

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-at-least-256-bits-long-for-production

# OpenAI Configuration
OPENAI_API_KEY=sk-your-openai-api-key-here

# AWS S3 Configuration
AWS_ACCESS_KEY=your-aws-access-key-here
AWS_SECRET_KEY=your-aws-secret-key-here
AWS_REGION=us-east-1
S3_BUCKET=zimche-audit-documents

# Email Configuration
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USERNAME=your-email@gmail.com
EMAIL_PASSWORD=your-app-password

# Application Configuration
SPRING_PROFILES_ACTIVE=dev
ENV_EOF

echo "✅ Environment file created: .env"
echo ""
echo "📝 Please update the following values in .env:"
echo "  - OPENAI_API_KEY: Your OpenAI API key"
echo "  - AWS_ACCESS_KEY & AWS_SECRET_KEY: Your AWS credentials"
echo "  - EMAIL_USERNAME & EMAIL_PASSWORD: Your SMTP credentials"
echo "  - JWT_SECRET: A secure secret key for production"
EOF

chmod +x scripts/setup-env-postgres.sh

echo "✅ PostgreSQL migration completed!"
echo ""
echo "📋 Summary of changes:"
echo "  ✅ Updated build.gradle.kts (PostgreSQL driver)"
echo "  ✅ Updated application configuration files"
echo "  ✅ Updated Docker Compose (PostgreSQL 15)"
echo "  ✅ Created PostgreSQL initialization scripts"
echo "  ✅ Updated Entity classes with PostgreSQL optimizations"
echo "  ✅ Created PostgreSQL-specific configuration"
echo "  ✅ Updated test configuration"
echo "  ✅ Created setup scripts"
echo ""
echo "🚀 Next steps:"
echo "1. Install PostgreSQL (if not already installed)"
echo "2. Run: ./scripts/setup-postgres.sh"
echo "3. Run: ./scripts/setup-env-postgres.sh"
echo "4. Start with Docker: cd docker && docker-compose up -d"
echo "5. Or start locally: ./gradlew bootRun"
echo ""
echo "🔍 Key advantages of PostgreSQL:"
echo "  ✅ Better performance for complex queries"
echo "  ✅ Advanced indexing (GIN, GiST, BRIN)"
echo "  ✅ Full-text search capabilities"
echo "  ✅ JSON/JSONB support for flexible data"
echo "  ✅ Better concurrent write performance"
echo "  ✅ Advanced data types (arrays, hstore, etc.)"
echo "  ✅ Better compliance with SQL standards"