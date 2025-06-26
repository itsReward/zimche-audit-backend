package com.zimche.audit.exception


/**
 * Exception thrown when business validation rules are violated
 */
class ValidationException(
    message: String,
    val field: String? = null,
    val code: String? = null
) : RuntimeException(message) {

    // Alternative approach using companion object
    companion object {
        fun forField(field: String, message: String, code: String): ValidationException {
            return ValidationException(
                message = message,
                field = field,
                code = code
            )
        }
    }


}
