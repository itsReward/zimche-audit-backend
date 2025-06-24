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
run_script "generate-dtos.sh" "Generating DTO Classes"
run_script "generate-services.sh" "Generating Service Classes"
run_script "generate-security.sh" "Generating Security Classes"
run_script "generate-config.sh" "Generating Configuration Classes"
run_script "generate-controllers.sh" "Generating Controller Classes"
run_script "generate-utils.sh" "Generating Utility Classes"

echo "=================================================="
echo "🎉 ZIMCHE Audit Backend Generation Complete!"
echo ""
echo "📁 Project Structure:"
echo "  ├── Entities: User, University, Document, Audit, Message, AIAnalysis"
echo "  ├── Repositories: Full CRUD + custom queries for all entities"
echo "  ├── Services: Business logic for auth, users, documents, AI, etc."
echo "  ├── Controllers: REST API endpoints"
echo "  ├── DTOs: Request/Response objects with validation"
echo "  ├── Security: JWT authentication & authorization"
echo "  ├── Configuration: Database, Security, AI, Email, CORS"
echo "  └── Utils: File handling, validation, date utilities"
echo ""
echo "🛠️  Next Steps:"
echo "1. Set up your MySQL database:"
echo "   cd docker && docker-compose up -d mysql"
echo ""
echo "2. Configure environment variables:"
echo "   export JWT_SECRET='your-secret-key'"
echo "   export OPENAI_API_KEY='your-openai-key'"
echo "   export AWS_ACCESS_KEY='your-aws-key'"
echo "   export AWS_SECRET_KEY='your-aws-secret'"
echo ""
echo "3. Build and run the application:"
echo "   ./gradlew build"
echo "   ./gradlew bootRun"
echo ""
echo "4. Access the API at: http://localhost:8080"
echo "   - Swagger UI: http://localhost:8080/swagger-ui.html"
echo "   - Health Check: http://localhost:8080/actuator/health"
echo ""
echo "📚 API Endpoints will be available at:"
echo "   - POST /api/auth/login"
echo "   - POST /api/auth/register"
echo "   - GET /api/users"
echo "   - POST /api/documents/upload"
echo "   - GET /api/universities"
echo "   - POST /api/audits"
echo "   - GET /api/messages"
echo "   - POST /api/ai/analyze"
echo ""
echo "🎯 Ready to start building your frontend!"
echo "=================================================="