package com.zimche.audit.dto.response

import com.zimche.audit.entity.University
import java.time.LocalDateTime

data class UniversityResponse(
    val id: Long,
    val name: String,
    val code: String,
    val address: String,
    val contactEmail: String,
    val contactPhone: String?,
    val website: String?,
    val establishedYear: Int?,
    val isActive: Boolean,
    val userCount: Int,
    val documentCount: Int,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
) {
    companion object {
        fun from(university: University): UniversityResponse {
            return UniversityResponse(
                id = university.id,
                name = university.name,
                code = university.code,
                address = university.address,
                contactEmail = university.contactEmail,
                contactPhone = university.contactPhone,
                website = university.website,
                establishedYear = university.establishedYear,
                isActive = university.isActive,
                userCount = university.users.size,
                documentCount = university.documents.size,
                createdAt = university.createdAt,
                updatedAt = university.updatedAt
            )
        }
    }
}

data class UniversitySimpleResponse(
    val id: Long,
    val name: String,
    val code: String
) {
    companion object {
        fun from(university: University): UniversitySimpleResponse {
            return UniversitySimpleResponse(
                id = university.id,
                name = university.name,
                code = university.code
            )
        }
    }
}
