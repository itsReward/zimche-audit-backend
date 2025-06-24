package com.zimche.audit.repository

import com.zimche.audit.entity.Audit
import com.zimche.audit.enums.AuditStatus
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

@Repository
interface AuditRepository : JpaRepository<Audit, Long> {

    fun findByUniversityId(universityId: Long): List<Audit>

    fun findByUniversityId(universityId: Long, pageable: Pageable): Page<Audit>

    fun findByStatus(status: AuditStatus): List<Audit>

    fun findByAssignedToId(assignedToId: Long): List<Audit>

    fun findByCreatedById(createdById: Long): List<Audit>

    fun findByStatusAndUniversityId(status: AuditStatus, universityId: Long): List<Audit>

    fun findByScheduledDateBetween(startDate: LocalDateTime, endDate: LocalDateTime): List<Audit>

    @Query("""
        SELECT a FROM Audit a
        WHERE (:universityId IS NULL OR a.university.id = :universityId)
        AND (:status IS NULL OR a.status = :status)
        AND (:assignedToId IS NULL OR a.assignedTo.id = :assignedToId)
        AND (LOWER(a.title) LIKE LOWER(CONCAT('%', :search, '%'))
             OR LOWER(a.description) LIKE LOWER(CONCAT('%', :search, '%')))
        ORDER BY a.scheduledDate DESC
    """)
    fun findAuditsWithFilters(
        @Param("universityId") universityId: Long?,
        @Param("status") status: AuditStatus?,
        @Param("assignedToId") assignedToId: Long?,
        @Param("search") search: String?,
        pageable: Pageable
    ): Page<Audit>

    @Query("SELECT COUNT(a) FROM Audit a WHERE a.status = :status")
    fun countByStatus(@Param("status") status: AuditStatus): Long

    @Query("SELECT COUNT(a) FROM Audit a WHERE a.university.id = :universityId")
    fun countByUniversityId(@Param("universityId") universityId: Long): Long

    @Query("""
        SELECT a FROM Audit a
        LEFT JOIN FETCH a.auditSteps
        WHERE a.id = :id
    """)
    fun findByIdWithSteps(@Param("id") id: Long): Audit?

    @Query("""
        SELECT a FROM Audit a
        WHERE a.status IN (:statuses)
        AND a.scheduledDate <= :date
        ORDER BY a.scheduledDate ASC
    """)
    fun findUpcomingAudits(
        @Param("statuses") statuses: List<AuditStatus>,
        @Param("date") date: LocalDateTime
    ): List<Audit>

    @Query("""
        SELECT AVG(a.complianceScore) FROM Audit a
        WHERE a.university.id = :universityId
        AND a.complianceScore IS NOT NULL
    """)
    fun getAverageComplianceScoreByUniversity(@Param("universityId") universityId: Long): Double?
}
