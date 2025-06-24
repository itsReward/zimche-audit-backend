package com.zimche.audit.entity

import jakarta.persistence.*
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.jpa.domain.support.AuditingEntityListener
import java.time.LocalDateTime

@Entity
@Table(name = "ai_analyses")
@EntityListeners(AuditingEntityListener::class)
data class AIAnalysis(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @Column(name = "analysis_type", nullable = false)
    val analysisType: String, // e.g., "SUMMARY", "COMPLIANCE_CHECK", "BIAS_DETECTION"

    @Column(nullable = false, columnDefinition = "TEXT")
    val prompt: String,

    @Column(nullable = false, columnDefinition = "TEXT")
    val result: String,

    @Column(name = "confidence_score")
    val confidenceScore: Double? = null,

    @Column(name = "tokens_used")
    val tokensUsed: Int? = null,

    @Column(name = "processing_time_ms")
    val processingTimeMs: Long? = null,

    @Column(name = "model_version")
    val modelVersion: String? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "document_id", nullable = false)
    val document: Document,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "requested_by", nullable = false)
    val requestedBy: User,

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as AIAnalysis
        return id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String = "AIAnalysis(id=$id, analysisType='$analysisType', documentId=${document.id})"
}
