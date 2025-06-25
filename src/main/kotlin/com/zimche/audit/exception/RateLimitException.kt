package com.zimche.audit.exception

/**
 * Exception thrown when rate limits are exceeded
 */
class RateLimitException(
    message: String = "Rate limit exceeded",
    val retryAfterSeconds: Long? = null
) : RuntimeException(message) {
    
    constructor(operation: String, retryAfterSeconds: Long) : 
        this(message = "Rate limit exceeded for $operation. Try again in $retryAfterSeconds seconds", retryAfterSeconds)
}
