package com.zimche.audit.repository

import com.zimche.audit.entity.University
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

@Repository
interface UniversityRepository : JpaRepository<University, Long> {

    fun findByCode(code: String): Optional<University>

    fun existsByCode(code: String): Boolean

    fun existsByName(name: String): Boolean

    fun findByIsActiveTrue(): List<University>

    fun findByNameContainingIgnoreCase(name: String): List<University>

    @Query("""
        SELECT u FROM University u
        WHERE u.isActive = true
        AND (LOWER(u.name) LIKE LOWER(CONCAT('%', :search, '%'))
             OR LOWER(u.code) LIKE LOWER(CONCAT('%', :search, '%'))
             OR LOWER(u.contactEmail) LIKE LOWER(CONCAT('%', :search, '%')))
    """)
    fun findUniversitiesWithSearch(
        @Param("search") search: String?,
        pageable: Pageable
    ): Page<University>

    @Query("SELECT COUNT(u) FROM University u WHERE u.isActive = true")
    fun countActiveUniversities(): Long

    @Query("""
        SELECT u FROM University u
        LEFT JOIN FETCH u.users
        WHERE u.id = :id AND u.isActive = true
    """)
    fun findByIdWithUsers(@Param("id") id: Long): Optional<University>
}
