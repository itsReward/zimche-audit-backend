package com.zimche.audit.repository

import com.zimche.audit.entity.AIAnalysis
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

@Repository
interface AIAnalysisRepository : JpaRepository<AIAnalysis, Long> {

    fun findByDocumentId(documentId: Long): List<AIAnalysis>

    fun findByAnalysisType(analysisType: String): List<AIAnalysis>

    fun findByDocumentIdAndAnalysisType(documentId: Long, analysisType: String): List<AIAnalysis>

    fun findByRequestedById(requestedById: Long): List<AIAnalysis>

    fun findByCreatedAtBetween(startDate: LocalDateTime, endDate: LocalDateTime): List<AIAnalysis>

    @Query("""
        SELECT a FROM AIAnalysis a
        WHERE (:documentId IS NULL OR a.document.id = :documentId)
        AND (:analysisType IS NULL OR a.analysisType = :analysisType)
        AND (:requestedById IS NULL OR a.requestedBy.id = :requestedById)
        ORDER BY a.createdAt DESC
    """)
    fun findAnalysesWithFilters(
        @Param("documentId") documentId: Long?,
        @Param("analysisType") analysisType: String?,
        @Param("requestedById") requestedById: Long?,
        pageable: Pageable
    ): Page<AIAnalysis>

    @Query("SELECT COUNT(a) FROM AIAnalysis a WHERE a.analysisType = :analysisType")
    fun countByAnalysisType(@Param("analysisType") analysisType: String): Long

    @Query("SELECT SUM(a.tokensUsed) FROM AIAnalysis a WHERE a.tokensUsed IS NOT NULL")
    fun getTotalTokensUsed(): Long?

    @Query("""
        SELECT AVG(a.processingTimeMs) FROM AIAnalysis a
        WHERE a.processingTimeMs IS NOT NULL
        AND a.analysisType = :analysisType
    """)
    fun getAverageProcessingTimeByType(@Param("analysisType") analysisType: String): Double?

    @Query("""
        SELECT a FROM AIAnalysis a
        WHERE a.document.id = :documentId
        AND a.analysisType = :analysisType
        ORDER BY a.createdAt DESC
        LIMIT 1
    """)
    fun findLatestAnalysisForDocument(
        @Param("documentId") documentId: Long,
        @Param("analysisType") analysisType: String
    ): AIAnalysis?
}
