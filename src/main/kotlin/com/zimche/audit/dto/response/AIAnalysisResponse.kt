package com.zimche.audit.dto.response

import com.zimche.audit.entity.AIAnalysis
import java.time.LocalDateTime

data class AIAnalysisResponse(
    val id: Long,
    val analysisType: String,
    val result: String,
    val confidenceScore: Double?,
    val tokensUsed: Int?,
    val processingTimeMs: Long?,
    val modelVersion: String?,
    val document: DocumentSimpleResponse,
    val requestedBy: UserSimpleResponse,
    val createdAt: LocalDateTime
) {
    companion object {
        fun from(analysis: AIAnalysis): AIAnalysisResponse {
            return AIAnalysisResponse(
                id = analysis.id,
                analysisType = analysis.analysisType,
                result = analysis.result,
                confidenceScore = analysis.confidenceScore,
                tokensUsed = analysis.tokensUsed,
                processingTimeMs = analysis.processingTimeMs,
                modelVersion = analysis.modelVersion,
                document = DocumentSimpleResponse.from(analysis.document),
                requestedBy = UserSimpleResponse.from(analysis.requestedBy),
                createdAt = analysis.createdAt
            )
        }
    }
}
