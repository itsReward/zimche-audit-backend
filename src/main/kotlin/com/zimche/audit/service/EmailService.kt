package com.zimche.audit.service

import com.zimche.audit.entity.Document
import com.zimche.audit.entity.User
import org.springframework.beans.factory.annotation.Value
import org.springframework.mail.SimpleMailMessage
import org.springframework.mail.javamail.JavaMailSender
import org.springframework.scheduling.annotation.Async
import org.springframework.stereotype.Service

@Service
class EmailService(
    private val mailSender: JavaMailSender,
    @Value("\${spring.mail.username}") private val fromEmail: String,
    @Value("\${app.frontend.url:http://localhost:3000}") private val frontendUrl: String
) {

    @Async
    fun sendWelcomeEmail(user: User) {
        val message = SimpleMailMessage().apply {
            from = fromEmail
            setTo(user.email)
            subject = "Welcome to ZIMCHE Audit Management System"
            text = """
                Dear ${user.fullName},

                Welcome to the ZIMCHE University Audit Management System!

                Your account has been successfully created with the following details:
                - Email: ${user.email}
                - Role: ${user.role.displayName}
                ${if (user.university != null) "- University: ${user.university.name}" else ""}

                You can now log in to the system at: $frontendUrl

                If you have any questions, please contact our support team.

                Best regards,
                ZIMCHE Team
            """.trimIndent()
        }

        try {
            mailSender.send(message)
        } catch (e: Exception) {
            println("Failed to send welcome email to ${user.email}: ${e.message}")
        }
    }

    @Async
    fun sendPasswordResetEmail(user: User, resetToken: String) {
        val resetUrl = "$frontendUrl/reset-password?token=$resetToken"

        val message = SimpleMailMessage().apply {
            from = fromEmail
            setTo(user.email)
            subject = "Password Reset Request - ZIMCHE Audit System"
            text = """
                Dear ${user.fullName},

                You have requested to reset your password for the ZIMCHE Audit Management System.

                Please click the following link to reset your password:
                $resetUrl

                This link will expire in 1 hour for security reasons.

                If you did not request this password reset, please ignore this email.

                Best regards,
                ZIMCHE Team
            """.trimIndent()
        }

        try {
            mailSender.send(message)
        } catch (e: Exception) {
            println("Failed to send password reset email to ${user.email}: ${e.message}")
        }
    }

    @Async
    fun sendDocumentUploadNotification(document: Document, recipients: List<User>) {
        recipients.forEach { recipient ->
            val message = SimpleMailMessage().apply {
                from = fromEmail
                setTo(recipient.email)
                subject = "New Document Uploaded - ${document.title}"
                text = """
                    Dear ${recipient.fullName},

                    A new document has been uploaded to the ZIMCHE Audit Management System:

                    Document: ${document.title}
                    University: ${document.university.name}
                    Uploaded by: ${document.uploadedBy.fullName}
                    Upload date: ${document.createdAt}

                    Please log in to the system to review the document: $frontendUrl

                    Best regards,
                    ZIMCHE Team
                """.trimIndent()
            }

            try {
                mailSender.send(message)
            } catch (e: Exception) {
                println("Failed to send document upload notification to ${recipient.email}: ${e.message}")
            }
        }
    }

    @Async
    fun sendDocumentStatusChangeNotification(document: Document) {
        val message = SimpleMailMessage().apply {
            from = fromEmail
            setTo(document.uploadedBy.email)
            subject = "Document Status Updated - ${document.title}"
            text = """
                Dear ${document.uploadedBy.fullName},

                The status of your document has been updated:

                Document: ${document.title}
                New Status: ${document.status.displayName}
                Reviewed by: ${document.reviewedBy?.fullName ?: "System"}
                Review date: ${document.reviewedAt}

                ${if (document.reviewComments != null) "Comments: ${document.reviewComments}" else ""}

                Please log in to the system for more details: $frontendUrl

                Best regards,
                ZIMCHE Team
            """.trimIndent()
        }

        try {
            mailSender.send(message)
        } catch (e: Exception) {
            println("Failed to send status change notification to ${document.uploadedBy.email}: ${e.message}")
        }
    }

    @Async
    fun sendAuditReminderEmail(user: User, auditTitle: String, scheduledDate: String) {
        val message = SimpleMailMessage().apply {
            from = fromEmail
            setTo(user.email)
            subject = "Audit Reminder - $auditTitle"
            text = """
                Dear ${user.fullName},

                This is a reminder about the upcoming audit:

                Audit: $auditTitle
                Scheduled Date: $scheduledDate
                University: ${user.university?.name ?: "N/A"}

                Please ensure all required documents are submitted before the audit date.

                Log in to the system for more details: $frontendUrl

                Best regards,
                ZIMCHE Team
            """.trimIndent()
        }

        try {
            mailSender.send(message)
        } catch (e: Exception) {
            println("Failed to send audit reminder to ${user.email}: ${e.message}")
        }
    }
}
