package com.zimche.audit.dto.response

import com.zimche.audit.entity.Message
import com.zimche.audit.enums.MessageType
import java.time.LocalDateTime

data class MessageResponse(
    val id: Long,
    val subject: String,
    val content: String,
    val type: MessageType,
    val isRead: Boolean,
    val readAt: LocalDateTime?,
    val sender: UserSimpleResponse,
    val recipient: UserSimpleResponse,
    val relatedDocument: DocumentSimpleResponse?,
    val relatedAudit: AuditSimpleResponse?,
    val createdAt: LocalDateTime
) {
    companion object {
        fun from(message: Message): MessageResponse {
            return MessageResponse(
                id = message.id,
                subject = message.subject,
                content = message.content,
                type = message.type,
                isRead = message.isRead,
                readAt = message.readAt,
                sender = UserSimpleResponse.from(message.sender),
                recipient = UserSimpleResponse.from(message.recipient),
                relatedDocument = message.relatedDocument?.let { DocumentSimpleResponse.from(it) },
                relatedAudit = message.relatedAudit?.let { AuditSimpleResponse.from(it) },
                createdAt = message.createdAt
            )
        }
    }
}

data class DocumentSimpleResponse(
    val id: Long,
    val title: String,
    val fileName: String
) {
    companion object {
        fun from(document: com.zimche.audit.entity.Document): DocumentSimpleResponse {
            return DocumentSimpleResponse(
                id = document.id,
                title = document.title,
                fileName = document.fileName
            )
        }
    }
}

data class AuditSimpleResponse(
    val id: Long,
    val title: String,
    val status: com.zimche.audit.enums.AuditStatus
) {
    companion object {
        fun from(audit: com.zimche.audit.entity.Audit): AuditSimpleResponse {
            return AuditSimpleResponse(
                id = audit.id,
                title = audit.title,
                status = audit.status
            )
        }
    }
}
