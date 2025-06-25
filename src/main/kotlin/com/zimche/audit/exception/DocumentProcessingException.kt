package com.zimche.audit.exception

/**
 * Exception thrown when document processing fails
 */
class DocumentProcessingException(
    message: String,
    val documentId: Long? = null,
    val processingStep: String? = null,
    cause: Throwable? = null
) : RuntimeException(message, cause) {
    
    constructor(processingStep: String, documentId: Long, cause: Throwable) : 
        this("Document processing failed at step '$processingStep' for document $documentId: ${cause.message}", 
             documentId, processingStep, cause)
}
