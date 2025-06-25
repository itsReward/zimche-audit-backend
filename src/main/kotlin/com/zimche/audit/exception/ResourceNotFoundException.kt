package com.zimche.audit.exception

/**
 * Exception thrown when a requested resource is not found
 */
class ResourceNotFoundException(message: String) : RuntimeException(message) {
    constructor(resource: String, id: Any) : this("$resource not found with id: $id")
    constructor(resource: String, field: String, value: Any) : this("$resource not found with $field: $value")
}
