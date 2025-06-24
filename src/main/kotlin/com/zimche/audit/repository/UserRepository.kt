package com.zimche.audit.repository

import com.zimche.audit.entity.User
import com.zimche.audit.enums.UserRole
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

@Repository
interface UserRepository : JpaRepository<User, Long> {

    fun findByEmail(email: String): Optional<User>

    fun existsByEmail(email: String): Boolean

    fun findByRole(role: UserRole): List<User>

    fun findByUniversityId(universityId: Long): List<User>

    fun findByRoleAndUniversityId(role: UserRole, universityId: Long): List<User>

    fun findByIsActiveTrue(): List<User>

    fun findByFirstNameContainingIgnoreCaseOrLastNameContainingIgnoreCase(
        firstName: String,
        lastName: String
    ): List<User>

    @Query("""
        SELECT u FROM User u
        WHERE u.isActive = true
        AND (:role IS NULL OR u.role = :role)
        AND (:universityId IS NULL OR u.university.id = :universityId)
        AND (LOWER(u.firstName) LIKE LOWER(CONCAT('%', :search, '%'))
             OR LOWER(u.lastName) LIKE LOWER(CONCAT('%', :search, '%'))
             OR LOWER(u.email) LIKE LOWER(CONCAT('%', :search, '%')))
    """)
    fun findUsersWithFilters(
        @Param("role") role: UserRole?,
        @Param("universityId") universityId: Long?,
        @Param("search") search: String?,
        pageable: Pageable
    ): Page<User>

    @Query("SELECT COUNT(u) FROM User u WHERE u.role = :role")
    fun countByRole(@Param("role") role: UserRole): Long

    @Query("SELECT COUNT(u) FROM User u WHERE u.university.id = :universityId")
    fun countByUniversityId(@Param("universityId") universityId: Long): Long
}
