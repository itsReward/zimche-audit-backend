package com.zimche.audit.dto.response

data class FileUploadResponse(
    val fileName: String,
    val fileUrl: String,
    val fileSize: Long,
    val contentType: String?,
    val uploadedAt: java.time.LocalDateTime
)
