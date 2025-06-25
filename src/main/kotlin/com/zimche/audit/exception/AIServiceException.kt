package com.zimche.audit.exception

/**
 * Exception thrown when AI service operations fail
 */
class AIServiceException(
    message: String,
    val analysisType: String? = null,
    val documentId: Long? = null,
    cause: Throwable? = null
) : RuntimeException(message, cause) {
    
    constructor(analysisType: String, documentId: Long, cause: Throwable) : 
        this("AI analysis '$analysisType' failed for document $documentId: ${cause.message}", analysisType, documentId, cause)
}
