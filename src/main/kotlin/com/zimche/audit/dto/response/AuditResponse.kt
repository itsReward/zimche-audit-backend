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
