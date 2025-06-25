package com.zimche.audit.exception


/**
 * Exception thrown when business validation rules are violated
 */
class ValidationException(
    message: String,
    val field: String? = null,
    val code: String? = null
) : RuntimeException(message) {

    constructor(field: String, message: String, code: String) : this(message = message, /*field=field, code = code*/)
}
