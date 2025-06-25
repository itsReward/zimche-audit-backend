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
