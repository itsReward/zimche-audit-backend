package com.zimche.audit.service

import com.zimche.audit.dto.response.UserResponse
import com.zimche.audit.entity.User
import com.zimche.audit.enums.UserRole
import com.zimche.audit.exception.BadRequestException
import com.zimche.audit.exception.ResourceNotFoundException
import com.zimche.audit.repository.UserRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional
class UserService(
    private val userRepository: UserRepository,
    private val universityService: UniversityService
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
}
