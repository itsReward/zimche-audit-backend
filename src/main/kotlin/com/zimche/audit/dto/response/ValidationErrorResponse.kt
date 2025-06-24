package com.zimche.audit.dto.response

import java.time.LocalDateTime

data class ValidationErrorResponse(
    val success: Boolean = false,
    val message: String,
    val errors: Map<String, String>,
    val timestamp: LocalDateTime = LocalDateTime.now()
)
