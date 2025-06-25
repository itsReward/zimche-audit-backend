package com.zimche.audit.exception

/**
 * Exception thrown when there's a conflict with the current state of the resource
 */
class ConflictException(message: String) : RuntimeException(message) {
    constructor(resource: String, field: String, value: Any) : this("$resource with $field '$value' already exists")
}
