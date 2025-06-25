package com.zimche.audit.exception

/**
 * Exception thrown when an external service fails or is unavailable
 */
class ServiceException(
    message: String,
    val service: String,
    cause: Throwable? = null
) : RuntimeException(message, cause) {
    
    constructor(service: String, operation: String, cause: Throwable) : 
        this(message = "$service service failed during $operation: ${cause.message}", service, cause)
}
