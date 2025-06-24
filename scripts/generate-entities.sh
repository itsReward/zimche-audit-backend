#!/bin/bash

# Generate Entity Classes for ZIMCHE Audit System

BASE_DIR="src/main/kotlin/com/zimche/audit"
ENTITY_DIR="$BASE_DIR/entity"
ENUM_DIR="$BASE_DIR/enums"

echo "🏗️  Generating Entity classes..."

# Create Enums first
mkdir -p $ENUM_DIR

cat > $ENUM_DIR/UserRole.kt << 'EOF'
package com.zimche.audit.enums

enum class UserRole(val displayName: String) {
    ADMIN("Administrator"),
    UNIVERSITY_STAFF("University Staff"),
    PEER_REVIEWER("Peer Reviewer"),
    SUPER_USER("Super User")
}
EOF

cat > $ENUM_DIR/DocumentStatus.kt << 'EOF'
package com.zimche.audit.enums

enum class DocumentStatus(val displayName: String) {
    PENDING("Pending Review"),
    UNDER_REVIEW("Under Review"),
    APPROVED("Approved"),
    REJECTED("Rejected"),
    REQUIRES_REVISION("Requires Revision")
}
EOF

cat > $ENUM_DIR/AuditStatus.kt << 'EOF'
package com.zimche.audit.enums

enum class AuditStatus(val displayName: String) {
    SCHEDULED("Scheduled"),
    IN_PROGRESS("In Progress"),
    COMPLETED("Completed"),
    CANCELLED("Cancelled"),
    ON_HOLD("On Hold")
}
EOF

cat > $ENUM_DIR/MessageType.kt << 'EOF'
package com.zimche.audit.enums

enum class MessageType(val displayName: String) {
    NOTIFICATION("Notification"),
    ALERT("Alert"),
    REMINDER("Reminder"),
    CHAT("Chat Message"),
    SYSTEM("System Message")
}
EOF

# Create Entity classes
mkdir -p $ENTITY_DIR

cat > $ENTITY_DIR/User.kt << 'EOF'
package com.zimche.audit.entity

import com.zimche.audit.enums.UserRole
import jakarta.persistence.*
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.jpa.domain.support.AuditingEntityListener
import java.time.LocalDateTime

@Entity
@Table(name = "users")
@EntityListeners(AuditingEntityListener::class)
data class User(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @Column(unique = true, nullable = false)
    val email: String,

    @Column(nullable = false)
    val password: String,

    @Column(name = "first_name", nullable = false)
    val firstName: String,

    @Column(name = "last_name", nullable = false)
    val lastName: String,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val role: UserRole,

    @Column(name = "phone_number")
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

cat > $ENTITY_DIR/University.kt << 'EOF'
package com.zimche.audit.entity

import jakarta.persistence.*
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.jpa.domain.support.AuditingEntityListener
import java.time.LocalDateTime

@Entity
@Table(name = "universities")
@EntityListeners(AuditingEntityListener::class)
data class University(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @Column(nullable = false)
    val name: String,

    @Column(unique = true, nullable = false)
    val code: String,

    @Column(nullable = false)
    val address: String,

    @Column(name = "contact_email", nullable = false)
    val contactEmail: String,

    @Column(name = "contact_phone")
    val contactPhone: String? = null,

    @Column
    val website: String? = null,

    @Column(name = "established_year")
    val establishedYear: Int? = null,

    @Column(name = "is_active")
    val isActive: Boolean = true,

    @OneToMany(mappedBy = "university", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val users: MutableList<User> = mutableListOf(),

    @OneToMany(mappedBy = "university", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val documents: MutableList<Document> = mutableListOf(),

    @OneToMany(mappedBy = "university", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val audits: MutableList<Audit> = mutableListOf(),

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @LastModifiedDate
    @Column(name = "updated_at")
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as University
        return id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String = "University(id=$id, name='$name', code='$code')"
}
EOF

cat > $ENTITY_DIR/Document.kt << 'EOF'
package com.zimche.audit.entity

import com.zimche.audit.enums.DocumentStatus
import jakarta.persistence.*
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.jpa.domain.support.AuditingEntityListener
import java.time.LocalDateTime

@Entity
@Table(name = "documents")
@EntityListeners(AuditingEntityListener::class)
data class Document(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @Column(nullable = false)
    val title: String,

    @Column(name = "file_name", nullable = false)
    val fileName: String,

    @Column(name = "file_url", nullable = false)
    val fileUrl: String,

    @Column(name = "file_size", nullable = false)
    val fileSize: Long,

    @Column(name = "content_type")
    val contentType: String? = null,

    @Column(columnDefinition = "TEXT")
    val description: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val status: DocumentStatus = DocumentStatus.PENDING,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "university_id", nullable = false)
    val university: University,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "uploaded_by", nullable = false)
    val uploadedBy: User,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reviewed_by")
    val reviewedBy: User? = null,

    @Column(name = "reviewed_at")
    val reviewedAt: LocalDateTime? = null,

    @Column(name = "review_comments", columnDefinition = "TEXT")
    val reviewComments: String? = null,

    @OneToMany(mappedBy = "document", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val aiAnalyses: MutableList<AIAnalysis> = mutableListOf(),

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @LastModifiedDate
    @Column(name = "updated_at")
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as Document
        return id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String = "Document(id=$id, title='$title', fileName='$fileName')"
}
EOF

cat > $ENTITY_DIR/Audit.kt << 'EOF'
package com.zimche.audit.entity

import com.zimche.audit.enums.AuditStatus
import jakarta.persistence.*
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.jpa.domain.support.AuditingEntityListener
import java.time.LocalDateTime

@Entity
@Table(name = "audits")
@EntityListeners(AuditingEntityListener::class)
data class Audit(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @Column(nullable = false)
    val title: String,

    @Column(columnDefinition = "TEXT")
    val description: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val status: AuditStatus = AuditStatus.SCHEDULED,

    @Column(name = "scheduled_date", nullable = false)
    val scheduledDate: LocalDateTime,

    @Column(name = "start_date")
    val startDate: LocalDateTime? = null,

    @Column(name = "end_date")
    val endDate: LocalDateTime? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "university_id", nullable = false)
    val university: University,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_to")
    val assignedTo: User? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by", nullable = false)
    val createdBy: User,

    @OneToMany(mappedBy = "audit", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val auditSteps: MutableList<AuditStep> = mutableListOf(),

    @Column(name = "final_report", columnDefinition = "TEXT")
    val finalReport: String? = null,

    @Column(name = "compliance_score")
    val complianceScore: Double? = null,

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @LastModifiedDate
    @Column(name = "updated_at")
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as Audit
        return id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String = "Audit(id=$id, title='$title', status=$status)"
}
EOF

cat > $ENTITY_DIR/AuditStep.kt << 'EOF'
package com.zimche.audit.entity

import jakarta.persistence.*
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.jpa.domain.support.AuditingEntityListener
import java.time.LocalDateTime

@Entity
@Table(name = "audit_steps")
@EntityListeners(AuditingEntityListener::class)
data class AuditStep(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @Column(nullable = false)
    val title: String,

    @Column(columnDefinition = "TEXT")
    val description: String? = null,

    @Column(name = "step_order", nullable = false)
    val stepOrder: Int,

    @Column(name = "is_completed")
    val isCompleted: Boolean = false,

    @Column(name = "completed_at")
    val completedAt: LocalDateTime? = null,

    @Column(name = "comments", columnDefinition = "TEXT")
    val comments: String? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "audit_id", nullable = false)
    val audit: Audit,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_to")
    val assignedTo: User? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "completed_by")
    val completedBy: User? = null,

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @LastModifiedDate
    @Column(name = "updated_at")
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as AuditStep
        return id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String = "AuditStep(id=$id, title='$title', stepOrder=$stepOrder)"
}
EOF

cat > $ENTITY_DIR/Message.kt << 'EOF'
package com.zimche.audit.entity

import com.zimche.audit.enums.MessageType
import jakarta.persistence.*
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.jpa.domain.support.AuditingEntityListener
import java.time.LocalDateTime

@Entity
@Table(name = "messages")
@EntityListeners(AuditingEntityListener::class)
data class Message(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @Column(nullable = false)
    val subject: String,

    @Column(nullable = false, columnDefinition = "TEXT")
    val content: String,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val type: MessageType,

    @Column(name = "is_read")
    val isRead: Boolean = false,

    @Column(name = "read_at")
    val readAt: LocalDateTime? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sender_id", nullable = false)
    val sender: User,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipient_id", nullable = false)
    val recipient: User,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "related_document_id")
    val relatedDocument: Document? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "related_audit_id")
    val relatedAudit: Audit? = null,

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as Message
        return id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String = "Message(id=$id, subject='$subject', type=$type)"
}
EOF

cat > $ENTITY_DIR/AIAnalysis.kt << 'EOF'
package com.zimche.audit.entity

import jakarta.persistence.*
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.jpa.domain.support.AuditingEntityListener
import java.time.LocalDateTime

@Entity
@Table(name = "ai_analyses")
@EntityListeners(AuditingEntityListener::class)
data class AIAnalysis(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @Column(name = "analysis_type", nullable = false)
    val analysisType: String, // e.g., "SUMMARY", "COMPLIANCE_CHECK", "BIAS_DETECTION"

    @Column(nullable = false, columnDefinition = "TEXT")
    val prompt: String,

    @Column(nullable = false, columnDefinition = "TEXT")
    val result: String,

    @Column(name = "confidence_score")
    val confidenceScore: Double? = null,

    @Column(name = "tokens_used")
    val tokensUsed: Int? = null,

    @Column(name = "processing_time_ms")
    val processingTimeMs: Long? = null,

    @Column(name = "model_version")
    val modelVersion: String? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "document_id", nullable = false)
    val document: Document,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "requested_by", nullable = false)
    val requestedBy: User,

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as AIAnalysis
        return id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String = "AIAnalysis(id=$id, analysisType='$analysisType', documentId=${document.id})"
}
EOF

echo "✅ Entity classes generated successfully!"
echo "Generated files:"
echo "  - Enums: UserRole, DocumentStatus, AuditStatus, MessageType"
echo "  - Entities: User, University, Document, Audit, AuditStep, Message, AIAnalysis"