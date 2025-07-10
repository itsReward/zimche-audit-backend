package com.zimche.audit.service

import com.zimche.audit.dto.response.UserResponse
import com.zimche.audit.entity.User
import com.zimche.audit.enums.UserRole
import com.zimche.audit.exception.BadRequestException
import com.zimche.audit.exception.ResourceNotFoundException
import com.zimche.audit.repository.UserRepository
import com.zimche.audit.util.SpringProfileUtils
import jakarta.annotation.PostConstruct
import org.slf4j.LoggerFactory
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional
class UserService(
    private val userRepository: UserRepository,
    private val universityService: UniversityService,
    private val passwordEncoder: PasswordEncoder
) {

    fun findById(id: Long): User {
        return userRepository.findById(id)
            .orElseThrow { ResourceNotFoundException("User not found with id: $id") }
    }

    fun findByEmail(email: String): User {
        return userRepository.findByEmail(email)
            .orElseThrow { ResourceNotFoundException("User not found with email: $email") }
    }

    @Transactional(readOnly = true)
    fun getAllUsers(pageable: Pageable): Page<UserResponse> {
        return userRepository.findAll(pageable).map { UserResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun searchUsers(
        role: UserRole?,
        universityId: Long?,
        search: String?,
        pageable: Pageable
    ): Page<UserResponse> {
        return userRepository.findUsersWithFilters(role, universityId, search, pageable)
            .map { UserResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun getUsersByUniversity(universityId: Long): List<UserResponse> {
        return userRepository.findByUniversityId(universityId).map { UserResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun getUsersByRole(role: UserRole): List<UserResponse> {
        return userRepository.findByRole(role).map { UserResponse.from(it) }
    }

    fun updateUser(
        id: Long,
        firstName: String?,
        lastName: String?,
        phoneNumber: String?,
        universityId: Long?
    ): UserResponse {
        val user = findById(id)

        val university = universityId?.let { universityService.findById(it) }

        val updatedUser = user.copy(
            firstName = firstName ?: user.firstName,
            lastName = lastName ?: user.lastName,
            phoneNumber = phoneNumber ?: user.phoneNumber,
            university = university ?: user.university
        )

        return UserResponse.from(userRepository.save(updatedUser))
    }

    fun updateUserRole(id: Long, role: UserRole): UserResponse {
        val user = findById(id)
        val updatedUser = user.copy(role = role)
        return UserResponse.from(userRepository.save(updatedUser))
    }

    fun deactivateUser(id: Long): UserResponse {
        val user = findById(id)
        if (user.role == UserRole.ADMIN) {
            val adminCount = userRepository.countByRole(UserRole.ADMIN)
            if (adminCount <= 1) {
                throw BadRequestException("Cannot deactivate the last admin user")
            }
        }
        val updatedUser = user.copy(isActive = false)
        return UserResponse.from(userRepository.save(updatedUser))
    }

    fun activateUser(id: Long): UserResponse {
        val user = findById(id)
        val updatedUser = user.copy(isActive = true)
        return UserResponse.from(userRepository.save(updatedUser))
    }

    fun deleteUser(id: Long) {
        val user = findById(id)
        if (user.role == UserRole.ADMIN) {
            val adminCount = userRepository.countByRole(UserRole.ADMIN)
            if (adminCount <= 1) {
                throw BadRequestException("Cannot delete the last admin user")
            }
        }
        userRepository.delete(user)
    }

    @Transactional(readOnly = true)
    fun getUserStats(): Map<String, Any> {
        val totalUsers = userRepository.count()
        val activeUsers = userRepository.findByIsActiveTrue().size
        val usersByRole = UserRole.values().associate { role ->
            role.name to userRepository.countByRole(role)
        }

        return mapOf(
            "totalUsers" to totalUsers,
            "activeUsers" to activeUsers,
            "usersByRole" to usersByRole
        )
    }

    @PostConstruct
    @Transactional
    fun initializeDefaultAdminUser() {
        val userCount = userRepository.count()

        // Only create default admin if there are no users in the database
        if (userCount.toInt() == 0) {
            // Get credentials from application properties, or use defaults
            val adminEmail = System.getenv("DEFAULT_ADMIN_EMAIL") ?: "admin@zimche.ac.zw"
            val adminPassword = System.getenv("DEFAULT_ADMIN_PASSWORD") ?: "Admin@2025!"

            // Check if admin already exists (additional safety check)
            val existingAdmin = userRepository.findByEmail(adminEmail).orElse(null)

            if (existingAdmin == null) {
                val defaultAdmin = User(
                    email = adminEmail,
                    password = passwordEncoder.encode(adminPassword), // Encode the password
                    firstName = "System",
                    lastName = "Administrator",
                    role = UserRole.ADMIN,
                    phoneNumber = "+263000000000",
                    isActive = true,
                    isEmailVerified = true
                )

                val savedAdmin = userRepository.save(defaultAdmin)

                // Log the creation of default admin (important for auditing)
                logger.info("Default admin user created with email: ${savedAdmin.email}")

                // Print credentials to console during development (remove in production)
                if (SpringProfileUtils.isDevProfile()) {
                    logger.info("Default admin credentials: Email: $adminEmail, Password: $adminPassword")
                }
            }
        }
    }

    companion object {
        private val logger = LoggerFactory.getLogger(UserService::class.java)
    }

}
