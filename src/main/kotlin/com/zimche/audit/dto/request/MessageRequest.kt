package com.zimche.audit.dto.request

import com.zimche.audit.enums.MessageType
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Size

data class MessageRequest(
    @field:NotBlank(message = "Subject is required")
    @field:Size(max = 100, message = "Subject cannot exceed 100 characters")
    val subject: String,

    @field:NotBlank(message = "Content is required")
    @field:Size(max = 2000, message = "Content cannot exceed 2000 characters")
    val content: String,

    @field:NotNull(message = "Recipient ID is required")
    val recipientId: Long,

    val type: MessageType? = MessageType.CHAT,

    val relatedDocumentId: Long? = null,

    val relatedAuditId: Long? = null
)
