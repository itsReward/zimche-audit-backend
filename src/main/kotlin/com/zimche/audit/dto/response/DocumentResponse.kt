package com.zimche.audit.dto.response

import com.zimche.audit.entity.Document
import com.zimche.audit.enums.DocumentStatus
import java.time.LocalDateTime

data class DocumentResponse(
    val id: Long,
    val title: String,
    val fileName: String,
    val fileUrl: String,
    val fileSize: Long,
    val contentType: String?,
    val description: String?,
    val status: DocumentStatus,
    val university: UniversitySimpleResponse,
    val uploadedBy: UserSimpleResponse,
    val reviewedBy: UserSimpleResponse?,
    val reviewedAt: LocalDateTime?,
    val reviewComments: String?,
    val analysisCount: Int,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
) {
    companion object {
        fun from(document: Document): DocumentResponse {
            return DocumentResponse(
                id = document.id,
                title = document.title,
                fileName = document.fileName,
                fileUrl = document.fileUrl,
                fileSize = document.fileSize,
                contentType = document.contentType,
                description = document.description,
                status = document.status,
                university = UniversitySimpleResponse.from(document.university),
                uploadedBy = UserSimpleResponse.from(document.uploadedBy),
                reviewedBy = document.reviewedBy?.let { UserSimpleResponse.from(it) },
                reviewedAt = document.reviewedAt,
                reviewComments = document.reviewComments,
                analysisCount = document.aiAnalyses.size,
                createdAt = document.createdAt,
                updatedAt = document.updatedAt
            )
        }
    }
}
