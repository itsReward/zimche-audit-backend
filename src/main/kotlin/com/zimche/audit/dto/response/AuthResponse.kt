package com.zimche.audit.dto.response

data class AuthResponse(
    val token: String,
    val type: String = "Bearer",
    val email: String,
    val role: String,
    val fullName: String,
    val universityId: Long? = null
)
