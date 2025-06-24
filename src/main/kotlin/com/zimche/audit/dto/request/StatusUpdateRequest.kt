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
