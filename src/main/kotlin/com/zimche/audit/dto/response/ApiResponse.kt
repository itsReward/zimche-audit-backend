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
