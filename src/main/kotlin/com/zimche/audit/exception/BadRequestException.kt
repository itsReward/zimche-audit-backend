package com.zimche.audit.exception

/**
 * Exception thrown when a request is malformed or contains invalid data
 */
class BadRequestException(message: String) : RuntimeException(message) {
    constructor(field: String, value: Any?, reason: String) : this("Invalid $field '$value': $reason")
}
