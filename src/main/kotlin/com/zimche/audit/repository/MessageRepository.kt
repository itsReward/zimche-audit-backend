package com.zimche.audit.repository

import com.zimche.audit.entity.Message
import com.zimche.audit.enums.MessageType
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

@Repository
interface MessageRepository : JpaRepository<Message, Long> {

    fun findByRecipientId(recipientId: Long): List<Message>

    fun findByRecipientId(recipientId: Long, pageable: Pageable): Page<Message>

    fun findBySenderId(senderId: Long): List<Message>

    fun findByRecipientIdAndIsReadFalse(recipientId: Long): List<Message>

    fun findByType(type: MessageType): List<Message>

    fun findByRecipientIdAndType(recipientId: Long, type: MessageType): List<Message>

    @Query("""
        SELECT m FROM Message m
        WHERE m.recipient.id = :recipientId
        AND (:type IS NULL OR m.type = :type)
        AND (:isRead IS NULL OR m.isRead = :isRead)
        AND (LOWER(m.subject) LIKE LOWER(CONCAT('%', :search, '%'))
             OR LOWER(m.content) LIKE LOWER(CONCAT('%', :search, '%')))
        ORDER BY m.createdAt DESC
    """)
    fun findMessagesForRecipientWithFilters(
        @Param("recipientId") recipientId: Long,
        @Param("type") type: MessageType?,
        @Param("isRead") isRead: Boolean?,
        @Param("search") search: String?,
        pageable: Pageable
    ): Page<Message>

    @Query("SELECT COUNT(m) FROM Message m WHERE m.recipient.id = :recipientId AND m.isRead = false")
    fun countUnreadByRecipientId(@Param("recipientId") recipientId: Long): Long

    @Modifying
    @Query("UPDATE Message m SET m.isRead = true, m.readAt = :readAt WHERE m.id = :messageId")
    fun markAsRead(@Param("messageId") messageId: Long, @Param("readAt") readAt: LocalDateTime)

    @Modifying
    @Query("""
        UPDATE Message m SET m.isRead = true, m.readAt = :readAt
        WHERE m.recipient.id = :recipientId AND m.isRead = false
    """)
    fun markAllAsReadForRecipient(@Param("recipientId") recipientId: Long, @Param("readAt") readAt: LocalDateTime)

    fun findByRelatedDocumentId(documentId: Long): List<Message>

    fun findByRelatedAuditId(auditId: Long): List<Message>

    @Query("""
        SELECT m FROM Message m
        WHERE (m.sender.id = :userId OR m.recipient.id = :userId)
        AND (:otherUserId IS NULL OR (m.sender.id = :otherUserId OR m.recipient.id = :otherUserId))
        ORDER BY m.createdAt DESC
    """)
    fun findConversation(
        @Param("userId") userId: Long,
        @Param("otherUserId") otherUserId: Long?,
        pageable: Pageable
    ): Page<Message>
}
