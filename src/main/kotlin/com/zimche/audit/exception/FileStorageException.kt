package com.zimche.audit.exception

/**
 * Exception thrown when file storage operations fail
 */
class FileStorageException(
    message: String,
    val operation: String? = null,
    cause: Throwable? = null
) : RuntimeException(message, cause) {

    companion object {
        fun forOperation(operation: String, auditId: Long, currentStatus: String): AuditException {
            return AuditException("Cannot $operation audit $auditId in status $currentStatus", auditId, currentStatus)
        }
    }

}
