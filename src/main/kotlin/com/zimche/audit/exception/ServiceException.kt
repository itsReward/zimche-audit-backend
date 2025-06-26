package com.zimche.audit.exception

/**
 * Exception thrown when an external service fails or is unavailable
 */
class ServiceException(
    message: String,
    val service: String,
    cause: Throwable? = null
) : RuntimeException(message, cause) {

    companion object {
        fun forOperation(service: String, operation: String, cause: Throwable): ServiceException {
            return ServiceException(
                message = "$service service failed during $operation: ${cause.message}",
                service = service,
                cause = cause
            )
        }
    }


}
