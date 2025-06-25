package com.zimche.audit.service

import com.theokanning.openai.completion.chat.ChatCompletionRequest
import com.theokanning.openai.completion.chat.ChatMessage
import com.theokanning.openai.completion.chat.ChatMessageRole
import com.theokanning.openai.service.OpenAiService
import com.zimche.audit.dto.response.AIAnalysisResponse
import com.zimche.audit.entity.AIAnalysis
import com.zimche.audit.entity.Document
import com.zimche.audit.exception.BadRequestException
import com.zimche.audit.repository.AIAnalysisRepository
import org.apache.tika.Tika
import org.springframework.beans.factory.annotation.Value
import org.springframework.scheduling.annotation.Async
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Duration

@Service
@Transactional
class AIService(
    private val aiAnalysisRepository: AIAnalysisRepository,
    private val documentService: DocumentService,
    private val userService: UserService,
    @Value("\${app.openai.api-key}") private val openAiApiKey: String,
    @Value("\${app.openai.model}") private val model: String,
    @Value("\${app.openai.max-tokens}") private val maxTokens: Int
) {

    private val openAiService: OpenAiService by lazy {
        OpenAiService(openAiApiKey, Duration.ofSeconds(60))
    }

    private val tika = Tika()

    @Async
    fun scheduleDocumentAnalysis(documentId: Long) {
        try {
            val document = documentService.findById(documentId)

            // Extract text from document
            val documentText = extractTextFromDocument(document)

            // Perform different types of analysis
            performSummaryAnalysis(document, documentText)
            performComplianceAnalysis(document, documentText)
            performBiasAnalysis(document, documentText)

        } catch (e: Exception) {
            println("Failed to analyze document $documentId: ${e.message}")
        }
    }

    fun analyzeDocument(
        documentId: Long,
        analysisType: String,
        userEmail: String
    ): AIAnalysisResponse {
        val document = documentService.findById(documentId)
        val user = userService.findByEmail(userEmail)
        val documentText = extractTextFromDocument(document)

        val result = when (analysisType.uppercase()) {
            "SUMMARY" -> generateSummary(documentText)
            "COMPLIANCE" -> checkCompliance(documentText)
            "BIAS" -> detectBias(documentText)
            "QUALITY" -> assessQuality(documentText)
            else -> throw BadRequestException("Unsupported analysis type: $analysisType")
        }

        val analysis = AIAnalysis(
            analysisType = analysisType.uppercase(),
            prompt = buildPrompt(analysisType, documentText),
            result = result.response,
            confidenceScore = result.confidence,
            tokensUsed = result.tokensUsed,
            processingTimeMs = result.processingTime,
            modelVersion = model,
            document = document,
            requestedBy = user
        )

        val savedAnalysis = aiAnalysisRepository.save(analysis)
        return AIAnalysisResponse.from(savedAnalysis)
    }

    private fun extractTextFromDocument(document: Document): String {
        return try {
            // In a real implementation, you would download the file from S3 and extract text
            // For now, we'll simulate with the document title and description
            "${document.title}\n\n${document.description ?: ""}"
        } catch (e: Exception) {
            throw BadRequestException("Failed to extract text from document: ${e.message}")
        }
    }

    private fun performSummaryAnalysis(document: Document, text: String) {
        val result = generateSummary(text)
        saveAnalysis("SUMMARY", document, text, result, document.uploadedBy)
    }

    private fun performComplianceAnalysis(document: Document, text: String) {
        val result = checkCompliance(text)
        saveAnalysis("COMPLIANCE", document, text, result, document.uploadedBy)
    }

    private fun performBiasAnalysis(document: Document, text: String) {
        val result = detectBias(text)
        saveAnalysis("BIAS", document, text, result, document.uploadedBy)
    }

    private fun generateSummary(text: String): AIResult {
        val prompt = """
            Please provide a concise summary of the following document.
            Focus on key points, main findings, and important conclusions.
            Keep the summary under 300 words.

            Document:
            $text
        """.trimIndent()

        return callOpenAI(prompt)
    }

    private fun checkCompliance(text: String): AIResult {
        val prompt = """
            Analyze the following document for compliance with university audit standards.
            Check for:
            1. Required documentation completeness
            2. Adherence to regulatory guidelines
            3. Data accuracy and consistency
            4. Missing information or red flags

            Provide a compliance score (0-100) and detailed explanation.

            Document:
            $text
        """.trimIndent()

        return callOpenAI(prompt)
    }

    private fun detectBias(text: String): AIResult {
        val prompt = """
            Analyze the following document for potential bias or unfair treatment.
            Look for:
            1. Language that favors certain groups
            2. Unequal representation or treatment
            3. Discriminatory practices or policies
            4. Cultural or gender bias

            Provide a bias assessment and recommendations for improvement.

            Document:
            $text
        """.trimIndent()

        return callOpenAI(prompt)
    }

    private fun assessQuality(text: String): AIResult {
        val prompt = """
            Assess the overall quality of the following document.
            Evaluate:
            1. Clarity and coherence of content
            2. Completeness of information
            3. Professional presentation
            4. Accuracy and reliability

            Provide a quality score (0-100) and improvement suggestions.

            Document:
            $text
        """.trimIndent()

        return callOpenAI(prompt)
    }

    private fun callOpenAI(prompt: String): AIResult {
        val startTime = System.currentTimeMillis()

        try {
            val chatMessage = ChatMessage(ChatMessageRole.USER.value(), prompt)
            val request = ChatCompletionRequest.builder()
                .model(model)
                .messages(listOf(chatMessage))
                .maxTokens(maxTokens)
                .temperature(0.3)
                .build()

            val response = openAiService.createChatCompletion(request)
            val content = response.choices.firstOrNull()?.message?.content ?: "No response generated"
            val tokensUsed = response.usage?.totalTokens ?: 0
            val processingTime = System.currentTimeMillis() - startTime

            return AIResult(
                response = content,
                confidence = calculateConfidence(content),
                tokensUsed = tokensUsed.toInt(),
                processingTime = processingTime
            )
        } catch (e: Exception) {
            throw BadRequestException("AI analysis failed: ${e.message}")
        }
    }

    private fun calculateConfidence(response: String): Double {
        // Simple confidence calculation based on response length and keywords
        val length = response.length
        val confidenceKeywords = listOf("confident", "certain", "clear", "evident", "strongly")
        val uncertaintyKeywords = listOf("uncertain", "unclear", "possibly", "might", "could")

        var confidence = when {
            length < 50 -> 0.3
            length < 200 -> 0.6
            length < 500 -> 0.8
            else -> 0.9
        }

        val lowerResponse = response.lowercase()
        confidenceKeywords.forEach { keyword ->
            if (lowerResponse.contains(keyword)) confidence += 0.1
        }
        uncertaintyKeywords.forEach { keyword ->
            if (lowerResponse.contains(keyword)) confidence -= 0.1
        }

        return minOf(1.0, maxOf(0.0, confidence))
    }

    private fun buildPrompt(analysisType: String, text: String): String {
        return when (analysisType.uppercase()) {
            "SUMMARY" -> "Summarize: $text"
            "COMPLIANCE" -> "Check compliance: $text"
            "BIAS" -> "Detect bias: $text"
            "QUALITY" -> "Assess quality: $text"
            else -> "Analyze: $text"
        }
    }

    private fun saveAnalysis(
        analysisType: String,
        document: Document,
        text: String,
        result: AIResult,
        user: com.zimche.audit.entity.User
    ) {
        val analysis = AIAnalysis(
            analysisType = analysisType,
            prompt = buildPrompt(analysisType, text),
            result = result.response,
            confidenceScore = result.confidence,
            tokensUsed = result.tokensUsed,
            processingTimeMs = result.processingTime,
            modelVersion = model,
            document = document,
            requestedBy = user
        )
        aiAnalysisRepository.save(analysis)
    }

    @Transactional(readOnly = true)
    fun getDocumentAnalyses(documentId: Long): List<AIAnalysisResponse> {
        return aiAnalysisRepository.findByDocumentId(documentId)
            .map { AIAnalysisResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun getAnalysisStats(): Map<String, Any> {
        val totalAnalyses = aiAnalysisRepository.count()
        val totalTokensUsed = aiAnalysisRepository.getTotalTokensUsed() ?: 0L
        val avgProcessingTime = aiAnalysisRepository.getAverageProcessingTimeByType("SUMMARY") ?: 0.0

        return mapOf(
            "totalAnalyses" to totalAnalyses,
            "totalTokensUsed" to totalTokensUsed,
            "averageProcessingTime" to avgProcessingTime
        )
    }

    private data class AIResult(
        val response: String,
        val confidence: Double,
        val tokensUsed: Int,
        val processingTime: Long
    )
}
