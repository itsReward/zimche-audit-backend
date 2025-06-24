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
