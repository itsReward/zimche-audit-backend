#!/bin/bash

# Generate Service Classes for ZIMCHE Audit System

BASE_DIR="src/main/kotlin/com/zimche/audit"
SERVICE_DIR="$BASE_DIR/service"

echo "🔧 Generating Service classes..."

mkdir -p $SERVICE_DIR

cat > $SERVICE_DIR/AuthService.kt << 'EOF'
package com.zimche.audit.service

import com.zimche.audit.dto.request.LoginRequest
import com.zimche.audit.dto.request.RegisterRequest
import com.zimche.audit.dto.response.AuthResponse
import com.zimche.audit.entity.User
import com.zimche.audit.enums.UserRole
import com.zimche.audit.exception.BadRequestException
import com.zimche.audit.exception.UnauthorizedException
import com.zimche.audit.repository.UserRepository
import com.zimche.audit.security.JwtTokenProvider
import org.springframework.security.authentication.AuthenticationManager
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional
class AuthService(
    private val userRepository: UserRepository,
    private val passwordEncoder: PasswordEncoder,
    private val authenticationManager: AuthenticationManager,
    private val jwtTokenProvider: JwtTokenProvider,
    private val universityService: UniversityService,
    private val emailService: EmailService
) {

    fun login(loginRequest: LoginRequest): AuthResponse {
        try {
            authenticationManager.authenticate(
                UsernamePasswordAuthenticationToken(
                    loginRequest.email,
                    loginRequest.password
                )
            )
        } catch (e: Exception) {
            throw UnauthorizedException("Invalid email or password")
        }

        val user = userRepository.findByEmail(loginRequest.email)
            .orElseThrow { UnauthorizedException("User not found") }

        if (!user.isActive) {
            throw UnauthorizedException("Account is deactivated")
        }

        val token = jwtTokenProvider.generateToken(user.email)

        return AuthResponse(
            token = token,
            type = "Bearer",
            email = user.email,
            role = user.role.name,
            fullName = user.fullName,
            universityId = user.university?.id
        )
    }

    fun register(registerRequest: RegisterRequest): AuthResponse {
        if (userRepository.existsByEmail(registerRequest.email)) {
            throw BadRequestException("Email is already registered")
        }

        val university = registerRequest.universityId?.let {
            universityService.findById(it)
        }

        val user = User(
            email = registerRequest.email,
            password = passwordEncoder.encode(registerRequest.password),
            firstName = registerRequest.firstName,
            lastName = registerRequest.lastName,
            role = registerRequest.role ?: UserRole.UNIVERSITY_STAFF,
            phoneNumber = registerRequest.phoneNumber,
            university = university
        )

        val savedUser = userRepository.save(user)

        // Send welcome email
        emailService.sendWelcomeEmail(savedUser)

        val token = jwtTokenProvider.generateToken(savedUser.email)

        return AuthResponse(
            token = token,
            type = "Bearer",
            email = savedUser.email,
            role = savedUser.role.name,
            fullName = savedUser.fullName,
            universityId = savedUser.university?.id
        )
    }

    fun getCurrentUser(email: String): User {
        return userRepository.findByEmail(email)
            .orElseThrow { UnauthorizedException("User not found") }
    }

    fun changePassword(email: String, oldPassword: String, newPassword: String) {
        val user = getCurrentUser(email)

        if (!passwordEncoder.matches(oldPassword, user.password)) {
            throw BadRequestException("Current password is incorrect")
        }

        val updatedUser = user.copy(password = passwordEncoder.encode(newPassword))
        userRepository.save(updatedUser)
    }

    fun forgotPassword(email: String) {
        val user = userRepository.findByEmail(email)
            .orElseThrow { BadRequestException("Email not found") }

        // Generate reset token and send email
        val resetToken = jwtTokenProvider.generatePasswordResetToken(email)
        emailService.sendPasswordResetEmail(user, resetToken)
    }

    fun resetPassword(token: String, newPassword: String) {
        val email = jwtTokenProvider.getEmailFromToken(token)
        if (!jwtTokenProvider.validateToken(token)) {
            throw BadRequestException("Invalid or expired reset token")
        }

        val user = getCurrentUser(email)
        val updatedUser = user.copy(password = passwordEncoder.encode(newPassword))
        userRepository.save(updatedUser)
    }
}
EOF

cat > $SERVICE_DIR/UserService.kt << 'EOF'
package com.zimche.audit.service

import com.zimche.audit.dto.response.UserResponse
import com.zimche.audit.entity.User
import com.zimche.audit.enums.UserRole
import com.zimche.audit.exception.BadRequestException
import com.zimche.audit.exception.ResourceNotFoundException
import com.zimche.audit.repository.UserRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional
class UserService(
    private val userRepository: UserRepository,
    private val universityService: UniversityService
) {

    fun findById(id: Long): User {
        return userRepository.findById(id)
            .orElseThrow { ResourceNotFoundException("User not found with id: $id") }
    }

    fun findByEmail(email: String): User {
        return userRepository.findByEmail(email)
            .orElseThrow { ResourceNotFoundException("User not found with email: $email") }
    }

    @Transactional(readOnly = true)
    fun getAllUsers(pageable: Pageable): Page<UserResponse> {
        return userRepository.findAll(pageable).map { UserResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun searchUsers(
        role: UserRole?,
        universityId: Long?,
        search: String?,
        pageable: Pageable
    ): Page<UserResponse> {
        return userRepository.findUsersWithFilters(role, universityId, search, pageable)
            .map { UserResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun getUsersByUniversity(universityId: Long): List<UserResponse> {
        return userRepository.findByUniversityId(universityId).map { UserResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun getUsersByRole(role: UserRole): List<UserResponse> {
        return userRepository.findByRole(role).map { UserResponse.from(it) }
    }

    fun updateUser(
        id: Long,
        firstName: String?,
        lastName: String?,
        phoneNumber: String?,
        universityId: Long?
    ): UserResponse {
        val user = findById(id)

        val university = universityId?.let { universityService.findById(it) }

        val updatedUser = user.copy(
            firstName = firstName ?: user.firstName,
            lastName = lastName ?: user.lastName,
            phoneNumber = phoneNumber ?: user.phoneNumber,
            university = university ?: user.university
        )

        return UserResponse.from(userRepository.save(updatedUser))
    }

    fun updateUserRole(id: Long, role: UserRole): UserResponse {
        val user = findById(id)
        val updatedUser = user.copy(role = role)
        return UserResponse.from(userRepository.save(updatedUser))
    }

    fun deactivateUser(id: Long): UserResponse {
        val user = findById(id)
        if (user.role == UserRole.ADMIN) {
            val adminCount = userRepository.countByRole(UserRole.ADMIN)
            if (adminCount <= 1) {
                throw BadRequestException("Cannot deactivate the last admin user")
            }
        }
        val updatedUser = user.copy(isActive = false)
        return UserResponse.from(userRepository.save(updatedUser))
    }

    fun activateUser(id: Long): UserResponse {
        val user = findById(id)
        val updatedUser = user.copy(isActive = true)
        return UserResponse.from(userRepository.save(updatedUser))
    }

    fun deleteUser(id: Long) {
        val user = findById(id)
        if (user.role == UserRole.ADMIN) {
            val adminCount = userRepository.countByRole(UserRole.ADMIN)
            if (adminCount <= 1) {
                throw BadRequestException("Cannot delete the last admin user")
            }
        }
        userRepository.delete(user)
    }

    @Transactional(readOnly = true)
    fun getUserStats(): Map<String, Any> {
        val totalUsers = userRepository.count()
        val activeUsers = userRepository.findByIsActiveTrue().size
        val usersByRole = UserRole.values().associate { role ->
            role.name to userRepository.countByRole(role)
        }

        return mapOf(
            "totalUsers" to totalUsers,
            "activeUsers" to activeUsers,
            "usersByRole" to usersByRole
        )
    }
}
EOF

cat > $SERVICE_DIR/UniversityService.kt << 'EOF'
package com.zimche.audit.service

import com.zimche.audit.dto.request.UniversityCreateRequest
import com.zimche.audit.dto.response.UniversityResponse
import com.zimche.audit.entity.University
import com.zimche.audit.exception.BadRequestException
import com.zimche.audit.exception.ResourceNotFoundException
import com.zimche.audit.repository.UniversityRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional
class UniversityService(
    private val universityRepository: UniversityRepository
) {

    fun findById(id: Long): University {
        return universityRepository.findById(id)
            .orElseThrow { ResourceNotFoundException("University not found with id: $id") }
    }

    fun findByCode(code: String): University {
        return universityRepository.findByCode(code)
            .orElseThrow { ResourceNotFoundException("University not found with code: $code") }
    }

    @Transactional(readOnly = true)
    fun getAllUniversities(pageable: Pageable): Page<UniversityResponse> {
        return universityRepository.findAll(pageable).map { UniversityResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun getActiveUniversities(): List<UniversityResponse> {
        return universityRepository.findByIsActiveTrue().map { UniversityResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun searchUniversities(search: String?, pageable: Pageable): Page<UniversityResponse> {
        return universityRepository.findUniversitiesWithSearch(search, pageable)
            .map { UniversityResponse.from(it) }
    }

    fun createUniversity(request: UniversityCreateRequest): UniversityResponse {
        if (universityRepository.existsByCode(request.code)) {
            throw BadRequestException("University with code '${request.code}' already exists")
        }

        if (universityRepository.existsByName(request.name)) {
            throw BadRequestException("University with name '${request.name}' already exists")
        }

        val university = University(
            name = request.name,
            code = request.code,
            address = request.address,
            contactEmail = request.contactEmail,
            contactPhone = request.contactPhone,
            website = request.website,
            establishedYear = request.establishedYear
        )

        return UniversityResponse.from(universityRepository.save(university))
    }

    fun updateUniversity(
        id: Long,
        request: UniversityCreateRequest
    ): UniversityResponse {
        val university = findById(id)

        // Check for duplicate code (excluding current university)
        universityRepository.findByCode(request.code).ifPresent { existing ->
            if (existing.id != id) {
                throw BadRequestException("University with code '${request.code}' already exists")
            }
        }

        val updatedUniversity = university.copy(
            name = request.name,
            code = request.code,
            address = request.address,
            contactEmail = request.contactEmail,
            contactPhone = request.contactPhone,
            website = request.website,
            establishedYear = request.establishedYear
        )

        return UniversityResponse.from(universityRepository.save(updatedUniversity))
    }

    fun deactivateUniversity(id: Long): UniversityResponse {
        val university = findById(id)
        val updatedUniversity = university.copy(isActive = false)
        return UniversityResponse.from(universityRepository.save(updatedUniversity))
    }

    fun activateUniversity(id: Long): UniversityResponse {
        val university = findById(id)
        val updatedUniversity = university.copy(isActive = true)
        return UniversityResponse.from(universityRepository.save(updatedUniversity))
    }

    fun deleteUniversity(id: Long) {
        val university = findById(id)

        // Check if university has associated users or documents
        if (university.users.isNotEmpty()) {
            throw BadRequestException("Cannot delete university with associated users")
        }

        if (university.documents.isNotEmpty()) {
            throw BadRequestException("Cannot delete university with associated documents")
        }

        universityRepository.delete(university)
    }

    @Transactional(readOnly = true)
    fun getUniversityWithUsers(id: Long): University {
        return universityRepository.findByIdWithUsers(id)
            .orElseThrow { ResourceNotFoundException("University not found with id: $id") }
    }

    @Transactional(readOnly = true)
    fun getUniversityStats(): Map<String, Any> {
        val totalUniversities = universityRepository.count()
        val activeUniversities = universityRepository.countActiveUniversities()

        return mapOf(
            "totalUniversities" to totalUniversities,
            "activeUniversities" to activeUniversities
        )
    }
}
EOF

cat > $SERVICE_DIR/DocumentService.kt << 'EOF'
package com.zimche.audit.service

import com.zimche.audit.dto.response.DocumentResponse
import com.zimche.audit.entity.Document
import com.zimche.audit.enums.DocumentStatus
import com.zimche.audit.exception.BadRequestException
import com.zimche.audit.exception.ResourceNotFoundException
import com.zimche.audit.repository.DocumentRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.multipart.MultipartFile
import java.time.LocalDateTime

@Service
@Transactional
class DocumentService(
    private val documentRepository: DocumentRepository,
    private val userService: UserService,
    private val universityService: UniversityService,
    private val fileStorageService: FileStorageService,
    private val aiService: AIService,
    private val messagingService: MessagingService
) {

    fun findById(id: Long): Document {
        return documentRepository.findById(id)
            .orElseThrow { ResourceNotFoundException("Document not found with id: $id") }
    }

    @Transactional(readOnly = true)
    fun getAllDocuments(pageable: Pageable): Page<DocumentResponse> {
        return documentRepository.findAll(pageable).map { DocumentResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun searchDocuments(
        universityId: Long?,
        status: DocumentStatus?,
        uploadedById: Long?,
        search: String?,
        pageable: Pageable
    ): Page<DocumentResponse> {
        return documentRepository.findDocumentsWithFilters(
            universityId, status, uploadedById, search, pageable
        ).map { DocumentResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun getDocumentsByUniversity(universityId: Long, pageable: Pageable): Page<DocumentResponse> {
        return documentRepository.findByUniversityId(universityId, pageable)
            .map { DocumentResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun getDocumentsByStatus(status: DocumentStatus): List<DocumentResponse> {
        return documentRepository.findByStatus(status).map { DocumentResponse.from(it) }
    }

    fun uploadDocument(
        file: MultipartFile,
        title: String,
        description: String?,
        universityId: Long,
        userEmail: String
    ): DocumentResponse {
        val user = userService.findByEmail(userEmail)
        val university = universityService.findById(universityId)

        // Validate file
        if (file.isEmpty) {
            throw BadRequestException("File cannot be empty")
        }

        val maxFileSize = 50 * 1024 * 1024 // 50MB
        if (file.size > maxFileSize) {
            throw BadRequestException("File size cannot exceed 50MB")
        }

        // Upload file to storage
        val fileUrl = fileStorageService.uploadFile(file, "documents")

        val document = Document(
            title = title,
            fileName = file.originalFilename ?: "unknown",
            fileUrl = fileUrl,
            fileSize = file.size,
            contentType = file.contentType,
            description = description,
            university = university,
            uploadedBy = user
        )

        val savedDocument = documentRepository.save(document)

        // Send notification to admins
        messagingService.notifyDocumentUploaded(savedDocument)

        // Trigger AI analysis
        aiService.scheduleDocumentAnalysis(savedDocument.id)

        return DocumentResponse.from(savedDocument)
    }

    fun updateDocumentStatus(
        documentId: Long,
        status: DocumentStatus,
        reviewComments: String?,
        reviewerEmail: String
    ): DocumentResponse {
        val document = findById(documentId)
        val reviewer = userService.findByEmail(reviewerEmail)

        val updatedDocument = document.copy(
            status = status,
            reviewedBy = reviewer,
            reviewedAt = LocalDateTime.now(),
            reviewComments = reviewComments
        )

        val savedDocument = documentRepository.save(updatedDocument)

        // Send notification to uploader
        messagingService.notifyDocumentStatusChanged(savedDocument)

        return DocumentResponse.from(savedDocument)
    }

    fun updateDocument(
        documentId: Long,
        title: String?,
        description: String?,
        userEmail: String
    ): DocumentResponse {
        val document = findById(documentId)
        val user = userService.findByEmail(userEmail)

        // Check if user has permission to update
        if (document.uploadedBy.id != user.id && user.role.name != "ADMIN") {
            throw BadRequestException("You don't have permission to update this document")
        }

        val updatedDocument = document.copy(
            title = title ?: document.title,
            description = description ?: document.description
        )

        return DocumentResponse.from(documentRepository.save(updatedDocument))
    }

    fun deleteDocument(documentId: Long, userEmail: String) {
        val document = findById(documentId)
        val user = userService.findByEmail(userEmail)

        // Check if user has permission to delete
        if (document.uploadedBy.id != user.id && user.role.name != "ADMIN") {
            throw BadRequestException("You don't have permission to delete this document")
        }

        // Delete file from storage
        fileStorageService.deleteFile(document.fileUrl)

        // Delete document record
        documentRepository.delete(document)
    }

    @Transactional(readOnly = true)
    fun getDocumentWithAnalyses(documentId: Long): Document {
        return documentRepository.findByIdWithAnalyses(documentId)
            ?: throw ResourceNotFoundException("Document not found with id: $documentId")
    }

    @Transactional(readOnly = true)
    fun downloadDocument(documentId: Long, userEmail: String): String {
        val document = findById(documentId)
        val user = userService.findByEmail(userEmail)

        // Check access permissions based on user role and university
        when (user.role) {
            com.zimche.audit.enums.UserRole.ADMIN,
            com.zimche.audit.enums.UserRole.PEER_REVIEWER -> {
                // Admins and reviewers can access all documents
            }
            com.zimche.audit.enums.UserRole.UNIVERSITY_STAFF -> {
                // University staff can only access their university's documents
                if (document.university.id != user.university?.id) {
                    throw BadRequestException("You don't have permission to access this document")
                }
            }
            else -> throw BadRequestException("You don't have permission to access this document")
        }

        return fileStorageService.generateDownloadUrl(document.fileUrl)
    }

    @Transactional(readOnly = true)
    fun getDocumentStats(): Map<String, Any> {
        val totalDocuments = documentRepository.count()
        val documentsByStatus = DocumentStatus.values().associate { status ->
            status.name to documentRepository.countByStatus(status)
        }

        return mapOf(
            "totalDocuments" to totalDocuments,
            "documentsByStatus" to documentsByStatus
        )
    }

    @Transactional(readOnly = true)
    fun getUniversityDocumentStats(universityId: Long): Map<String, Any> {
        val totalDocuments = documentRepository.countByUniversityId(universityId)
        val totalFileSize = documentRepository.getTotalFileSizeByUniversity(universityId) ?: 0L

        return mapOf(
            "totalDocuments" to totalDocuments,
            "totalFileSize" to totalFileSize
        )
    }
}
EOF

cat > $SERVICE_DIR/FileStorageService.kt << 'EOF'
package com.zimche.audit.service

import com.zimche.audit.exception.BadRequestException
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import org.springframework.web.multipart.MultipartFile
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider
import software.amazon.awssdk.core.sync.RequestBody
import software.amazon.awssdk.regions.Region
import software.amazon.awssdk.services.s3.S3Client
import software.amazon.awssdk.services.s3.model.*
import software.amazon.awssdk.services.s3.presigner.S3Presigner
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest
import java.time.Duration
import java.util.*

@Service
class FileStorageService(
    @Value("\${app.aws.access-key}") private val accessKey: String,
    @Value("\${app.aws.secret-key}") private val secretKey: String,
    @Value("\${app.aws.region}") private val region: String,
    @Value("\${app.aws.s3-bucket}") private val bucketName: String
) {

    private val s3Client: S3Client by lazy {
        val credentials = AwsBasicCredentials.create(accessKey, secretKey)
        S3Client.builder()
            .region(Region.of(region))
            .credentialsProvider(StaticCredentialsProvider.create(credentials))
            .build()
    }

    private val s3Presigner: S3Presigner by lazy {
        val credentials = AwsBasicCredentials.create(accessKey, secretKey)
        S3Presigner.builder()
            .region(Region.of(region))
            .credentialsProvider(StaticCredentialsProvider.create(credentials))
            .build()
    }

    fun uploadFile(file: MultipartFile, folder: String): String {
        try {
            val fileName = generateUniqueFileName(file.originalFilename ?: "file")
            val key = "$folder/$fileName"

            val putObjectRequest = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .contentType(file.contentType)
                .contentLength(file.size)
                .build()

            s3Client.putObject(putObjectRequest, RequestBody.fromInputStream(file.inputStream, file.size))

            return "https://$bucketName.s3.$region.amazonaws.com/$key"
        } catch (e: Exception) {
            throw BadRequestException("Failed to upload file: ${e.message}")
        }
    }

    fun deleteFile(fileUrl: String) {
        try {
            val key = extractKeyFromUrl(fileUrl)
            val deleteObjectRequest = DeleteObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .build()

            s3Client.deleteObject(deleteObjectRequest)
        } catch (e: Exception) {
            // Log error but don't throw exception to avoid breaking document deletion
            println("Failed to delete file from S3: ${e.message}")
        }
    }

    fun generateDownloadUrl(fileUrl: String): String {
        return try {
            val key = extractKeyFromUrl(fileUrl)
            val getObjectRequest = GetObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .build()

            val presignRequest = GetObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(60)) // URL valid for 1 hour
                .getObjectRequest(getObjectRequest)
                .build()

            s3Presigner.presignGetObject(presignRequest).url().toString()
        } catch (e: Exception) {
            throw BadRequestException("Failed to generate download URL: ${e.message}")
        }
    }

    private fun generateUniqueFileName(originalFileName: String): String {
        val timestamp = System.currentTimeMillis()
        val uuid = UUID.randomUUID().toString().substring(0, 8)
        val extension = originalFileName.substringAfterLast(".", "")
        val name = originalFileName.substringBeforeLast(".")
            .replace(" ", "_")
            .replace("[^a-zA-Z0-9._-]".toRegex(), "")

        return if (extension.isNotEmpty()) {
            "${name}_${timestamp}_${uuid}.$extension"
        } else {
            "${name}_${timestamp}_${uuid}"
        }
    }

    private fun extractKeyFromUrl(fileUrl: String): String {
        // Extract key from S3 URL format: https://bucket.s3.region.amazonaws.com/key
        return fileUrl.substringAfter("amazonaws.com/")
    }
}
EOF

cat > $SERVICE_DIR/AIService.kt << 'EOF'
package com.zimche.audit.service

import com.theokanning.openai.completion.chat.ChatCompletionRequest
import com.theokanning.openai.completion.chat.ChatMessage
import com.theokanning.openai.completion.chat.ChatMessageRole
import com.theokanning.openai.service.OpenAiService
import com.zimche.audit.dto.response.AIAnalysisResponse
import com.zimche.audit.entity.AIAnalysis
import com.zimche.audit.entity.Document
import com.zimche.audit.exception.BadRequestException
import com.zimche.audit.repository.AIAnalysisRepository
import org.apache.tika.Tika
import org.springframework.beans.factory.annotation.Value
import org.springframework.scheduling.annotation.Async
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Duration

@Service
@Transactional
class AIService(
    private val aiAnalysisRepository: AIAnalysisRepository,
    private val documentService: DocumentService,
    private val userService: UserService,
    @Value("\${app.openai.api-key}") private val openAiApiKey: String,
    @Value("\${app.openai.model}") private val model: String,
    @Value("\${app.openai.max-tokens}") private val maxTokens: Int
) {

    private val openAiService: OpenAiService by lazy {
        OpenAiService(openAiApiKey, Duration.ofSeconds(60))
    }

    private val tika = Tika()

    @Async
    fun scheduleDocumentAnalysis(documentId: Long) {
        try {
            val document = documentService.findById(documentId)

            // Extract text from document
            val documentText = extractTextFromDocument(document)

            // Perform different types of analysis
            performSummaryAnalysis(document, documentText)
            performComplianceAnalysis(document, documentText)
            performBiasAnalysis(document, documentText)

        } catch (e: Exception) {
            println("Failed to analyze document $documentId: ${e.message}")
        }
    }

    fun analyzeDocument(
        documentId: Long,
        analysisType: String,
        userEmail: String
    ): AIAnalysisResponse {
        val document = documentService.findById(documentId)
        val user = userService.findByEmail(userEmail)
        val documentText = extractTextFromDocument(document)

        val result = when (analysisType.uppercase()) {
            "SUMMARY" -> generateSummary(documentText)
            "COMPLIANCE" -> checkCompliance(documentText)
            "BIAS" -> detectBias(documentText)
            "QUALITY" -> assessQuality(documentText)
            else -> throw BadRequestException("Unsupported analysis type: $analysisType")
        }

        val analysis = AIAnalysis(
            analysisType = analysisType.uppercase(),
            prompt = buildPrompt(analysisType, documentText),
            result = result.response,
            confidenceScore = result.confidence,
            tokensUsed = result.tokensUsed,
            processingTimeMs = result.processingTime,
            modelVersion = model,
            document = document,
            requestedBy = user
        )

        val savedAnalysis = aiAnalysisRepository.save(analysis)
        return AIAnalysisResponse.from(savedAnalysis)
    }

    private fun extractTextFromDocument(document: Document): String {
        return try {
            // In a real implementation, you would download the file from S3 and extract text
            // For now, we'll simulate with the document title and description
            "${document.title}\n\n${document.description ?: ""}"
        } catch (e: Exception) {
            throw BadRequestException("Failed to extract text from document: ${e.message}")
        }
    }

    private fun performSummaryAnalysis(document: Document, text: String) {
        val result = generateSummary(text)
        saveAnalysis("SUMMARY", document, text, result, document.uploadedBy)
    }

    private fun performComplianceAnalysis(document: Document, text: String) {
        val result = checkCompliance(text)
        saveAnalysis("COMPLIANCE", document, text, result, document.uploadedBy)
    }

    private fun performBiasAnalysis(document: Document, text: String) {
        val result = detectBias(text)
        saveAnalysis("BIAS", document, text, result, document.uploadedBy)
    }

    private fun generateSummary(text: String): AIResult {
        val prompt = """
            Please provide a concise summary of the following document.
            Focus on key points, main findings, and important conclusions.
            Keep the summary under 300 words.

            Document:
            $text
        """.trimIndent()

        return callOpenAI(prompt)
    }

    private fun checkCompliance(text: String): AIResult {
        val prompt = """
            Analyze the following document for compliance with university audit standards.
            Check for:
            1. Required documentation completeness
            2. Adherence to regulatory guidelines
            3. Data accuracy and consistency
            4. Missing information or red flags

            Provide a compliance score (0-100) and detailed explanation.

            Document:
            $text
        """.trimIndent()

        return callOpenAI(prompt)
    }

    private fun detectBias(text: String): AIResult {
        val prompt = """
            Analyze the following document for potential bias or unfair treatment.
            Look for:
            1. Language that favors certain groups
            2. Unequal representation or treatment
            3. Discriminatory practices or policies
            4. Cultural or gender bias

            Provide a bias assessment and recommendations for improvement.

            Document:
            $text
        """.trimIndent()

        return callOpenAI(prompt)
    }

    private fun assessQuality(text: String): AIResult {
        val prompt = """
            Assess the overall quality of the following document.
            Evaluate:
            1. Clarity and coherence of content
            2. Completeness of information
            3. Professional presentation
            4. Accuracy and reliability

            Provide a quality score (0-100) and improvement suggestions.

            Document:
            $text
        """.trimIndent()

        return callOpenAI(prompt)
    }

    private fun callOpenAI(prompt: String): AIResult {
        val startTime = System.currentTimeMillis()

        try {
            val chatMessage = ChatMessage(ChatMessageRole.USER.value(), prompt)
            val request = ChatCompletionRequest.builder()
                .model(model)
                .messages(listOf(chatMessage))
                .maxTokens(maxTokens)
                .temperature(0.3)
                .build()

            val response = openAiService.createChatCompletion(request)
            val content = response.choices.firstOrNull()?.message?.content ?: "No response generated"
            val tokensUsed = response.usage?.totalTokens ?: 0
            val processingTime = System.currentTimeMillis() - startTime

            return AIResult(
                response = content,
                confidence = calculateConfidence(content),
                tokensUsed = tokensUsed,
                processingTime = processingTime
            )
        } catch (e: Exception) {
            throw BadRequestException("AI analysis failed: ${e.message}")
        }
    }

    private fun calculateConfidence(response: String): Double {
        // Simple confidence calculation based on response length and keywords
        val length = response.length
        val confidenceKeywords = listOf("confident", "certain", "clear", "evident", "strongly")
        val uncertaintyKeywords = listOf("uncertain", "unclear", "possibly", "might", "could")

        var confidence = when {
            length < 50 -> 0.3
            length < 200 -> 0.6
            length < 500 -> 0.8
            else -> 0.9
        }

        val lowerResponse = response.lowercase()
        confidenceKeywords.forEach { keyword ->
            if (lowerResponse.contains(keyword)) confidence += 0.1
        }
        uncertaintyKeywords.forEach { keyword ->
            if (lowerResponse.contains(keyword)) confidence -= 0.1
        }

        return minOf(1.0, maxOf(0.0, confidence))
    }

    private fun buildPrompt(analysisType: String, text: String): String {
        return when (analysisType.uppercase()) {
            "SUMMARY" -> "Summarize: $text"
            "COMPLIANCE" -> "Check compliance: $text"
            "BIAS" -> "Detect bias: $text"
            "QUALITY" -> "Assess quality: $text"
            else -> "Analyze: $text"
        }
    }

    private fun saveAnalysis(
        analysisType: String,
        document: Document,
        text: String,
        result: AIResult,
        user: com.zimche.audit.entity.User
    ) {
        val analysis = AIAnalysis(
            analysisType = analysisType,
            prompt = buildPrompt(analysisType, text),
            result = result.response,
            confidenceScore = result.confidence,
            tokensUsed = result.tokensUsed,
            processingTimeMs = result.processingTime,
            modelVersion = model,
            document = document,
            requestedBy = user
        )
        aiAnalysisRepository.save(analysis)
    }

    @Transactional(readOnly = true)
    fun getDocumentAnalyses(documentId: Long): List<AIAnalysisResponse> {
        return aiAnalysisRepository.findByDocumentId(documentId)
            .map { AIAnalysisResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun getAnalysisStats(): Map<String, Any> {
        val totalAnalyses = aiAnalysisRepository.count()
        val totalTokensUsed = aiAnalysisRepository.getTotalTokensUsed() ?: 0L
        val avgProcessingTime = aiAnalysisRepository.getAverageProcessingTimeByType("SUMMARY") ?: 0.0

        return mapOf(
            "totalAnalyses" to totalAnalyses,
            "totalTokensUsed" to totalTokensUsed,
            "averageProcessingTime" to avgProcessingTime
        )
    }

    private data class AIResult(
        val response: String,
        val confidence: Double,
        val tokensUsed: Int,
        val processingTime: Long
    )
}
EOF

cat > $SERVICE_DIR/EmailService.kt << 'EOF'
package com.zimche.audit.service

import com.zimche.audit.entity.Document
import com.zimche.audit.entity.User
import org.springframework.beans.factory.annotation.Value
import org.springframework.mail.SimpleMailMessage
import org.springframework.mail.javamail.JavaMailSender
import org.springframework.scheduling.annotation.Async
import org.springframework.stereotype.Service

@Service
class EmailService(
    private val mailSender: JavaMailSender,
    @Value("\${spring.mail.username}") private val fromEmail: String,
    @Value("\${app.frontend.url:http://localhost:3000}") private val frontendUrl: String
) {

    @Async
    fun sendWelcomeEmail(user: User) {
        val message = SimpleMailMessage().apply {
            from = fromEmail
            setTo(user.email)
            subject = "Welcome to ZIMCHE Audit Management System"
            text = """
                Dear ${user.fullName},

                Welcome to the ZIMCHE University Audit Management System!

                Your account has been successfully created with the following details:
                - Email: ${user.email}
                - Role: ${user.role.displayName}
                ${if (user.university != null) "- University: ${user.university.name}" else ""}

                You can now log in to the system at: $frontendUrl

                If you have any questions, please contact our support team.

                Best regards,
                ZIMCHE Team
            """.trimIndent()
        }

        try {
            mailSender.send(message)
        } catch (e: Exception) {
            println("Failed to send welcome email to ${user.email}: ${e.message}")
        }
    }

    @Async
    fun sendPasswordResetEmail(user: User, resetToken: String) {
        val resetUrl = "$frontendUrl/reset-password?token=$resetToken"

        val message = SimpleMailMessage().apply {
            from = fromEmail
            setTo(user.email)
            subject = "Password Reset Request - ZIMCHE Audit System"
            text = """
                Dear ${user.fullName},

                You have requested to reset your password for the ZIMCHE Audit Management System.

                Please click the following link to reset your password:
                $resetUrl

                This link will expire in 1 hour for security reasons.

                If you did not request this password reset, please ignore this email.

                Best regards,
                ZIMCHE Team
            """.trimIndent()
        }

        try {
            mailSender.send(message)
        } catch (e: Exception) {
            println("Failed to send password reset email to ${user.email}: ${e.message}")
        }
    }

    @Async
    fun sendDocumentUploadNotification(document: Document, recipients: List<User>) {
        recipients.forEach { recipient ->
            val message = SimpleMailMessage().apply {
                from = fromEmail
                setTo(recipient.email)
                subject = "New Document Uploaded - ${document.title}"
                text = """
                    Dear ${recipient.fullName},

                    A new document has been uploaded to the ZIMCHE Audit Management System:

                    Document: ${document.title}
                    University: ${document.university.name}
                    Uploaded by: ${document.uploadedBy.fullName}
                    Upload date: ${document.createdAt}

                    Please log in to the system to review the document: $frontendUrl

                    Best regards,
                    ZIMCHE Team
                """.trimIndent()
            }

            try {
                mailSender.send(message)
            } catch (e: Exception) {
                println("Failed to send document upload notification to ${recipient.email}: ${e.message}")
            }
        }
    }

    @Async
    fun sendDocumentStatusChangeNotification(document: Document) {
        val message = SimpleMailMessage().apply {
            from = fromEmail
            setTo(document.uploadedBy.email)
            subject = "Document Status Updated - ${document.title}"
            text = """
                Dear ${document.uploadedBy.fullName},

                The status of your document has been updated:

                Document: ${document.title}
                New Status: ${document.status.displayName}
                Reviewed by: ${document.reviewedBy?.fullName ?: "System"}
                Review date: ${document.reviewedAt}

                ${if (document.reviewComments != null) "Comments: ${document.reviewComments}" else ""}

                Please log in to the system for more details: $frontendUrl

                Best regards,
                ZIMCHE Team
            """.trimIndent()
        }

        try {
            mailSender.send(message)
        } catch (e: Exception) {
            println("Failed to send status change notification to ${document.uploadedBy.email}: ${e.message}")
        }
    }

    @Async
    fun sendAuditReminderEmail(user: User, auditTitle: String, scheduledDate: String) {
        val message = SimpleMailMessage().apply {
            from = fromEmail
            setTo(user.email)
            subject = "Audit Reminder - $auditTitle"
            text = """
                Dear ${user.fullName},

                This is a reminder about the upcoming audit:

                Audit: $auditTitle
                Scheduled Date: $scheduledDate
                University: ${user.university?.name ?: "N/A"}

                Please ensure all required documents are submitted before the audit date.

                Log in to the system for more details: $frontendUrl

                Best regards,
                ZIMCHE Team
            """.trimIndent()
        }

        try {
            mailSender.send(message)
        } catch (e: Exception) {
            println("Failed to send audit reminder to ${user.email}: ${e.message}")
        }
    }
}
EOF

cat > $SERVICE_DIR/MessagingService.kt << 'EOF'
package com.zimche.audit.service

import com.zimche.audit.dto.request.MessageRequest
import com.zimche.audit.dto.response.MessageResponse
import com.zimche.audit.entity.Document
import com.zimche.audit.entity.Message
import com.zimche.audit.enums.MessageType
import com.zimche.audit.enums.UserRole
import com.zimche.audit.exception.ResourceNotFoundException
import com.zimche.audit.repository.MessageRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@Service
@Transactional
class MessagingService(
    private val messageRepository: MessageRepository,
    private val userService: UserService,
    private val emailService: EmailService
) {

    fun sendMessage(request: MessageRequest, senderEmail: String): MessageResponse {
        val sender = userService.findByEmail(senderEmail)
        val recipient = userService.findById(request.recipientId)

        val message = Message(
            subject = request.subject,
            content = request.content,
            type = request.type ?: MessageType.CHAT,
            sender = sender,
            recipient = recipient,
            relatedDocument = request.relatedDocumentId?.let {
                // documentService.findById(it) - would need to inject DocumentService
                null // Simplified for now
            },
            relatedAudit = request.relatedAuditId?.let {
                // auditService.findById(it) - would need to inject AuditService
                null // Simplified for now
            }
        )

        val savedMessage = messageRepository.save(message)

        // Send email notification for important messages
        if (request.type == MessageType.ALERT || request.type == MessageType.NOTIFICATION) {
            // emailService.sendMessageNotification(savedMessage) - implement if needed
        }

        return MessageResponse.from(savedMessage)
    }

    @Transactional(readOnly = true)
    fun getMessagesForUser(
        userEmail: String,
        type: MessageType?,
        isRead: Boolean?,
        search: String?,
        pageable: Pageable
    ): Page<MessageResponse> {
        val user = userService.findByEmail(userEmail)
        return messageRepository.findMessagesForRecipientWithFilters(
            user.id, type, isRead, search, pageable
        ).map { MessageResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun getConversation(
        userEmail: String,
        otherUserId: Long?,
        pageable: Pageable
    ): Page<MessageResponse> {
        val user = userService.findByEmail(userEmail)
        return messageRepository.findConversation(user.id, otherUserId, pageable)
            .map { MessageResponse.from(it) }
    }

    fun markMessageAsRead(messageId: Long, userEmail: String): MessageResponse {
        val message = messageRepository.findById(messageId)
            .orElseThrow { ResourceNotFoundException("Message not found with id: $messageId") }

        val user = userService.findByEmail(userEmail)

        if (message.recipient.id != user.id) {
            throw IllegalArgumentException("You can only mark your own messages as read")
        }

        if (!message.isRead) {
            messageRepository.markAsRead(messageId, LocalDateTime.now())
        }

        return MessageResponse.from(message.copy(isRead = true, readAt = LocalDateTime.now()))
    }

    fun markAllMessagesAsRead(userEmail: String) {
        val user = userService.findByEmail(userEmail)
        messageRepository.markAllAsReadForRecipient(user.id, LocalDateTime.now())
    }

    @Transactional(readOnly = true)
    fun getUnreadMessageCount(userEmail: String): Long {
        val user = userService.findByEmail(userEmail)
        return messageRepository.countUnreadByRecipientId(user.id)
    }

    fun notifyDocumentUploaded(document: Document) {
        // Send notification to all admins and peer reviewers
        val adminUsers = userService.getUsersByRole(UserRole.ADMIN)
        val reviewers = userService.getUsersByRole(UserRole.PEER_REVIEWER)

        val recipients = (adminUsers + reviewers).map { it.email }.distinct()

        recipients.forEach { recipientEmail ->
            try {
                val recipient = userService.findByEmail(recipientEmail)
                val message = Message(
                    subject = "New Document Uploaded: ${document.title}",
                    content = """
                        A new document has been uploaded by ${document.uploadedBy.fullName}
                        from ${document.university.name}.

                        Document: ${document.title}
                        Description: ${document.description ?: "No description provided"}

                        Please review the document at your earliest convenience.
                    """.trimIndent(),
                    type = MessageType.NOTIFICATION,
                    sender = document.uploadedBy,
                    recipient = recipient,
                    relatedDocument = document
                )

                messageRepository.save(message)
            } catch (e: Exception) {
                println("Failed to send notification to $recipientEmail: ${e.message}")
            }
        }

        // Also send email notifications
        val users = recipients.mapNotNull { email ->
            try { userService.findByEmail(email) } catch (e: Exception) { null }
        }
        emailService.sendDocumentUploadNotification(document, users)
    }

    fun notifyDocumentStatusChanged(document: Document) {
        val message = Message(
            subject = "Document Status Updated: ${document.title}",
            content = """
                The status of your document "${document.title}" has been updated to: ${document.status.displayName}

                ${if (document.reviewComments != null) "Review Comments: ${document.reviewComments}" else ""}

                Reviewed by: ${document.reviewedBy?.fullName ?: "System"}
                Review Date: ${document.reviewedAt}
            """.trimIndent(),
            type = MessageType.NOTIFICATION,
            sender = document.reviewedBy ?: document.uploadedBy,
            recipient = document.uploadedBy
        )

        messageRepository.save(message)
        emailService.sendDocumentStatusChangeNotification(document)
    }

    fun sendSystemMessage(subject: String, content: String, recipientIds: List<Long>) {
        val systemUser = userService.getUsersByRole(UserRole.ADMIN).firstOrNull()
            ?: throw IllegalStateException("No admin user found to send system messages")

        recipientIds.forEach { recipientId ->
            try {
                val recipient = userService.findById(recipientId)
                val message = Message(
                    subject = subject,
                    content = content,
                    type = MessageType.SYSTEM,
                    sender = userService.findByEmail(systemUser.email),
                    recipient = recipient
                )

                messageRepository.save(message)
            } catch (e: Exception) {
                println("Failed to send system message to user $recipientId: ${e.message}")
            }
        }
    }

    fun deleteMessage(messageId: Long, userEmail: String) {
        val message = messageRepository.findById(messageId)
            .orElseThrow { ResourceNotFoundException("Message not found with id: $messageId") }

        val user = userService.findByEmail(userEmail)

        if (message.recipient.id != user.id && message.sender.id != user.id) {
            throw IllegalArgumentException("You can only delete your own messages")
        }

        messageRepository.delete(message)
    }
}
EOF

echo "✅ Service classes generated successfully!"
echo "Generated files:"
echo "  - AuthService"
echo "  - UserService"
echo "  - UniversityService"
echo "  - DocumentService"
echo "  - FileStorageService"
echo "  - AIService"
echo "  - EmailService"
echo "  - MessagingService"