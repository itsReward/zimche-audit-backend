package com.zimche.audit.exception

/**
 * Exception thrown when a user lacks permission to access a resource
 */
class ForbiddenException(message: String = "Access denied") : RuntimeException(message) {
    constructor(action: String, resource: String) : this("Permission denied to $action $resource")
}
