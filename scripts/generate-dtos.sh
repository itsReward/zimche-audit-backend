#!/bin/bash

# Generate DTO Classes for ZIMCHE Audit System

BASE_DIR="src/main/kotlin/com/zimche/audit"
DTO_DIR="$BASE_DIR/dto"
REQUEST_DIR="$DTO_DIR/request"
RESPONSE_DIR="$DTO_DIR/response"

echo "📝 Generating DTO classes..."

mkdir -p $REQUEST_DIR
mkdir -p $RESPONSE_DIR

# Request DTOs
cat > $REQUEST_DIR/LoginRequest.kt << 'EOF'
package com.zimche.audit.dto.request

import jakarta.validation.constraints.Email
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size

data class LoginRequest(
    @field:NotBlank(message = "Email is required")
    @field:Email(message = "Email format is invalid")
    val email: String,

    @field:NotBlank(message = "Password is required")
    @field:Size(min = 6, message = "Password must be at least 6 characters")
    val password: String
)
EOF

cat > $REQUEST_DIR/RegisterRequest.kt << 'EOF'
package com.zimche.audit.dto.request

import com.zimche.audit.enums.UserRole
import jakarta.validation.constraints.Email
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size

data class RegisterRequest(
    @field:NotBlank(message = "Email is required")
    @field:Email(message = "Email format is invalid")
    val email: String,

    @field:NotBlank(message = "Password is required")
    @field:Size(min = 6, message = "Password must be at least 6 characters")
    val password: String,

    @field:NotBlank(message = "First name is required")
    @field:Size(max = 50, message = "First name cannot exceed 50 characters")
    val firstName: String,

    @field:NotBlank(message = "Last name is required")
    @field:Size(max = 50, message = "Last name cannot exceed 50 characters")
    val lastName: String,

    val role: UserRole? = null,

    @field:Size(max = 20, message = "Phone number cannot exceed 20 characters")
    val phoneNumber: String? = null,

    val universityId: Long? = null
)
EOF

cat > $REQUEST_DIR/UniversityCreateRequest.kt << 'EOF'
package com.zimche.audit.dto.request

import jakarta.validation.constraints.Email
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Pattern
import jakarta.validation.constraints.Size

data class UniversityCreateRequest(
    @field:NotBlank(message = "University name is required")
    @field:Size(max = 100, message = "University name cannot exceed 100 characters")
    val name: String,

    @field:NotBlank(message = "University code is required")
    @field:Size(max = 10, message = "University code cannot exceed 10 characters")
    @field:Pattern(regexp = "^[A-Z0-9]+$", message = "University code must contain only uppercase letters and numbers")
    val code: String,

    @field:NotBlank(message = "Address is required")
    @field:Size(max = 255, message = "Address cannot exceed 255 characters")
    val address: String,

    @field:NotBlank(message = "Contact email is required")
    @field:Email(message = "Contact email format is invalid")
    val contactEmail: String,

    @field:Size(max = 20, message = "Contact phone cannot exceed 20 characters")
    val contactPhone: String? = null,

    @field:Size(max = 100, message = "Website cannot exceed 100 characters")
    val website: String? = null,

    val establishedYear: Int? = null
)
EOF

cat > $REQUEST_DIR/DocumentUploadRequest.kt << 'EOF'
package com.zimche.audit.dto.request

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Size

data class DocumentUploadRequest(
    @field:NotBlank(message = "Document title is required")
    @field:Size(max = 100, message = "Document title cannot exceed 100 characters")
    val title: String,

    @field:Size(max = 500, message = "Description cannot exceed 500 characters")
    val description: String? = null,

    @field:NotNull(message = "University ID is required")
    val universityId: Long
)
EOF

cat > $REQUEST_DIR/AuditCreateRequest.kt << 'EOF'
package com.zimche.audit.dto.request

import com.zimche.audit.enums.AuditStatus
import jakarta.validation.constraints.Future
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Size
import java.time.LocalDateTime

data class AuditCreateRequest(
    @field:NotBlank(message = "Audit title is required")
    @field:Size(max = 100, message = "Audit title cannot exceed 100 characters")
    val title: String,

    @field:Size(max = 1000, message = "Description cannot exceed 1000 characters")
    val description: String? = null,

    @field:NotNull(message = "Scheduled date is required")
    @field:Future(message = "Scheduled date must be in the future")
    val scheduledDate: LocalDateTime,

    @field:NotNull(message = "University ID is required")
    val universityId: Long,

    val assignedToId: Long? = null,

    val status: AuditStatus = AuditStatus.SCHEDULED,

    val auditSteps: List<AuditStepRequest> = emptyList()
)

data class AuditStepRequest(
    @field:NotBlank(message = "Step title is required")
    @field:Size(max = 100, message = "Step title cannot exceed 100 characters")
    val title: String,

    @field:Size(max = 500, message = "Step description cannot exceed 500 characters")
    val description: String? = null,

    @field:NotNull(message = "Step order is required")
    val stepOrder: Int,

    val assignedToId: Long? = null
)
EOF

cat > $REQUEST_DIR/MessageRequest.kt << 'EOF'
package com.zimche.audit.dto.request

import com.zimche.audit.enums.MessageType
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Size

data class MessageRequest(
    @field:NotBlank(message = "Subject is required")
    @field:Size(max = 100, message = "Subject cannot exceed 100 characters")
    val subject: String,

    @field:NotBlank(message = "Content is required")
    @field:Size(max = 2000, message = "Content cannot exceed 2000 characters")
    val content: String,

    @field:NotNull(message = "Recipient ID is required")
    val recipientId: Long,

    val type: MessageType? = MessageType.CHAT,

    val relatedDocumentId: Long? = null,

    val relatedAuditId: Long? = null
)
EOF

cat > $REQUEST_DIR/StatusUpdateRequest.kt << 'EOF'
package com.zimche.audit.dto.request

import com.zimche.audit.enums.DocumentStatus
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Size

data class StatusUpdateRequest(
    @field:NotNull(message = "Status is required")
    val status: DocumentStatus,

    @field:Size(max = 1000, message = "Comments cannot exceed 1000 characters")
    val comments: String? = null
)
EOF

cat > $REQUEST_DIR/PasswordChangeRequest.kt << 'EOF'
package com.zimche.audit.dto.request

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size

data class PasswordChangeRequest(
    @field:NotBlank(message = "Current password is required")
    val currentPassword: String,

    @field:NotBlank(message = "New password is required")
    @field:Size(min = 6, message = "New password must be at least 6 characters")
    val newPassword: String
)
EOF

# Response DTOs
cat > $RESPONSE_DIR/ApiResponse.kt << 'EOF'
package com.zimche.audit.dto.response

import com.fasterxml.jackson.annotation.JsonInclude
import java.time.LocalDateTime

@JsonInclude(JsonInclude.Include.NON_NULL)
data class ApiResponse<T>(
    val success: Boolean,
    val message: String,
    val data: T? = null,
    val timestamp: LocalDateTime = LocalDateTime.now()
) {
    companion object {
        fun <T> success(data: T? = null, message: String = "Operation successful"): ApiResponse<T> {
            return AuditResponse(
                id = audit.id,
                title = audit.title,
                description = audit.description,
                status = audit.status,
                scheduledDate = audit.scheduledDate,
                startDate = audit.startDate,
                endDate = audit.endDate,
                university = UniversitySimpleResponse.from(audit.university),
                assignedTo = audit.assignedTo?.let { UserSimpleResponse.from(it) },
                createdBy = UserSimpleResponse.from(audit.createdBy),
                auditSteps = audit.auditSteps.map { AuditStepResponse.from(it) },
                finalReport = audit.finalReport,
                complianceScore = audit.complianceScore,
                progressPercentage = progressPercentage,
                createdAt = audit.createdAt,
                updatedAt = audit.updatedAt
            )
        }
    }
}

data class AuditStepResponse(
    val id: Long,
    val title: String,
    val description: String?,
    val stepOrder: Int,
    val isCompleted: Boolean,
    val completedAt: LocalDateTime?,
    val comments: String?,
    val assignedTo: UserSimpleResponse?,
    val completedBy: UserSimpleResponse?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
) {
    companion object {
        fun from(auditStep: AuditStep): AuditStepResponse {
            return AuditStepResponse(
                id = auditStep.id,
                title = auditStep.title,
                description = auditStep.description,
                stepOrder = auditStep.stepOrder,
                isCompleted = auditStep.isCompleted,
                completedAt = auditStep.completedAt,
                comments = auditStep.comments,
                assignedTo = auditStep.assignedTo?.let { UserSimpleResponse.from(it) },
                completedBy = auditStep.completedBy?.let { UserSimpleResponse.from(it) },
                createdAt = auditStep.createdAt,
                updatedAt = auditStep.updatedAt
            )
        }
    }
}
EOF

cat > $RESPONSE_DIR/MessageResponse.kt << 'EOF'
package com.zimche.audit.dto.response

import com.zimche.audit.entity.Message
import com.zimche.audit.enums.MessageType
import java.time.LocalDateTime

data class MessageResponse(
    val id: Long,
    val subject: String,
    val content: String,
    val type: MessageType,
    val isRead: Boolean,
    val readAt: LocalDateTime?,
    val sender: UserSimpleResponse,
    val recipient: UserSimpleResponse,
    val relatedDocument: DocumentSimpleResponse?,
    val relatedAudit: AuditSimpleResponse?,
    val createdAt: LocalDateTime
) {
    companion object {
        fun from(message: Message): MessageResponse {
            return MessageResponse(
                id = message.id,
                subject = message.subject,
                content = message.content,
                type = message.type,
                isRead = message.isRead,
                readAt = message.readAt,
                sender = UserSimpleResponse.from(message.sender),
                recipient = UserSimpleResponse.from(message.recipient),
                relatedDocument = message.relatedDocument?.let { DocumentSimpleResponse.from(it) },
                relatedAudit = message.relatedAudit?.let { AuditSimpleResponse.from(it) },
                createdAt = message.createdAt
            )
        }
    }
}

data class DocumentSimpleResponse(
    val id: Long,
    val title: String,
    val fileName: String
) {
    companion object {
        fun from(document: com.zimche.audit.entity.Document): DocumentSimpleResponse {
            return DocumentSimpleResponse(
                id = document.id,
                title = document.title,
                fileName = document.fileName
            )
        }
    }
}

data class AuditSimpleResponse(
    val id: Long,
    val title: String,
    val status: com.zimche.audit.enums.AuditStatus
) {
    companion object {
        fun from(audit: com.zimche.audit.entity.Audit): AuditSimpleResponse {
            return AuditSimpleResponse(
                id = audit.id,
                title = audit.title,
                status = audit.status
            )
        }
    }
}
EOF

cat > $RESPONSE_DIR/AIAnalysisResponse.kt << 'EOF'
package com.zimche.audit.dto.response

import com.zimche.audit.entity.AIAnalysis
import java.time.LocalDateTime

data class AIAnalysisResponse(
    val id: Long,
    val analysisType: String,
    val result: String,
    val confidenceScore: Double?,
    val tokensUsed: Int?,
    val processingTimeMs: Long?,
    val modelVersion: String?,
    val document: DocumentSimpleResponse,
    val requestedBy: UserSimpleResponse,
    val createdAt: LocalDateTime
) {
    companion object {
        fun from(analysis: AIAnalysis): AIAnalysisResponse {
            return AIAnalysisResponse(
                id = analysis.id,
                analysisType = analysis.analysisType,
                result = analysis.result,
                confidenceScore = analysis.confidenceScore,
                tokensUsed = analysis.tokensUsed,
                processingTimeMs = analysis.processingTimeMs,
                modelVersion = analysis.modelVersion,
                document = DocumentSimpleResponse.from(analysis.document),
                requestedBy = UserSimpleResponse.from(analysis.requestedBy),
                createdAt = analysis.createdAt
            )
        }
    }
}
EOF

cat > $RESPONSE_DIR/DashboardStatsResponse.kt << 'EOF'
package com.zimche.audit.dto.response

data class DashboardStatsResponse(
    val totalUsers: Long,
    val activeUsers: Long,
    val totalUniversities: Long,
    val activeUniversities: Long,
    val totalDocuments: Long,
    val pendingDocuments: Long,
    val totalAudits: Long,
    val activeAudits: Long,
    val unreadMessages: Long,
    val recentActivity: List<ActivityResponse>
)

data class ActivityResponse(
    val id: Long,
    val type: String, // "DOCUMENT_UPLOADED", "AUDIT_CREATED", "MESSAGE_SENT", etc.
    val description: String,
    val entityId: Long?,
    val entityType: String?, // "DOCUMENT", "AUDIT", "MESSAGE", etc.
    val userId: Long,
    val userName: String,
    val timestamp: java.time.LocalDateTime
)
EOF

cat > $RESPONSE_DIR/PaginatedResponse.kt << 'EOF'
package com.zimche.audit.dto.response

data class PaginatedResponse<T>(
    val content: List<T>,
    val page: Int,
    val size: Int,
    val totalElements: Long,
    val totalPages: Int,
    val isFirst: Boolean,
    val isLast: Boolean,
    val hasNext: Boolean,
    val hasPrevious: Boolean
) {
    companion object {
        fun <T> from(
            content: List<T>,
            page: Int,
            size: Int,
            totalElements: Long
        ): PaginatedResponse<T> {
            val totalPages = if (size > 0) ((totalElements + size - 1) / size).toInt() else 0

            return PaginatedResponse(
                content = content,
                page = page,
                size = size,
                totalElements = totalElements,
                totalPages = totalPages,
                isFirst = page == 0,
                isLast = page >= totalPages - 1,
                hasNext = page < totalPages - 1,
                hasPrevious = page > 0
            )
        }
    }
}
EOF

cat > $RESPONSE_DIR/FileUploadResponse.kt << 'EOF'
package com.zimche.audit.dto.response

data class FileUploadResponse(
    val fileName: String,
    val fileUrl: String,
    val fileSize: Long,
    val contentType: String?,
    val uploadedAt: java.time.LocalDateTime
)
EOF

cat > $RESPONSE_DIR/ValidationErrorResponse.kt << 'EOF'
package com.zimche.audit.dto.response

import java.time.LocalDateTime

data class ValidationErrorResponse(
    val success: Boolean = false,
    val message: String,
    val errors: Map<String, String>,
    val timestamp: LocalDateTime = LocalDateTime.now()
)
EOF

echo "✅ DTO classes generated successfully!"
echo "Generated Request DTOs:"
echo "  - LoginRequest"
echo "  - RegisterRequest"
echo "  - UniversityCreateRequest"
echo "  - DocumentUploadRequest"
echo "  - AuditCreateRequest"
echo "  - MessageRequest"
echo "  - StatusUpdateRequest"
echo "  - PasswordChangeRequest"
echo ""
echo "Generated Response DTOs:"
echo "  - ApiResponse"
echo "  - AuthResponse"
echo "  - UserResponse"
echo "  - UniversityResponse"
echo "  - DocumentResponse"
echo "  - AuditResponse"
echo "  - MessageResponse"
echo "  - AIAnalysisResponse"
echo "  - DashboardStatsResponse"
echo "  - PaginatedResponse"
echo "  - FileUploadResponse"
echo "  - ValidationErrorResponse" ApiResponse(success = true, message = message, data = data)
        }

        fun <T> error(message: String): ApiResponse<T> {
            return ApiResponse(success = false, message = message)
        }
    }
}
EOF

cat > $RESPONSE_DIR/AuthResponse.kt << 'EOF'
package com.zimche.audit.dto.response

data class AuthResponse(
    val token: String,
    val type: String = "Bearer",
    val email: String,
    val role: String,
    val fullName: String,
    val universityId: Long? = null
)
EOF

cat > $RESPONSE_DIR/UserResponse.kt << 'EOF'
package com.zimche.audit.dto.response

import com.zimche.audit.entity.User
import com.zimche.audit.enums.UserRole
import java.time.LocalDateTime

data class UserResponse(
    val id: Long,
    val email: String,
    val firstName: String,
    val lastName: String,
    val fullName: String,
    val role: UserRole,
    val phoneNumber: String?,
    val isActive: Boolean,
    val isEmailVerified: Boolean,
    val university: UniversitySimpleResponse?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
) {
    companion object {
        fun from(user: User): UserResponse {
            return UserResponse(
                id = user.id,
                email = user.email,
                firstName = user.firstName,
                lastName = user.lastName,
                fullName = user.fullName,
                role = user.role,
                phoneNumber = user.phoneNumber,
                isActive = user.isActive,
                isEmailVerified = user.isEmailVerified,
                university = user.university?.let { UniversitySimpleResponse.from(it) },
                createdAt = user.createdAt,
                updatedAt = user.updatedAt
            )
        }
    }
}

data class UserSimpleResponse(
    val id: Long,
    val email: String,
    val fullName: String,
    val role: UserRole
) {
    companion object {
        fun from(user: User): UserSimpleResponse {
            return UserSimpleResponse(
                id = user.id,
                email = user.email,
                fullName = user.fullName,
                role = user.role
            )
        }
    }
}
EOF

cat > $RESPONSE_DIR/UniversityResponse.kt << 'EOF'
package com.zimche.audit.dto.response

import com.zimche.audit.entity.University
import java.time.LocalDateTime

data class UniversityResponse(
    val id: Long,
    val name: String,
    val code: String,
    val address: String,
    val contactEmail: String,
    val contactPhone: String?,
    val website: String?,
    val establishedYear: Int?,
    val isActive: Boolean,
    val userCount: Int,
    val documentCount: Int,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
) {
    companion object {
        fun from(university: University): UniversityResponse {
            return UniversityResponse(
                id = university.id,
                name = university.name,
                code = university.code,
                address = university.address,
                contactEmail = university.contactEmail,
                contactPhone = university.contactPhone,
                website = university.website,
                establishedYear = university.establishedYear,
                isActive = university.isActive,
                userCount = university.users.size,
                documentCount = university.documents.size,
                createdAt = university.createdAt,
                updatedAt = university.updatedAt
            )
        }
    }
}

data class UniversitySimpleResponse(
    val id: Long,
    val name: String,
    val code: String
) {
    companion object {
        fun from(university: University): UniversitySimpleResponse {
            return UniversitySimpleResponse(
                id = university.id,
                name = university.name,
                code = university.code
            )
        }
    }
}
EOF

cat > $RESPONSE_DIR/DocumentResponse.kt << 'EOF'
package com.zimche.audit.dto.response

import com.zimche.audit.entity.Document
import com.zimche.audit.enums.DocumentStatus
import java.time.LocalDateTime

data class DocumentResponse(
    val id: Long,
    val title: String,
    val fileName: String,
    val fileUrl: String,
    val fileSize: Long,
    val contentType: String?,
    val description: String?,
    val status: DocumentStatus,
    val university: UniversitySimpleResponse,
    val uploadedBy: UserSimpleResponse,
    val reviewedBy: UserSimpleResponse?,
    val reviewedAt: LocalDateTime?,
    val reviewComments: String?,
    val analysisCount: Int,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
) {
    companion object {
        fun from(document: Document): DocumentResponse {
            return DocumentResponse(
                id = document.id,
                title = document.title,
                fileName = document.fileName,
                fileUrl = document.fileUrl,
                fileSize = document.fileSize,
                contentType = document.contentType,
                description = document.description,
                status = document.status,
                university = UniversitySimpleResponse.from(document.university),
                uploadedBy = UserSimpleResponse.from(document.uploadedBy),
                reviewedBy = document.reviewedBy?.let { UserSimpleResponse.from(it) },
                reviewedAt = document.reviewedAt,
                reviewComments = document.reviewComments,
                analysisCount = document.aiAnalyses.size,
                createdAt = document.createdAt,
                updatedAt = document.updatedAt
            )
        }
    }
}
EOF

cat > $RESPONSE_DIR/AuditResponse.kt << 'EOF'
package com.zimche.audit.dto.response

import com.zimche.audit.entity.Audit
import com.zimche.audit.entity.AuditStep
import com.zimche.audit.enums.AuditStatus
import java.time.LocalDateTime

data class AuditResponse(
    val id: Long,
    val title: String,
    val description: String?,
    val status: AuditStatus,
    val scheduledDate: LocalDateTime,
    val startDate: LocalDateTime?,
    val endDate: LocalDateTime?,
    val university: UniversitySimpleResponse,
    val assignedTo: UserSimpleResponse?,
    val createdBy: UserSimpleResponse,
    val auditSteps: List<AuditStepResponse>,
    val finalReport: String?,
    val complianceScore: Double?,
    val progressPercentage: Double,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
) {
    companion object {
        fun from(audit: Audit): AuditResponse {
            val completedSteps = audit.auditSteps.count { it.isCompleted }
            val totalSteps = audit.auditSteps.size
            val progressPercentage = if (totalSteps > 0) {
                (completedSteps.toDouble() / totalSteps) * 100
            } else 0.0

            return