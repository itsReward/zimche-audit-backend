package com.zimche.audit.service

import com.zimche.audit.dto.request.MessageRequest
import com.zimche.audit.dto.response.MessageResponse
import com.zimche.audit.entity.Document
import com.zimche.audit.entity.Message
import com.zimche.audit.enums.MessageType
import com.zimche.audit.enums.UserRole
import com.zimche.audit.exception.ResourceNotFoundException
import com.zimche.audit.repository.MessageRepository
import com.zimche.audit.repository.DocumentRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@Service
@Transactional
class MessagingService(
    private val messageRepository: MessageRepository,
    private val userService: UserService,
    private val documentRepository: DocumentRepository,
    private val emailService: EmailService
) {

    fun sendMessage(request: MessageRequest, senderEmail: String): MessageResponse {
        val sender = userService.findByEmail(senderEmail)
        val recipient = userService.findById(request.recipientId)

        val relatedDocument = request.relatedDocumentId?.let {
            documentRepository.findById(it).orElse(null)
        }

        val message = Message(
            subject = request.subject,
            content = request.content,
            type = request.type ?: MessageType.CHAT,
            sender = sender,
            recipient = recipient,
            relatedDocument = relatedDocument,
            relatedAudit = null // Will be implemented when AuditService is available
        )

        val savedMessage = messageRepository.save(message)

        // Send email notification for important messages
        if (request.type == MessageType.ALERT || request.type == MessageType.NOTIFICATION) {
            // emailService.sendMessageNotification(savedMessage) - implement if needed
        }

        return MessageResponse.from(savedMessage)
    }

    @Transactional(readOnly = true)
    fun getMessagesForUser(
        userEmail: String,
        type: MessageType?,
        isRead: Boolean?,
        search: String?,
        pageable: Pageable
    ): Page<MessageResponse> {
        val user = userService.findByEmail(userEmail)
        return messageRepository.findMessagesForRecipientWithFilters(
            user.id, type, isRead, search, pageable
        ).map { MessageResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun getConversation(
        userEmail: String,
        otherUserId: Long?,
        pageable: Pageable
    ): Page<MessageResponse> {
        val user = userService.findByEmail(userEmail)
        return messageRepository.findConversation(user.id, otherUserId, pageable)
            .map { MessageResponse.from(it) }
    }

    fun markMessageAsRead(messageId: Long, userEmail: String): MessageResponse {
        val message = messageRepository.findById(messageId)
            .orElseThrow { ResourceNotFoundException("Message not found with id: $messageId") }

        val user = userService.findByEmail(userEmail)

        if (message.recipient.id != user.id) {
            throw IllegalArgumentException("You can only mark your own messages as read")
        }

        if (!message.isRead) {
            messageRepository.markAsRead(messageId, LocalDateTime.now())
        }

        return MessageResponse.from(message.copy(isRead = true, readAt = LocalDateTime.now()))
    }

    fun markAllMessagesAsRead(userEmail: String) {
        val user = userService.findByEmail(userEmail)
        messageRepository.markAllAsReadForRecipient(user.id, LocalDateTime.now())
    }

    @Transactional(readOnly = true)
    fun getUnreadMessageCount(userEmail: String): Long {
        val user = userService.findByEmail(userEmail)
        return messageRepository.countUnreadByRecipientId(user.id)
    }

    fun notifyDocumentUploaded(document: Document) {
        // Send notification to all admins and peer reviewers
        val adminUsers = userService.getUsersByRole(UserRole.ADMIN)
        val reviewers = userService.getUsersByRole(UserRole.PEER_REVIEWER)

        val recipients = (adminUsers + reviewers).map { it.email }.distinct()

        recipients.forEach { recipientEmail ->
            try {
                val recipient = userService.findByEmail(recipientEmail)
                val message = Message(
                    subject = "New Document Uploaded: ${document.title}",
                    content = """
                        A new document has been uploaded by ${document.uploadedBy.fullName}
                        from ${document.university.name}.

                        Document: ${document.title}
                        Description: ${document.description ?: "No description provided"}

                        Please review the document at your earliest convenience.
                    """.trimIndent(),
                    type = MessageType.NOTIFICATION,
                    sender = document.uploadedBy,
                    recipient = recipient,
                    relatedDocument = document
                )

                messageRepository.save(message)
            } catch (e: Exception) {
                println("Failed to send notification to $recipientEmail: ${e.message}")
            }
        }

        // Also send email notifications
        val users = recipients.mapNotNull { email ->
            try { userService.findByEmail(email) } catch (e: Exception) { null }
        }
        emailService.sendDocumentUploadNotification(document, users)
    }

    fun notifyDocumentStatusChanged(document: Document) {
        val message = Message(
            subject = "Document Status Updated: ${document.title}",
            content = """
                The status of your document "${document.title}" has been updated to: ${document.status.displayName}

                ${if (document.reviewComments != null) "Review Comments: ${document.reviewComments}" else ""}

                Reviewed by: ${document.reviewedBy?.fullName ?: "System"}
                Review Date: ${document.reviewedAt}
            """.trimIndent(),
            type = MessageType.NOTIFICATION,
            sender = document.reviewedBy ?: document.uploadedBy,
            recipient = document.uploadedBy
        )

        messageRepository.save(message)
        emailService.sendDocumentStatusChangeNotification(document)
    }

    fun sendSystemMessage(subject: String, content: String, recipientIds: List<Long>) {
        val systemUser = userService.getUsersByRole(UserRole.ADMIN).firstOrNull()
            ?: throw IllegalStateException("No admin user found to send system messages")

        recipientIds.forEach { recipientId ->
            try {
                val recipient = userService.findById(recipientId)
                val message = Message(
                    subject = subject,
                    content = content,
                    type = MessageType.SYSTEM,
                    sender = userService.findByEmail(systemUser.email),
                    recipient = recipient
                )

                messageRepository.save(message)
            } catch (e: Exception) {
                println("Failed to send system message to user $recipientId: ${e.message}")
            }
        }
    }

    fun deleteMessage(messageId: Long, userEmail: String) {
        val message = messageRepository.findById(messageId)
            .orElseThrow { ResourceNotFoundException("Message not found with id: $messageId") }

        val user = userService.findByEmail(userEmail)

        if (message.recipient.id != user.id && message.sender.id != user.id) {
            throw IllegalArgumentException("You can only delete your own messages")
        }

        messageRepository.delete(message)
    }
}
