package com.zimche.audit.util

import com.zimche.audit.exception.BadRequestException
import java.util.regex.Pattern

object ValidationUtils {

    private val EMAIL_PATTERN = Pattern.compile(
        "^[A-Za-z0-9+_.-]+@([A-Za-z0-9.-]+\\.[A-Za-z]{2,})$"
    )

    private val PHONE_PATTERN = Pattern.compile(
        "^[+]?[0-9]{10,15}$"
    )

    private val PASSWORD_PATTERN = Pattern.compile(
        "^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*[@#$%^&+=])(?=\\S+$).{8,}$"
    )

    fun validateEmail(email: String): Boolean {
        return EMAIL_PATTERN.matcher(email).matches()
    }

    fun validatePhone(phone: String): Boolean {
        return PHONE_PATTERN.matcher(phone).matches()
    }

    fun validatePassword(password: String): Boolean {
        return password.length >= 6 // Simplified for demo
    }

    fun validateStrongPassword(password: String): Boolean {
        return PASSWORD_PATTERN.matcher(password).matches()
    }

    fun validateRequired(value: String?, fieldName: String) {
        if (value.isNullOrBlank()) {
            throw BadRequestException("$fieldName is required")
        }
    }

    fun validateLength(value: String?, fieldName: String, minLength: Int, maxLength: Int) {
        if (value != null) {
            if (value.length < minLength) {
                throw BadRequestException("$fieldName must be at least $minLength characters long")
            }
            if (value.length > maxLength) {
                throw BadRequestException("$fieldName cannot exceed $maxLength characters")
            }
        }
    }

    fun validatePositive(value: Long?, fieldName: String) {
        if (value != null && value <= 0) {
            throw BadRequestException("$fieldName must be positive")
        }
    }

    fun validateRange(value: Double?, fieldName: String, min: Double, max: Double) {
        if (value != null && (value < min || value > max)) {
            throw BadRequestException("$fieldName must be between $min and $max")
        }
    }

    fun sanitizeInput(input: String?): String? {
        return input?.trim()?.takeIf { it.isNotEmpty() }
    }

    fun validateUniversityCode(code: String): Boolean {
        return code.matches("^[A-Z0-9]{2,10}$".toRegex())
    }

    fun validateFileName(filename: String): Boolean {
        val invalidChars = setOf('<', '>', ':', '"', '|', '?', '*', '\\', '/')
        return filename.isNotEmpty() && filename.none { it in invalidChars }
    }
}
