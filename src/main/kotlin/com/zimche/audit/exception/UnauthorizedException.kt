package com.zimche.audit.exception

/**
 * Exception thrown when a user is not authenticated or token is invalid
 */
class UnauthorizedException(message: String = "Authentication required") : RuntimeException(message)
