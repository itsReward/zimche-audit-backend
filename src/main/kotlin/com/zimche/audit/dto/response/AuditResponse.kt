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
