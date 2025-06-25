package com.zimche.audit.exception

/**
 * Exception thrown when email operations fail
 */
class EmailException(
    message: String,
    val recipient: String? = null,
    val emailType: String? = null,
    cause: Throwable? = null
) : RuntimeException(message, cause) {
    
    constructor(emailType: String, recipient: String, cause: Throwable) : 
        this("Failed to send $emailType email to $recipient: ${cause.message}", recipient, emailType, cause)
}
