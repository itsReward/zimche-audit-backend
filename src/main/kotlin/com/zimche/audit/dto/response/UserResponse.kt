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
