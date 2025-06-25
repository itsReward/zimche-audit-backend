#!/bin/bash

# Master script to generate all project files for ZIMCHE Audit Backend

echo "🚀 Starting ZIMCHE Audit Backend Generation..."
echo "=================================================="

# Check if we're in the right directory
if [ ! -f "build.gradle.kts" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    echo "Make sure you've run setup-project.sh first"
    exit 1
fi

# Function to run script and check result
run_script() {
    local script_name="$1"
    local description="$2"

    echo "🔧 $description..."
    if [ -f "scripts/$script_name" ]; then
        chmod +x "scripts/$script_name"
        ./scripts/$script_name
        if [ $? -eq 0 ]; then
            echo "✅ $description completed successfully"
        else
            echo "❌ Error in $description"
            exit 1
        fi
    else
        echo "⚠️  Warning: scripts/$script_name not found, skipping..."
    fi
    echo ""
}

# Generate all components in the correct order
run_script "generate-entities.sh" "Generating Entity Classes"
run_script "generate-repositories.sh" "Generating Repository Interfaces"

# Fix DTO compilation errors
echo "🔧 Fixing DTO compilation errors..."
if [ -f "scripts/fix-dto-errors.sh" ]; then
    chmod +x scripts/fix-dto-errors.sh
    ./scripts/fix-dto-errors.sh
fi

run_script "generate-services.sh" "Generating Service Classes"
run_script "generate-security.sh" "Generating Security Classes"
run_script "generate-config.sh" "Generating Configuration Classes"
run_script "generate-controllers.sh" "Generating Controller Classes"
run_script "generate-remaining-controllers.sh" "Generating Remaining Controllers"
run_script "generate-utils.sh" "Generating Utility Classes"

# Add missing dependencies to build.gradle.kts
echo "🔧 Adding missing dependencies..."
cat >> build.gradle.kts << 'EOF'

    // Swagger/OpenAPI
    implementation("org.springdoc:springdoc-openapi-starter-webmvc-ui:2.2.0")

    // Additional utilities
    implementation("org.apache.commons:commons-lang3:3.13.0")
    implementation("commons-io:commons-io:2.11.0")
EOF

echo "=================================================="
echo "🎉 ZIMCHE Audit Backend Generation Complete!"
echo ""
echo "📁 Project Structure:"
echo "  ├── Entities: User, University, Document, Audit, Message, AIAnalysis"
echo "  ├── Repositories: Full CRUD + custom queries for all entities"
echo "  ├── Services: Business logic for auth, users, documents, AI, etc."
echo "  ├── Controllers: REST API endpoints (Auth, User, Document, University, AI, Messaging)"
echo "  ├── DTOs: Request/Response objects with validation"
echo "  ├── Security: JWT authentication & authorization"
echo "  ├── Configuration: Database, Security, AI, Email, CORS, Swagger"
echo "  └── Utils: File handling, validation, date utilities, security utils"
echo ""
echo "🛠️  Next Steps:"
echo "1. Set up your MySQL database:"
echo "   cd docker && docker-compose up -d mysql"
echo ""
echo "2. Configure environment variables in .env file:"
echo "   JWT_SECRET='your-secret-key'"
echo "   OPENAI_API_KEY='your-openai-key'"
echo "   AWS_ACCESS_KEY='your-aws-key'"
echo "   AWS_SECRET_KEY='your-aws-secret'"
echo "   DB_USERNAME='zimche_user'"
echo "   DB_PASSWORD='zimche_password'"
echo ""
echo "3. Build and run the application:"
echo "   ./gradlew build"
echo "   ./gradlew bootRun"
echo ""
echo "4. Access the API at: http://localhost:8080"
echo "   - Swagger UI: http://localhost:8080/swagger-ui.html"
echo "   - Health Check: http://localhost:8080/actuator/health"
echo ""
echo "📚 Main API Endpoints:"
echo "   Authentication:"
echo "   - POST /api/auth/login"
echo "   - POST /api/auth/register"
echo "   - GET /api/auth/me"
echo ""
echo "   Document Management:"
echo "   - POST /api/documents/upload"
echo "   - GET /api/documents"
echo "   - PUT /api/documents/{id}/status"
echo "   - GET /api/documents/{id}/download"
echo ""
echo "   AI Analysis:"
echo "   - POST /api/ai/analyze/{documentId}"
echo "   - GET /api/ai/analyses/{documentId}"
echo ""
echo "   User Management:"
echo "   - GET /api/users"
echo "   - PUT /api/users/{id}"
echo "   - GET /api/users/search"
echo ""
echo "   University Management:"
echo "   - GET /api/universities"
echo "   - POST /api/universities"
echo "   - PUT /api/universities/{id}"
echo ""
echo "   Messaging:"
echo "   - POST /api/messages"
echo "   - GET /api/messages"
echo "   - PUT /api/messages/{id}/read"
echo ""
echo "🔧 Key Features Implemented:"
echo "  ✅ JWT Authentication & Role-based Authorization"
echo "  ✅ File Upload to AWS S3 with validation"
echo "  ✅ OpenAI GPT Integration for document analysis"
echo "  ✅ Email notifications (SMTP)"
echo "  ✅ Internal messaging system"
echo "  ✅ Comprehensive audit management"
echo "  ✅ University and user management"
echo "  ✅ Real-time API with pagination & filtering"
echo "  ✅ Swagger API documentation"
echo "  ✅ Exception handling and validation"
echo "  ✅ Performance monitoring utilities"
echo "  ✅ Docker support"
echo ""
echo "🎯 Ready to start building your React frontend!"
echo "=================================================="