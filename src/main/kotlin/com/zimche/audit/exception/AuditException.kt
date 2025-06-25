package com.zimche.audit.exception

/**
 * Exception thrown when audit operations fail or are in invalid state
 */
class AuditException(
    message: String,
    val auditId: Long? = null,
    val auditStatus: String? = null
) : RuntimeException(message) {

    constructor(operation: String, auditId: Long, currentStatus: String) :
            this(
                message = "Cannot $operation audit $auditId in status $currentStatus",
                auditId = auditId,
                auditStatus = currentStatus
            )

}
