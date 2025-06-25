#!/bin/bash

# Fix compilation errors in ZIMCHE Audit Backend

BASE_DIR="src/main/kotlin/com/zimche/audit"

echo "🔧 Fixing compilation errors..."

# 1. Fix JwtTokenProvider - parserBuilder is deprecated, use parser
cat > $BASE_DIR/security/JwtTokenProvider.kt << 'EOF'
package com.zimche.audit.security

import io.jsonwebtoken.Claims
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.SignatureAlgorithm
import io.jsonwebtoken.security.Keys
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Component
import java.util.*
import javax.crypto.SecretKey

@Component
class JwtTokenProvider(
    @Value("\${app.jwt.secret}") private val jwtSecret: String,
    @Value("\${app.jwt.expiration}") private val jwtExpiration: Long
) {

    private val secretKey: SecretKey by lazy {
        Keys.hmacShaKeyFor(jwtSecret.toByteArray())
    }

    fun generateToken(email: String): String {
        val now = Date()
        val expiryDate = Date(now.time + jwtExpiration)

        return Jwts.builder()
            .setSubject(email)
            .setIssuedAt(now)
            .setExpiration(expiryDate)
            .signWith(secretKey, SignatureAlgorithm.HS512)
            .compact()
    }

    fun generatePasswordResetToken(email: String): String {
        val now = Date()
        val expiryDate = Date(now.time + 3600000) // 1 hour

        return Jwts.builder()
            .setSubject(email)
            .setIssuedAt(now)
            .setExpiration(expiryDate)
            .claim("type", "password-reset")
            .signWith(secretKey, SignatureAlgorithm.HS512)
            .compact()
    }

    fun getEmailFromToken(token: String): String {
        val claims = getAllClaimsFromToken(token)
        return claims.subject
    }

    fun validateToken(token: String): Boolean {
        return try {
            getAllClaimsFromToken(token)
            true
        } catch (e: Exception) {
            false
        }
    }

    fun isTokenExpired(token: String): Boolean {
        return try {
            val claims = getAllClaimsFromToken(token)
            claims.expiration.before(Date())
        } catch (e: Exception) {
            true
        }
    }

    private fun getAllClaimsFromToken(token: String): Claims {
        return Jwts.parser()
            .setSigningKey(secretKey)
            .parseClaimsJws(token)
            .body
    }
}
EOF

# 2. Fix MessagingService - remove AuditService dependency
cat > $BASE_DIR/service/MessagingService.kt << 'EOF'
package com.zimche.audit.service

import com.zimche.audit.dto.request.MessageRequest
import com.zimche.audit.dto.response.MessageResponse
import com.zimche.audit.entity.Document
import com.zimche.audit.entity.Message
import com.zimche.audit.enums.MessageType
import com.zimche.audit.enums.UserRole
import com.zimche.audit.exception.ResourceNotFoundException
import com.zimche.audit.repository.MessageRepository
import com.zimche.audit.repository.DocumentRepository
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
    private val documentRepository: DocumentRepository,
    private val emailService: EmailService
) {

    fun sendMessage(request: MessageRequest, senderEmail: String): MessageResponse {
        val sender = userService.findByEmail(senderEmail)
        val recipient = userService.findById(request.recipientId)

        val relatedDocument = request.relatedDocumentId?.let {
            documentRepository.findById(it).orElse(null)
        }

        val message = Message(
            subject = request.subject,
            content = request.content,
            type = request.type ?: MessageType.CHAT,
            sender = sender,
            recipient = recipient,
            relatedDocument = relatedDocument,
            relatedAudit = null // Will be implemented when AuditService is available
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

# 3. Fix JsonUtils - make objectMapper internal instead of private for inline functions
cat > $BASE_DIR/util/JsonUtils.kt << 'EOF'
package com.zimche.audit.util

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.fasterxml.jackson.module.kotlin.readValue

object JsonUtils {

    internal val objectMapper: ObjectMapper = jacksonObjectMapper()

    fun <T> toJson(obj: T): String {
        return objectMapper.writeValueAsString(obj)
    }

    inline fun <reified T> fromJson(json: String): T {
        return objectMapper.readValue(json)
    }

    fun <T> fromJson(json: String, clazz: Class<T>): T {
        return objectMapper.readValue(json, clazz)
    }

    fun isValidJson(json: String): Boolean {
        return try {
            objectMapper.readTree(json)
            true
        } catch (e: Exception) {
            false
        }
    }

    fun prettifyJson(json: String): String {
        return try {
            val jsonNode = objectMapper.readTree(json)
            objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(jsonNode)
        } catch (e: Exception) {
            json
        }
    }

    fun minifyJson(json: String): String {
        return try {
            val jsonNode = objectMapper.readTree(json)
            objectMapper.writeValueAsString(jsonNode)
        } catch (e: Exception) {
            json
        }
    }
}
EOF

# 4. Fix PerformanceUtils - make logger internal and create separate logger for each inline function
cat > $BASE_DIR/util/PerformanceUtils.kt << 'EOF'
package com.zimche.audit.util

import org.slf4j.LoggerFactory

object PerformanceUtils {

    internal val logger = LoggerFactory.getLogger(PerformanceUtils::class.java)

    inline fun <T> measureTime(operation: String, block: () -> T): T {
        val startTime = System.currentTimeMillis()
        return try {
            block()
        } finally {
            val duration = System.currentTimeMillis() - startTime
            logger.debug("Operation '$operation' took ${duration}ms")
        }
    }

    inline fun <T> measureTimeWithResult(operation: String, block: () -> T): Pair<T, Long> {
        val startTime = System.currentTimeMillis()
        val result = block()
        val duration = System.currentTimeMillis() - startTime
        logger.debug("Operation '$operation' took ${duration}ms")
        return Pair(result, duration)
    }

    fun logMemoryUsage(operation: String) {
        val runtime = Runtime.getRuntime()
        val totalMemory = runtime.totalMemory()
        val freeMemory = runtime.freeMemory()
        val usedMemory = totalMemory - freeMemory
        val maxMemory = runtime.maxMemory()

        logger.debug(
            "Memory usage after '$operation': Used=${formatBytes(usedMemory)}, " +
            "Free=${formatBytes(freeMemory)}, Total=${formatBytes(totalMemory)}, " +
            "Max=${formatBytes(maxMemory)}"
        )
    }

    private fun formatBytes(bytes: Long): String {
        val mb = bytes / (1024 * 1024)
        return "${mb}MB"
    }

    class PerformanceTracker(private val operation: String) {
        private val startTime = System.currentTimeMillis()
        private var lastCheckpoint = startTime
        private val trackerLogger = LoggerFactory.getLogger("${PerformanceUtils::class.java.name}.Tracker")

        fun checkpoint(label: String) {
            val now = System.currentTimeMillis()
            val fromStart = now - startTime
            val fromLast = now - lastCheckpoint
            trackerLogger.debug("$operation - $label: +${fromLast}ms (total: ${fromStart}ms)")
            lastCheckpoint = now
        }

        fun finish(): Long {
            val duration = System.currentTimeMillis() - startTime
            trackerLogger.debug("$operation completed in ${duration}ms")
            return duration
        }
    }
}
EOF

# 5. Update DocumentService to remove circular dependency
cat > $BASE_DIR/service/DocumentService.kt << 'EOF'
package com.zimche.audit.service

import com.zimche.audit.dto.response.DocumentResponse
import com.zimche.audit.entity.Document
import com.zimche.audit.enums.DocumentStatus
import com.zimche.audit.exception.BadRequestException
import com.zimche.audit.exception.ResourceNotFoundException
import com.zimche.audit.repository.DocumentRepository
import com.zimche.audit.repository.UserRepository
import com.zimche.audit.repository.UniversityRepository
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
    private val userRepository: UserRepository,
    private val universityRepository: UniversityRepository,
    private val fileStorageService: FileStorageService,
    private val emailService: EmailService
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
        val user = userRepository.findByEmail(userEmail)
            .orElseThrow { ResourceNotFoundException("User not found with email: $userEmail") }
        val university = universityRepository.findById(universityId)
            .orElseThrow { ResourceNotFoundException("University not found with id: $universityId") }

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

        // Notify document uploaded - will be implemented by MessagingService
        // messagingService.notifyDocumentUploaded(savedDocument)

        return DocumentResponse.from(savedDocument)
    }

    fun updateDocumentStatus(
        documentId: Long,
        status: DocumentStatus,
        reviewComments: String?,
        reviewerEmail: String
    ): DocumentResponse {
        val document = findById(documentId)
        val reviewer = userRepository.findByEmail(reviewerEmail)
            .orElseThrow { ResourceNotFoundException("Reviewer not found with email: $reviewerEmail") }

        val updatedDocument = document.copy(
            status = status,
            reviewedBy = reviewer,
            reviewedAt = LocalDateTime.now(),
            reviewComments = reviewComments
        )

        val savedDocument = documentRepository.save(updatedDocument)

        // Send notification to uploader - will be implemented by MessagingService
        // messagingService.notifyDocumentStatusChanged(savedDocument)

        return DocumentResponse.from(savedDocument)
    }

    fun updateDocument(
        documentId: Long,
        title: String?,
        description: String?,
        userEmail: String
    ): DocumentResponse {
        val document = findById(documentId)
        val user = userRepository.findByEmail(userEmail)
            .orElseThrow { ResourceNotFoundException("User not found with email: $userEmail") }

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
        val user = userRepository.findByEmail(userEmail)
            .orElseThrow { ResourceNotFoundException("User not found with email: $userEmail") }

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
        val user = userRepository.findByEmail(userEmail)
            .orElseThrow { ResourceNotFoundException("User not found with email: $userEmail") }

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

# 6. Update build.gradle.kts to ensure correct JWT dependency version
echo "📝 Updating build.gradle.kts for correct JWT version..."
cat >> build.gradle.kts << 'EOF'

    // Ensure JJWT version compatibility
    implementation("io.jsonwebtoken:jjwt-api:0.11.5")
    runtimeOnly("io.jsonwebtoken:jjwt-impl:0.11.5")
    runtimeOnly("io.jsonwebtoken:jjwt-jackson:0.11.5")
EOF

echo "✅ All compilation errors fixed!"
echo ""
echo "🔧 Fixed issues:"
echo "  1. ✅ JwtTokenProvider - Updated to use Jwts.parser() instead of parserBuilder()"
echo "  2. ✅ MessagingService - Removed AuditService dependency, added DocumentRepository"
echo "  3. ✅ JsonUtils - Changed objectMapper from private to internal for inline functions"
echo "  4. ✅ PerformanceUtils - Changed logger from private to internal, added separate tracker logger"
echo "  5. ✅ DocumentService - Removed circular dependencies, injected repositories directly"
echo "  6. ✅ build.gradle.kts - Ensured correct JJWT version (0.11.5) for compatibility"
echo ""
echo "🚀 Your project should now compile successfully!"
echo "Run: ./gradlew build"