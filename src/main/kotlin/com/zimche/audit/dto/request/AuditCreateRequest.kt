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
