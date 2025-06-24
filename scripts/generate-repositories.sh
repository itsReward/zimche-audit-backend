#!/bin/bash

# Generate Repository Classes for ZIMCHE Audit System

BASE_DIR="src/main/kotlin/com/zimche/audit"
REPO_DIR="$BASE_DIR/repository"

echo "🗄️  Generating Repository interfaces..."

mkdir -p $REPO_DIR

cat > $REPO_DIR/UserRepository.kt << 'EOF'
package com.zimche.audit.repository

import com.zimche.audit.entity.User
import com.zimche.audit.enums.UserRole
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

@Repository
interface UserRepository : JpaRepository<User, Long> {

    fun findByEmail(email: String): Optional<User>

    fun existsByEmail(email: String): Boolean

    fun findByRole(role: UserRole): List<User>

    fun findByUniversityId(universityId: Long): List<User>

    fun findByRoleAndUniversityId(role: UserRole, universityId: Long): List<User>

    fun findByIsActiveTrue(): List<User>

    fun findByFirstNameContainingIgnoreCaseOrLastNameContainingIgnoreCase(
        firstName: String,
        lastName: String
    ): List<User>

    @Query("""
        SELECT u FROM User u
        WHERE u.isActive = true
        AND (:role IS NULL OR u.role = :role)
        AND (:universityId IS NULL OR u.university.id = :universityId)
        AND (LOWER(u.firstName) LIKE LOWER(CONCAT('%', :search, '%'))
             OR LOWER(u.lastName) LIKE LOWER(CONCAT('%', :search, '%'))
             OR LOWER(u.email) LIKE LOWER(CONCAT('%', :search, '%')))
    """)
    fun findUsersWithFilters(
        @Param("role") role: UserRole?,
        @Param("universityId") universityId: Long?,
        @Param("search") search: String?,
        pageable: Pageable
    ): Page<User>

    @Query("SELECT COUNT(u) FROM User u WHERE u.role = :role")
    fun countByRole(@Param("role") role: UserRole): Long

    @Query("SELECT COUNT(u) FROM User u WHERE u.university.id = :universityId")
    fun countByUniversityId(@Param("universityId") universityId: Long): Long
}
EOF

cat > $REPO_DIR/UniversityRepository.kt << 'EOF'
package com.zimche.audit.repository

import com.zimche.audit.entity.University
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

@Repository
interface UniversityRepository : JpaRepository<University, Long> {

    fun findByCode(code: String): Optional<University>

    fun existsByCode(code: String): Boolean

    fun existsByName(name: String): Boolean

    fun findByIsActiveTrue(): List<University>

    fun findByNameContainingIgnoreCase(name: String): List<University>

    @Query("""
        SELECT u FROM University u
        WHERE u.isActive = true
        AND (LOWER(u.name) LIKE LOWER(CONCAT('%', :search, '%'))
             OR LOWER(u.code) LIKE LOWER(CONCAT('%', :search, '%'))
             OR LOWER(u.contactEmail) LIKE LOWER(CONCAT('%', :search, '%')))
    """)
    fun findUniversitiesWithSearch(
        @Param("search") search: String?,
        pageable: Pageable
    ): Page<University>

    @Query("SELECT COUNT(u) FROM University u WHERE u.isActive = true")
    fun countActiveUniversities(): Long

    @Query("""
        SELECT u FROM University u
        LEFT JOIN FETCH u.users
        WHERE u.id = :id AND u.isActive = true
    """)
    fun findByIdWithUsers(@Param("id") id: Long): Optional<University>
}
EOF

cat > $REPO_DIR/DocumentRepository.kt << 'EOF'
package com.zimche.audit.repository

import com.zimche.audit.entity.Document
import com.zimche.audit.enums.DocumentStatus
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

@Repository
interface DocumentRepository : JpaRepository<Document, Long> {

    fun findByUniversityId(universityId: Long): List<Document>

    fun findByUniversityId(universityId: Long, pageable: Pageable): Page<Document>

    fun findByStatus(status: DocumentStatus): List<Document>

    fun findByUploadedById(uploadedById: Long): List<Document>

    fun findByReviewedById(reviewedById: Long): List<Document>

    fun findByStatusAndUniversityId(status: DocumentStatus, universityId: Long): List<Document>

    fun findByCreatedAtBetween(startDate: LocalDateTime, endDate: LocalDateTime): List<Document>

    @Query("""
        SELECT d FROM Document d
        WHERE (:universityId IS NULL OR d.university.id = :universityId)
        AND (:status IS NULL OR d.status = :status)
        AND (:uploadedById IS NULL OR d.uploadedBy.id = :uploadedById)
        AND (LOWER(d.title) LIKE LOWER(CONCAT('%', :search, '%'))
             OR LOWER(d.fileName) LIKE LOWER(CONCAT('%', :search, '%')))
        ORDER BY d.createdAt DESC
    """)
    fun findDocumentsWithFilters(
        @Param("universityId") universityId: Long?,
        @Param("status") status: DocumentStatus?,
        @Param("uploadedById") uploadedById: Long?,
        @Param("search") search: String?,
        pageable: Pageable
    ): Page<Document>

    @Query("SELECT COUNT(d) FROM Document d WHERE d.status = :status")
    fun countByStatus(@Param("status") status: DocumentStatus): Long

    @Query("SELECT COUNT(d) FROM Document d WHERE d.university.id = :universityId")
    fun countByUniversityId(@Param("universityId") universityId: Long): Long

    @Query("""
        SELECT d FROM Document d
        LEFT JOIN FETCH d.aiAnalyses
        WHERE d.id = :id
    """)
    fun findByIdWithAnalyses(@Param("id") id: Long): Document?

    @Query("""
        SELECT SUM(d.fileSize) FROM Document d
        WHERE d.university.id = :universityId
    """)
    fun getTotalFileSizeByUniversity(@Param("universityId") universityId: Long): Long?
}
EOF

cat > $REPO_DIR/AuditRepository.kt << 'EOF'
package com.zimche.audit.repository

import com.zimche.audit.entity.Audit
import com.zimche.audit.enums.AuditStatus
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

@Repository
interface AuditRepository : JpaRepository<Audit, Long> {

    fun findByUniversityId(universityId: Long): List<Audit>

    fun findByUniversityId(universityId: Long, pageable: Pageable): Page<Audit>

    fun findByStatus(status: AuditStatus): List<Audit>

    fun findByAssignedToId(assignedToId: Long): List<Audit>

    fun findByCreatedById(createdById: Long): List<Audit>

    fun findByStatusAndUniversityId(status: AuditStatus, universityId: Long): List<Audit>

    fun findByScheduledDateBetween(startDate: LocalDateTime, endDate: LocalDateTime): List<Audit>

    @Query("""
        SELECT a FROM Audit a
        WHERE (:universityId IS NULL OR a.university.id = :universityId)
        AND (:status IS NULL OR a.status = :status)
        AND (:assignedToId IS NULL OR a.assignedTo.id = :assignedToId)
        AND (LOWER(a.title) LIKE LOWER(CONCAT('%', :search, '%'))
             OR LOWER(a.description) LIKE LOWER(CONCAT('%', :search, '%')))
        ORDER BY a.scheduledDate DESC
    """)
    fun findAuditsWithFilters(
        @Param("universityId") universityId: Long?,
        @Param("status") status: AuditStatus?,
        @Param("assignedToId") assignedToId: Long?,
        @Param("search") search: String?,
        pageable: Pageable
    ): Page<Audit>

    @Query("SELECT COUNT(a) FROM Audit a WHERE a.status = :status")
    fun countByStatus(@Param("status") status: AuditStatus): Long

    @Query("SELECT COUNT(a) FROM Audit a WHERE a.university.id = :universityId")
    fun countByUniversityId(@Param("universityId") universityId: Long): Long

    @Query("""
        SELECT a FROM Audit a
        LEFT JOIN FETCH a.auditSteps
        WHERE a.id = :id
    """)
    fun findByIdWithSteps(@Param("id") id: Long): Audit?

    @Query("""
        SELECT a FROM Audit a
        WHERE a.status IN (:statuses)
        AND a.scheduledDate <= :date
        ORDER BY a.scheduledDate ASC
    """)
    fun findUpcomingAudits(
        @Param("statuses") statuses: List<AuditStatus>,
        @Param("date") date: LocalDateTime
    ): List<Audit>

    @Query("""
        SELECT AVG(a.complianceScore) FROM Audit a
        WHERE a.university.id = :universityId
        AND a.complianceScore IS NOT NULL
    """)
    fun getAverageComplianceScoreByUniversity(@Param("universityId") universityId: Long): Double?
}
EOF

cat > $REPO_DIR/MessageRepository.kt << 'EOF'
package com.zimche.audit.repository

import com.zimche.audit.entity.Message
import com.zimche.audit.enums.MessageType
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

@Repository
interface MessageRepository : JpaRepository<Message, Long> {

    fun findByRecipientId(recipientId: Long): List<Message>

    fun findByRecipientId(recipientId: Long, pageable: Pageable): Page<Message>

    fun findBySenderId(senderId: Long): List<Message>

    fun findByRecipientIdAndIsReadFalse(recipientId: Long): List<Message>

    fun findByType(type: MessageType): List<Message>

    fun findByRecipientIdAndType(recipientId: Long, type: MessageType): List<Message>

    @Query("""
        SELECT m FROM Message m
        WHERE m.recipient.id = :recipientId
        AND (:type IS NULL OR m.type = :type)
        AND (:isRead IS NULL OR m.isRead = :isRead)
        AND (LOWER(m.subject) LIKE LOWER(CONCAT('%', :search, '%'))
             OR LOWER(m.content) LIKE LOWER(CONCAT('%', :search, '%')))
        ORDER BY m.createdAt DESC
    """)
    fun findMessagesForRecipientWithFilters(
        @Param("recipientId") recipientId: Long,
        @Param("type") type: MessageType?,
        @Param("isRead") isRead: Boolean?,
        @Param("search") search: String?,
        pageable: Pageable
    ): Page<Message>

    @Query("SELECT COUNT(m) FROM Message m WHERE m.recipient.id = :recipientId AND m.isRead = false")
    fun countUnreadByRecipientId(@Param("recipientId") recipientId: Long): Long

    @Modifying
    @Query("UPDATE Message m SET m.isRead = true, m.readAt = :readAt WHERE m.id = :messageId")
    fun markAsRead(@Param("messageId") messageId: Long, @Param("readAt") readAt: LocalDateTime)

    @Modifying
    @Query("""
        UPDATE Message m SET m.isRead = true, m.readAt = :readAt
        WHERE m.recipient.id = :recipientId AND m.isRead = false
    """)
    fun markAllAsReadForRecipient(@Param("recipientId") recipientId: Long, @Param("readAt") readAt: LocalDateTime)

    fun findByRelatedDocumentId(documentId: Long): List<Message>

    fun findByRelatedAuditId(auditId: Long): List<Message>

    @Query("""
        SELECT m FROM Message m
        WHERE (m.sender.id = :userId OR m.recipient.id = :userId)
        AND (:otherUserId IS NULL OR (m.sender.id = :otherUserId OR m.recipient.id = :otherUserId))
        ORDER BY m.createdAt DESC
    """)
    fun findConversation(
        @Param("userId") userId: Long,
        @Param("otherUserId") otherUserId: Long?,
        pageable: Pageable
    ): Page<Message>
}
EOF

cat > $REPO_DIR/AIAnalysisRepository.kt << 'EOF'
package com.zimche.audit.repository

import com.zimche.audit.entity.AIAnalysis
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

@Repository
interface AIAnalysisRepository : JpaRepository<AIAnalysis, Long> {

    fun findByDocumentId(documentId: Long): List<AIAnalysis>

    fun findByAnalysisType(analysisType: String): List<AIAnalysis>

    fun findByDocumentIdAndAnalysisType(documentId: Long, analysisType: String): List<AIAnalysis>

    fun findByRequestedById(requestedById: Long): List<AIAnalysis>

    fun findByCreatedAtBetween(startDate: LocalDateTime, endDate: LocalDateTime): List<AIAnalysis>

    @Query("""
        SELECT a FROM AIAnalysis a
        WHERE (:documentId IS NULL OR a.document.id = :documentId)
        AND (:analysisType IS NULL OR a.analysisType = :analysisType)
        AND (:requestedById IS NULL OR a.requestedBy.id = :requestedById)
        ORDER BY a.createdAt DESC
    """)
    fun findAnalysesWithFilters(
        @Param("documentId") documentId: Long?,
        @Param("analysisType") analysisType: String?,
        @Param("requestedById") requestedById: Long?,
        pageable: Pageable
    ): Page<AIAnalysis>

    @Query("SELECT COUNT(a) FROM AIAnalysis a WHERE a.analysisType = :analysisType")
    fun countByAnalysisType(@Param("analysisType") analysisType: String): Long

    @Query("SELECT SUM(a.tokensUsed) FROM AIAnalysis a WHERE a.tokensUsed IS NOT NULL")
    fun getTotalTokensUsed(): Long?

    @Query("""
        SELECT AVG(a.processingTimeMs) FROM AIAnalysis a
        WHERE a.processingTimeMs IS NOT NULL
        AND a.analysisType = :analysisType
    """)
    fun getAverageProcessingTimeByType(@Param("analysisType") analysisType: String): Double?

    @Query("""
        SELECT a FROM AIAnalysis a
        WHERE a.document.id = :documentId
        AND a.analysisType = :analysisType
        ORDER BY a.createdAt DESC
        LIMIT 1
    """)
    fun findLatestAnalysisForDocument(
        @Param("documentId") documentId: Long,
        @Param("analysisType") analysisType: String
    ): AIAnalysis?
}
EOF

echo "✅ Repository interfaces generated successfully!"
echo "Generated files:"
echo "  - UserRepository"
echo "  - UniversityRepository"
echo "  - DocumentRepository"
echo "  - AuditRepository"
echo "  - MessageRepository"
echo "  - AIAnalysisRepository"