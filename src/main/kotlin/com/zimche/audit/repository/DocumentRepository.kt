package com.zimche.audit.repository

import com.zimche.audit.entity.Document
import com.zimche.audit.enums.DocumentStatus
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

@Repository
interface DocumentRepository : JpaRepository<Document, Long> {

    fun findByUniversityId(universityId: Long): List<Document>

    fun findByUniversityId(universityId: Long, pageable: Pageable): Page<Document>

    fun findByStatus(status: DocumentStatus): List<Document>

    fun findByUploadedById(uploadedById: Long): List<Document>

    fun findByReviewedById(reviewedById: Long): List<Document>

    fun findByStatusAndUniversityId(status: DocumentStatus, universityId: Long): List<Document>

    fun findByCreatedAtBetween(startDate: LocalDateTime, endDate: LocalDateTime): List<Document>

    @Query("""
        SELECT d FROM Document d
        WHERE (:universityId IS NULL OR d.university.id = :universityId)
        AND (:status IS NULL OR d.status = :status)
        AND (:uploadedById IS NULL OR d.uploadedBy.id = :uploadedById)
        AND (LOWER(d.title) LIKE LOWER(CONCAT('%', :search, '%'))
             OR LOWER(d.fileName) LIKE LOWER(CONCAT('%', :search, '%')))
        ORDER BY d.createdAt DESC
    """)
    fun findDocumentsWithFilters(
        @Param("universityId") universityId: Long?,
        @Param("status") status: DocumentStatus?,
        @Param("uploadedById") uploadedById: Long?,
        @Param("search") search: String?,
        pageable: Pageable
    ): Page<Document>

    @Query("SELECT COUNT(d) FROM Document d WHERE d.status = :status")
    fun countByStatus(@Param("status") status: DocumentStatus): Long

    @Query("SELECT COUNT(d) FROM Document d WHERE d.university.id = :universityId")
    fun countByUniversityId(@Param("universityId") universityId: Long): Long

    @Query("""
        SELECT d FROM Document d
        LEFT JOIN FETCH d.aiAnalyses
        WHERE d.id = :id
    """)
    fun findByIdWithAnalyses(@Param("id") id: Long): Document?

    @Query("""
        SELECT SUM(d.fileSize) FROM Document d
        WHERE d.university.id = :universityId
    """)
    fun getTotalFileSizeByUniversity(@Param("universityId") universityId: Long): Long?
}
