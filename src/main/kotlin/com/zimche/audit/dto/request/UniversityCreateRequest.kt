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
