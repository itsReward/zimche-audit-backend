#!/bin/bash

# ============================================================================
# Fix YAML Duplicate Keys Error
# File: fix-yaml-duplicates.sh
# ============================================================================

echo "🔧 Fixing YAML duplicate keys in application.yml..."

# Backup the current application.yml
cp src/main/resources/application.yml src/main/resources/application.yml.backup
echo "✅ Backed up application.yml"

# Create a clean application.yml file
echo "📝 Creating clean application.yml..."
cat > src/main/resources/application.yml << 'EOF'
spring:
  profiles:
    active: dev

  servlet:
    multipart:
      max-file-size: 50MB
      max-request-size: 50MB

  # Thymeleaf Configuration
  thymeleaf:
    cache: false
    enabled: true
    prefix: classpath:/templates/
    suffix: .html
    mode: HTML
    encoding: UTF-8
    servlet:
      content-type: text/html

  # Security Configuration
  security:
    user:
      name: dev
      password: dev123
      roles: ADMIN

server:
  port: 8080
  error:
    include-message: always
    include-binding-errors: always
    include-stacktrace: on_param

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
    com.zimche.audit: INFO
    org.springframework.security: INFO
    org.springframework.web: INFO
EOF

# Check if application-dev.yml exists and clean it up too
if [ -f "src/main/resources/application-dev.yml" ]; then
    echo "📝 Cleaning up application-dev.yml..."
    cp src/main/resources/application-dev.yml src/main/resources/application-dev.yml.backup

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

  mail:
    host: ${EMAIL_HOST:smtp.gmail.com}
    port: ${EMAIL_PORT:587}
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
    com.zimche.audit: DEBUG
    org.springframework.security: DEBUG
EOF
fi

# Check if application-prod.yml exists and clean it up too
if [ -f "src/main/resources/application-prod.yml" ]; then
    echo "📝 Cleaning up application-prod.yml..."
    cp src/main/resources/application-prod.yml src/main/resources/application-prod.yml.backup

    cat > src/main/resources/application-prod.yml << 'EOF'
spring:
  datasource:
    url: ${DATABASE_URL}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
    driver-class-name: org.postgresql.Driver

  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect

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
fi

# Also check if there are any test configuration files that might have issues
if [ -f "src/test/resources/application.yml" ]; then
    echo "🧪 Creating clean test application.yml..."
    mkdir -p src/test/resources
    cat > src/test/resources/application.yml << 'EOF'
spring:
  profiles:
    active: test

  datasource:
    url: jdbc:h2:mem:testdb
    driver-class-name: org.h2.Driver
    username: sa
    password: password

  jpa:
    hibernate:
      ddl-auto: create-drop
    show-sql: false
    database-platform: org.hibernate.dialect.H2Dialect

  security:
    user:
      name: test
      password: test123
      roles: ADMIN

logging:
  level:
    com.zimche.audit: WARN
    org.springframework.security: WARN
    org.springframework.web: WARN
    org.hibernate: WARN
EOF
fi

# Validate the YAML files
echo "🔍 Validating YAML syntax..."

# Function to validate YAML using Python (if available)
validate_yaml() {
    local file="$1"
    if command -v python3 &> /dev/null; then
        python3 -c "
import yaml
import sys
try:
    with open('$file', 'r') as f:
        yaml.safe_load(f)
    print('✅ $file is valid')
except yaml.YAMLError as e:
    print('❌ $file has YAML errors:')
    print(e)
    sys.exit(1)
except Exception as e:
    print('⚠️  Could not validate $file: $e')
"
    else
        echo "⚠️  Python not available for YAML validation"
    fi
}

# Validate main config files
validate_yaml "src/main/resources/application.yml"

if [ -f "src/main/resources/application-dev.yml" ]; then
    validate_yaml "src/main/resources/application-dev.yml"
fi

if [ -f "src/main/resources/application-prod.yml" ]; then
    validate_yaml "src/main/resources/application-prod.yml"
fi

if [ -f "src/test/resources/application.yml" ]; then
    validate_yaml "src/test/resources/application.yml"
fi

echo ""
echo "✅ YAML files have been cleaned up!"
echo ""
echo "🔧 What was fixed:"
echo "  1. Removed duplicate keys from application.yml"
echo "  2. Consolidated all Spring configuration properly"
echo "  3. Created clean test configuration"
echo "  4. Validated YAML syntax"
echo ""
echo "📁 Configuration files:"
echo "  • application.yml (main config)"
echo "  • application-dev.yml (development)"
echo "  • application-prod.yml (production)"
echo "  • test/application.yml (testing)"
echo ""
echo "💾 Backup files created:"
echo "  • application.yml.backup"
echo "  • application-dev.yml.backup"
echo "  • application-prod.yml.backup"
echo ""
echo "🚀 Now try building again:"
echo "  ./gradlew build"