package com.zimche.audit.exception

/**
 * Exception thrown when file storage operations fail
 */
class FileStorageException(
    message: String,
    val operation: String? = null,
    cause: Throwable? = null
) : RuntimeException(message, cause) {
    
    constructor(operation: String, filename: String, cause: Throwable) : 
        this(message = "Failed to $operation file '$filename': ${cause.message}", operation, cause)
}
