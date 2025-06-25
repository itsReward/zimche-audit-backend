package com.zimche.audit.util

import com.zimche.audit.security.UserPrincipal
import org.springframework.security.core.context.SecurityContextHolder
import java.security.SecureRandom
import java.util.*

object SecurityUtils {

    private val random = SecureRandom()

    fun getCurrentUserPrincipal(): UserPrincipal? {
        val authentication = SecurityContextHolder.getContext().authentication
        return if (authentication?.principal is UserPrincipal) {
            authentication.principal as UserPrincipal
        } else null
    }

    fun getCurrentUserId(): Long? {
        return getCurrentUserPrincipal()?.id
    }

    fun getCurrentUserEmail(): String? {
        return getCurrentUserPrincipal()?.email
    }

    fun getCurrentUniversityId(): Long? {
        return getCurrentUserPrincipal()?.universityId
    }

    fun hasRole(role: String): Boolean {
        val principal = getCurrentUserPrincipal()
        return principal?.authorities?.any { it.authority == "ROLE_$role" } ?: false
    }

    fun isAdmin(): Boolean {
        return hasRole("ADMIN")
    }

    fun isUniversityStaff(): Boolean {
        return hasRole("UNIVERSITY_STAFF")
    }

    fun isPeerReviewer(): Boolean {
        return hasRole("PEER_REVIEWER")
    }

    fun isSuperUser(): Boolean {
        return hasRole("SUPER_USER")
    }

    fun canAccessUniversity(universityId: Long): Boolean {
        return isAdmin() || getCurrentUniversityId() == universityId
    }

    fun generateRandomPassword(length: Int = 12): String {
        val chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
        return (1..length)
            .map { chars[random.nextInt(chars.length)] }
            .joinToString("")
    }

    fun generateRandomToken(length: Int = 32): String {
        val bytes = ByteArray(length)
        random.nextBytes(bytes)
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes)
    }

    fun maskEmail(email: String): String {
        val atIndex = email.indexOf('@')
        return if (atIndex > 2) {
            email.substring(0, 2) + "*".repeat(atIndex - 2) + email.substring(atIndex)
        } else {
            email
        }
    }

    fun isValidIPAddress(ip: String): Boolean {
        val parts = ip.split(".")
        if (parts.size != 4) return false
        
        return parts.all { part ->
            try {
                val num = part.toInt()
                num in 0..255
            } catch (e: NumberFormatException) {
                false
            }
        }
    }

    fun sanitizeForLog(input: String): String {
        // Remove potential log injection characters
        return input.replace("[\r\n\t]".toRegex(), "_")
    }
}
