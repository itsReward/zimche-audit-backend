#!/bin/bash

# Generate Utility Classes for ZIMCHE Audit System

BASE_DIR="src/main/kotlin/com/zimche/audit"
UTIL_DIR="$BASE_DIR/util"
EXCEPTION_DIR="$BASE_DIR/exception"

echo "🔧 Generating Utility classes..."

mkdir -p $UTIL_DIR
mkdir -p $EXCEPTION_DIR

# Exception classes
cat > $EXCEPTION_DIR/GlobalExceptionHandler.kt << 'EOF'
package com.zimche.audit.exception

import com.zimche.audit.dto.response.ApiResponse
import com.zimche.audit.dto.response.ValidationErrorResponse
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.access.AccessDeniedException
import org.springframework.security.authentication.BadCredentialsException
import org.springframework.validation.FieldError
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice
import org.springframework.web.multipart.MaxUploadSizeExceededException

@RestControllerAdvice
class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException::class)
    fun handleResourceNotFound(ex: ResourceNotFoundException): ResponseEntity<ApiResponse<Nothing>> {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(ApiResponse.error(ex.message ?: "Resource not found"))
    }

    @ExceptionHandler(BadRequestException::class)
    fun handleBadRequest(ex: BadRequestException): ResponseEntity<ApiResponse<Nothing>> {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(ApiResponse.error(ex.message ?: "Bad request"))
    }

    @ExceptionHandler(UnauthorizedException::class)
    fun handleUnauthorized(ex: UnauthorizedException): ResponseEntity<ApiResponse<Nothing>> {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
            .body(ApiResponse.error(ex.message ?: "Unauthorized"))
    }

    @ExceptionHandler(AccessDeniedException::class)
    fun handleAccessDenied(ex: AccessDeniedException): ResponseEntity<ApiResponse<Nothing>> {
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
            .body(ApiResponse.error("Access denied"))
    }

    @ExceptionHandler(BadCredentialsException::class)
    fun handleBadCredentials(ex: BadCredentialsException): ResponseEntity<ApiResponse<Nothing>> {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
            .body(ApiResponse.error("Invalid credentials"))
    }

    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidationErrors(ex: MethodArgumentNotValidException): ResponseEntity<ValidationErrorResponse> {
        val errors = mutableMapOf<String, String>()
        ex.bindingResult.allErrors.forEach { error ->
            val fieldName = (error as FieldError).field
            val errorMessage = error.defaultMessage ?: "Invalid value"
            errors[fieldName] = errorMessage
        }
        
        val response = ValidationErrorResponse(
            message = "Validation failed",
            errors = errors
        )
        
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response)
    }

    @ExceptionHandler(MaxUploadSizeExceededException::class)
    fun handleMaxUploadSizeExceeded(ex: MaxUploadSizeExceededException): ResponseEntity<ApiResponse<Nothing>> {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(ApiResponse.error("File size exceeds maximum allowed size"))
    }

    @ExceptionHandler(IllegalArgumentException::class)
    fun handleIllegalArgument(ex: IllegalArgumentException): ResponseEntity<ApiResponse<Nothing>> {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(ApiResponse.error(ex.message ?: "Invalid argument"))
    }

    @ExceptionHandler(Exception::class)
    fun handleGenericException(ex: Exception): ResponseEntity<ApiResponse<Nothing>> {
        // Log the exception for debugging
        ex.printStackTrace()
        
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(ApiResponse.error("An unexpected error occurred"))
    }
}
EOF

cat > $EXCEPTION_DIR/ResourceNotFoundException.kt << 'EOF'
package com.zimche.audit.exception

class ResourceNotFoundException(message: String) : RuntimeException(message)
EOF

cat > $EXCEPTION_DIR/BadRequestException.kt << 'EOF'
package com.zimche.audit.exception

class BadRequestException(message: String) : RuntimeException(message)
EOF

cat > $EXCEPTION_DIR/UnauthorizedException.kt << 'EOF'
package com.zimche.audit.exception

class UnauthorizedException(message: String) : RuntimeException(message)
EOF

# Utility classes
cat > $UTIL_DIR/FileUtils.kt << 'EOF'
package com.zimche.audit.util

import com.zimche.audit.exception.BadRequestException
import org.springframework.web.multipart.MultipartFile
import java.util.*

object FileUtils {

    private val ALLOWED_EXTENSIONS = setOf("pdf", "doc", "docx", "txt", "xlsx", "xls", "ppt", "pptx")
    private val MAX_FILE_SIZE = 50 * 1024 * 1024L // 50MB

    fun validateFile(file: MultipartFile) {
        if (file.isEmpty) {
            throw BadRequestException("File cannot be empty")
        }

        if (file.size > MAX_FILE_SIZE) {
            throw BadRequestException("File size cannot exceed ${MAX_FILE_SIZE / (1024 * 1024)}MB")
        }

        val extension = getFileExtension(file.originalFilename ?: "")
        if (extension !in ALLOWED_EXTENSIONS) {
            throw BadRequestException("File type not allowed. Allowed types: ${ALLOWED_EXTENSIONS.joinToString(", ")}")
        }
    }

    fun getFileExtension(filename: String): String {
        return filename.substringAfterLast(".", "").lowercase()
    }

    fun generateUniqueFileName(originalFilename: String): String {
        val timestamp = System.currentTimeMillis()
        val uuid = UUID.randomUUID().toString().substring(0, 8)
        val extension = getFileExtension(originalFilename)
        val name = originalFilename.substringBeforeLast(".")
            .replace(" ", "_")
            .replace("[^a-zA-Z0-9._-]".toRegex(), "")
            .take(50) // Limit name length

        return if (extension.isNotEmpty()) {
            "${name}_${timestamp}_${uuid}.${extension}"
        } else {
            "${name}_${timestamp}_${uuid}"
        }
    }

    fun formatFileSize(sizeInBytes: Long): String {
        val units = arrayOf("B", "KB", "MB", "GB", "TB")
        var size = sizeInBytes.toDouble()
        var unitIndex = 0

        while (size >= 1024 && unitIndex < units.size - 1) {
            size /= 1024
            unitIndex++
        }

        return String.format("%.2f %s", size, units[unitIndex])
    }

    fun isImageFile(filename: String): Boolean {
        val imageExtensions = setOf("jpg", "jpeg", "png", "gif", "bmp", "webp")
        return getFileExtension(filename) in imageExtensions
    }

    fun isDocumentFile(filename: String): Boolean {
        val documentExtensions = setOf("pdf", "doc", "docx", "txt", "rtf")
        return getFileExtension(filename) in documentExtensions
    }

    fun isSpreadsheetFile(filename: String): Boolean {
        val spreadsheetExtensions = setOf("xlsx", "xls", "csv")
        return getFileExtension(filename) in spreadsheetExtensions
    }

    fun isPresentationFile(filename: String): Boolean {
        val presentationExtensions = setOf("ppt", "pptx")
        return getFileExtension(filename) in presentationExtensions
    }
}
EOF

cat > $UTIL_DIR/ValidationUtils.kt << 'EOF'
package com.zimche.audit.util

import com.zimche.audit.exception.BadRequestException
import java.util.regex.Pattern

object ValidationUtils {

    private val EMAIL_PATTERN = Pattern.compile(
        "^[A-Za-z0-9+_.-]+@([A-Za-z0-9.-]+\\.[A-Za-z]{2,})$"
    )

    private val PHONE_PATTERN = Pattern.compile(
        "^[+]?[0-9]{10,15}$"
    )

    private val PASSWORD_PATTERN = Pattern.compile(
        "^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*[@#$%^&+=])(?=\\S+$).{8,}$"
    )

    fun validateEmail(email: String): Boolean {
        return EMAIL_PATTERN.matcher(email).matches()
    }

    fun validatePhone(phone: String): Boolean {
        return PHONE_PATTERN.matcher(phone).matches()
    }

    fun validatePassword(password: String): Boolean {
        return password.length >= 6 // Simplified for demo
    }

    fun validateStrongPassword(password: String): Boolean {
        return PASSWORD_PATTERN.matcher(password).matches()
    }

    fun validateRequired(value: String?, fieldName: String) {
        if (value.isNullOrBlank()) {
            throw BadRequestException("$fieldName is required")
        }
    }

    fun validateLength(value: String?, fieldName: String, minLength: Int, maxLength: Int) {
        if (value != null) {
            if (value.length < minLength) {
                throw BadRequestException("$fieldName must be at least $minLength characters long")
            }
            if (value.length > maxLength) {
                throw BadRequestException("$fieldName cannot exceed $maxLength characters")
            }
        }
    }

    fun validatePositive(value: Long?, fieldName: String) {
        if (value != null && value <= 0) {
            throw BadRequestException("$fieldName must be positive")
        }
    }

    fun validateRange(value: Double?, fieldName: String, min: Double, max: Double) {
        if (value != null && (value < min || value > max)) {
            throw BadRequestException("$fieldName must be between $min and $max")
        }
    }

    fun sanitizeInput(input: String?): String? {
        return input?.trim()?.takeIf { it.isNotEmpty() }
    }

    fun validateUniversityCode(code: String): Boolean {
        return code.matches("^[A-Z0-9]{2,10}$".toRegex())
    }

    fun validateFileName(filename: String): Boolean {
        val invalidChars = setOf('<', '>', ':', '"', '|', '?', '*', '\\', '/')
        return filename.isNotEmpty() && filename.none { it in invalidChars }
    }
}
EOF

cat > $UTIL_DIR/DateUtils.kt << 'EOF'
package com.zimche.audit.util

import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

object DateUtils {

    val DEFAULT_FORMATTER: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")
    val DATE_FORMATTER: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
    val TIME_FORMATTER: DateTimeFormatter = DateTimeFormatter.ofPattern("HH:mm:ss")
    val DISPLAY_FORMATTER: DateTimeFormatter = DateTimeFormatter.ofPattern("MMM dd, yyyy 'at' HH:mm")

    fun formatDateTime(dateTime: LocalDateTime): String {
        return dateTime.format(DEFAULT_FORMATTER)
    }

    fun formatDate(dateTime: LocalDateTime): String {
        return dateTime.format(DATE_FORMATTER)
    }

    fun formatTime(dateTime: LocalDateTime): String {
        return dateTime.format(TIME_FORMATTER)
    }

    fun formatForDisplay(dateTime: LocalDateTime): String {
        return dateTime.format(DISPLAY_FORMATTER)
    }

    fun getTimeAgo(dateTime: LocalDateTime): String {
        val now = LocalDateTime.now()
        val minutes = ChronoUnit.MINUTES.between(dateTime, now)
        val hours = ChronoUnit.HOURS.between(dateTime, now)
        val days = ChronoUnit.DAYS.between(dateTime, now)

        return when {
            minutes < 1 -> "Just now"
            minutes < 60 -> "$minutes minute${if (minutes != 1L) "s" else ""} ago"
            hours < 24 -> "$hours hour${if (hours != 1L) "s" else ""} ago"
            days < 7 -> "$days day${if (days != 1L) "s" else ""} ago"
            days < 30 -> "${days / 7} week${if (days / 7 != 1L) "s" else ""} ago"
            days < 365 -> "${days / 30} month${if (days / 30 != 1L) "s" else ""} ago"
            else -> "${days / 365} year${if (days / 365 != 1L) "s" else ""} ago"
        }
    }

    fun isToday(dateTime: LocalDateTime): Boolean {
        val today = LocalDateTime.now()
        return dateTime.toLocalDate() == today.toLocalDate()
    }

    fun isThisWeek(dateTime: LocalDateTime): Boolean {
        val now = LocalDateTime.now()
        val weekStart = now.minusDays(now.dayOfWeek.value - 1L)
        val weekEnd = weekStart.plusDays(6)
        return dateTime.isAfter(weekStart) && dateTime.isBefore(weekEnd)
    }

    fun isThisMonth(dateTime: LocalDateTime): Boolean {
        val now = LocalDateTime.now()
        return dateTime.year == now.year && dateTime.month == now.month
    }

    fun addBusinessDays(startDate: LocalDateTime, businessDays: Int): LocalDateTime {
        var result = startDate
        var daysToAdd = businessDays

        while (daysToAdd > 0) {
            result = result.plusDays(1)
            // Skip weekends (Saturday = 6, Sunday = 7)
            if (result.dayOfWeek.value < 6) {
                daysToAdd--
            }
        }

        return result
    }

    fun getStartOfDay(dateTime: LocalDateTime): LocalDateTime {
        return dateTime.withHour(0).withMinute(0).withSecond(0).withNano(0)
    }

    fun getEndOfDay(dateTime: LocalDateTime): LocalDateTime {
        return dateTime.withHour(23).withMinute(59).withSecond(59).withNano(999999999)
    }

    fun getStartOfWeek(dateTime: LocalDateTime): LocalDateTime {
        return dateTime.minusDays(dateTime.dayOfWeek.value - 1L)
            .withHour(0).withMinute(0).withSecond(0).withNano(0)
    }

    fun getEndOfWeek(dateTime: LocalDateTime): LocalDateTime {
        return dateTime.plusDays(7L - dateTime.dayOfWeek.value)
            .withHour(23).withMinute(59).withSecond(59).withNano(999999999)
    }

    fun getStartOfMonth(dateTime: LocalDateTime): LocalDateTime {
        return dateTime.withDayOfMonth(1)
            .withHour(0).withMinute(0).withSecond(0).withNano(0)
    }

    fun getEndOfMonth(dateTime: LocalDateTime): LocalDateTime {
        return dateTime.withDayOfMonth(dateTime.toLocalDate().lengthOfMonth())
            .withHour(23).withMinute(59).withSecond(59).withNano(999999999)
    }

    fun calculateBusinessDays(startDate: LocalDateTime, endDate: LocalDateTime): Int {
        var start = startDate.toLocalDate()
        val end = endDate.toLocalDate()
        var businessDays = 0

        while (!start.isAfter(end)) {
            // Skip weekends
            if (start.dayOfWeek.value < 6) {
                businessDays++
            }
            start = start.plusDays(1)
        }

        return businessDays
    }
}
EOF

cat > $UTIL_DIR/SecurityUtils.kt << 'EOF'
package com.zimche.audit.util

import com.zimche.audit.security.UserPrincipal
import org.springframework.security.core.context.SecurityContextHolder
import java.security.SecureRandom
import java.util.*

object SecurityUtils {

    private val random = SecureRandom()

    fun getCurrentUserPrincipal(): UserPrincipal? {
        val authentication = SecurityContextHolder.getContext().authentication
        return if (authentication?.principal is UserPrincipal) {
            authentication.principal as UserPrincipal
        } else null
    }

    fun getCurrentUserId(): Long? {
        return getCurrentUserPrincipal()?.id
    }

    fun getCurrentUserEmail(): String? {
        return getCurrentUserPrincipal()?.email
    }

    fun getCurrentUniversityId(): Long? {
        return getCurrentUserPrincipal()?.universityId
    }

    fun hasRole(role: String): Boolean {
        val principal = getCurrentUserPrincipal()
        return principal?.authorities?.any { it.authority == "ROLE_$role" } ?: false
    }

    fun isAdmin(): Boolean {
        return hasRole("ADMIN")
    }

    fun isUniversityStaff(): Boolean {
        return hasRole("UNIVERSITY_STAFF")
    }

    fun isPeerReviewer(): Boolean {
        return hasRole("PEER_REVIEWER")
    }

    fun isSuperUser(): Boolean {
        return hasRole("SUPER_USER")
    }

    fun canAccessUniversity(universityId: Long): Boolean {
        return isAdmin() || getCurrentUniversityId() == universityId
    }

    fun generateRandomPassword(length: Int = 12): String {
        val chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
        return (1..length)
            .map { chars[random.nextInt(chars.length)] }
            .joinToString("")
    }

    fun generateRandomToken(length: Int = 32): String {
        val bytes = ByteArray(length)
        random.nextBytes(bytes)
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes)
    }

    fun maskEmail(email: String): String {
        val atIndex = email.indexOf('@')
        return if (atIndex > 2) {
            email.substring(0, 2) + "*".repeat(atIndex - 2) + email.substring(atIndex)
        } else {
            email
        }
    }

    fun isValidIPAddress(ip: String): Boolean {
        val parts = ip.split(".")
        if (parts.size != 4) return false
        
        return parts.all { part ->
            try {
                val num = part.toInt()
                num in 0..255
            } catch (e: NumberFormatException) {
                false
            }
        }
    }

    fun sanitizeForLog(input: String): String {
        // Remove potential log injection characters
        return input.replace("[\r\n\t]".toRegex(), "_")
    }
}
EOF

cat > $UTIL_DIR/PerformanceUtils.kt << 'EOF'
package com.zimche.audit.util

import org.slf4j.LoggerFactory

object PerformanceUtils {

    private val logger = LoggerFactory.getLogger(PerformanceUtils::class.java)

    inline fun <T> measureTime(operation: String, block: () -> T): T {
        val startTime = System.currentTimeMillis()
        return try {
            block()
        } finally {
            val duration = System.currentTimeMillis() - startTime
            logger.debug("Operation '$operation' took ${duration}ms")
        }
    }

    inline fun <T> measureTimeWithResult(operation: String, block: () -> T): Pair<T, Long> {
        val startTime = System.currentTimeMillis()
        val result = block()
        val duration = System.currentTimeMillis() - startTime
        logger.debug("Operation '$operation' took ${duration}ms")
        return Pair(result, duration)
    }

    fun logMemoryUsage(operation: String) {
        val runtime = Runtime.getRuntime()
        val totalMemory = runtime.totalMemory()
        val freeMemory = runtime.freeMemory()
        val usedMemory = totalMemory - freeMemory
        val maxMemory = runtime.maxMemory()
        
        logger.debug(
            "Memory usage after '$operation': Used=${formatBytes(usedMemory)}, " +
            "Free=${formatBytes(freeMemory)}, Total=${formatBytes(totalMemory)}, " +
            "Max=${formatBytes(maxMemory)}"
        )
    }

    private fun formatBytes(bytes: Long): String {
        val mb = bytes / (1024 * 1024)
        return "${mb}MB"
    }

    class PerformanceTracker(private val operation: String) {
        private val startTime = System.currentTimeMillis()
        private var lastCheckpoint = startTime
        
        fun checkpoint(label: String) {
            val now = System.currentTimeMillis()
            val fromStart = now - startTime
            val fromLast = now - lastCheckpoint
            logger.debug("$operation - $label: +${fromLast}ms (total: ${fromStart}ms)")
            lastCheckpoint = now
        }
        
        fun finish(): Long {
            val duration = System.currentTimeMillis() - startTime
            logger.debug("$operation completed in ${duration}ms")
            return duration
        }
    }
}
EOF

cat > $UTIL_DIR/JsonUtils.kt << 'EOF'
package com.zimche.audit.util

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.fasterxml.jackson.module.kotlin.readValue

object JsonUtils {

    private val objectMapper: ObjectMapper = jacksonObjectMapper()

    fun <T> toJson(obj: T): String {
        return objectMapper.writeValueAsString(obj)
    }

    inline fun <reified T> fromJson(json: String): T {
        return objectMapper.readValue(json)
    }

    fun <T> fromJson(json: String, clazz: Class<T>): T {
        return objectMapper.readValue(json, clazz)
    }

    fun isValidJson(json: String): Boolean {
        return try {
            objectMapper.readTree(json)
            true
        } catch (e: Exception) {
            false
        }
    }

    fun prettifyJson(json: String): String {
        return try {
            val jsonNode = objectMapper.readTree(json)
            objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(jsonNode)
        } catch (e: Exception) {
            json
        }
    }

    fun minifyJson(json: String): String {
        return try {
            val jsonNode = objectMapper.readTree(json)
            objectMapper.writeValueAsString(jsonNode)
        } catch (e: Exception) {
            json
        }
    }
}
EOF

# Create a final script to complete remaining controllers
cat > scripts/generate-remaining-controllers.sh << 'EOF'
#!/bin/bash

# Generate remaining controller classes

BASE_DIR="src/main/kotlin/com/zimche/audit"
CONTROLLER_DIR="$BASE_DIR/controller"

echo "🎮 Generating remaining Controller classes..."

cat > $CONTROLLER_DIR/AIController.kt << 'EOF'
package com.zimche.audit.controller

import com.zimche.audit.dto.response.AIAnalysisResponse
import com.zimche.audit.dto.response.ApiResponse
import com.zimche.audit.security.UserPrincipal
import com.zimche.audit.service.AIService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/ai")
@Tag(name = "AI Analysis", description = "AI-powered document analysis endpoints")
class AIController(
    private val aiService: AIService
) {

    @PostMapping("/analyze/{documentId}")
    @PreAuthorize("hasRole('PEER_REVIEWER') or hasRole('ADMIN')")
    @Operation(summary = "Analyze document", description = "Perform AI analysis on document")
    fun analyzeDocument(
        @PathVariable documentId: Long,
        @RequestParam analysisType: String,
        @AuthenticationPrincipal userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<AIAnalysisResponse>> {
        val analysis = aiService.analyzeDocument(documentId, analysisType, userPrincipal.email)
        return ResponseEntity.ok(ApiResponse.success(analysis, "Analysis completed successfully"))
    }

    @GetMapping("/analyses/{documentId}")
    @Operation(summary = "Get document analyses", description = "Get all AI analyses for a document")
    fun getDocumentAnalyses(@PathVariable documentId: Long): ResponseEntity<ApiResponse<List<AIAnalysisResponse>>> {
        val analyses = aiService.getDocumentAnalyses(documentId)
        return ResponseEntity.ok(ApiResponse.success(analyses))
    }

    @GetMapping("/stats")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Get AI statistics", description = "Get AI usage statistics")
    fun getAIStats(): ResponseEntity<ApiResponse<Map<String, Any>>> {
        val stats = aiService.getAnalysisStats()
        return ResponseEntity.ok(ApiResponse.success(stats))
    }
}
EOF

cat > $CONTROLLER_DIR/MessagingController.kt << 'EOF'
package com.zimche.audit.controller

import com.zimche.audit.dto.request.MessageRequest
import com.zimche.audit.dto.response.ApiResponse
import com.zimche.audit.dto.response.MessageResponse
import com.zimche.audit.enums.MessageType
import com.zimche.audit.security.UserPrincipal
import com.zimche.audit.service.MessagingService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.data.domain.Page
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Sort
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/messages")
@Tag(name = "Messages", description = "Internal messaging endpoints")
class MessagingController(
    private val messagingService: MessagingService
) {

    @PostMapping
    @Operation(summary = "Send message", description = "Send a message to another user")
    fun sendMessage(
        @Valid @RequestBody request: MessageRequest,
        @AuthenticationPrincipal userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<MessageResponse>> {
        val message = messagingService.sendMessage(request, userPrincipal.email)
        return ResponseEntity.ok(ApiResponse.success(message, "Message sent successfully"))
    }

    @GetMapping
    @Operation(summary = "Get messages", description = "Get user messages with filters")
    fun getMessages(
        @RequestParam(required = false) type: MessageType?,
        @RequestParam(required = false) isRead: Boolean?,
        @RequestParam(required = false) search: String?,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "10") size: Int,
        @RequestParam(defaultValue = "createdAt") sortBy: String,
        @RequestParam(defaultValue = "desc") sortDir: String,
        @AuthenticationPrincipal userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<Page<MessageResponse>>> {
        val direction = if (sortDir.lowercase() == "desc") Sort.Direction.DESC else Sort.Direction.ASC
        val pageable = PageRequest.of(page, size, Sort.by(direction, sortBy))
        val messages = messagingService.getMessagesForUser(userPrincipal.email, type, isRead, search, pageable)
        return ResponseEntity.ok(ApiResponse.success(messages))
    }

    @GetMapping("/conversation")
    @Operation(summary = "Get conversation", description = "Get conversation with another user")
    fun getConversation(
        @RequestParam(required = false) otherUserId: Long?,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int,
        @AuthenticationPrincipal userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<Page<MessageResponse>>> {
        val pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"))
        val conversation = messagingService.getConversation(userPrincipal.email, otherUserId, pageable)
        return ResponseEntity.ok(ApiResponse.success(conversation))
    }

    @PutMapping("/{id}/read")
    @Operation(summary = "Mark message as read", description = "Mark a message as read")
    fun markAsRead(
        @PathVariable id: Long,
        @AuthenticationPrincipal userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<MessageResponse>> {
        val message = messagingService.markMessageAsRead(id, userPrincipal.email)
        return ResponseEntity.ok(ApiResponse.success(message, "Message marked as read"))
    }

    @PutMapping("/read-all")
    @Operation(summary = "Mark all messages as read", description = "Mark all user messages as read")
    fun markAllAsRead(@AuthenticationPrincipal userPrincipal: UserPrincipal): ResponseEntity<ApiResponse<Unit>> {
        messagingService.markAllMessagesAsRead(userPrincipal.email)
        return ResponseEntity.ok(ApiResponse.success(message = "All messages marked as read"))
    }

    @GetMapping("/unread-count")
    @Operation(summary = "Get unread message count", description = "Get count of unread messages")
    fun getUnreadCount(@AuthenticationPrincipal userPrincipal: UserPrincipal): ResponseEntity<ApiResponse<Long>> {
        val count = messagingService.getUnreadMessageCount(userPrincipal.email)
        return ResponseEntity.ok(ApiResponse.success(count))
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete message", description = "Delete a message")
    fun deleteMessage(
        @PathVariable id: Long,
        @AuthenticationPrincipal userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<Unit>> {
        messagingService.deleteMessage(id, userPrincipal.email)
        return ResponseEntity.ok(ApiResponse.success(message = "Message deleted successfully"))
    }
}
EOF

echo "✅ Remaining controller classes generated successfully!"
EOF

chmod +x scripts/generate-remaining-controllers.sh

echo "✅ Utility classes and exceptions generated successfully!"
echo "Generated files:"
echo "  Exception Classes:"
echo "    - GlobalExceptionHandler"
echo "    - ResourceNotFoundException"
echo "    - BadRequestException"
echo "    - UnauthorizedException"
echo ""
echo "  Utility Classes:"
echo "    - FileUtils (file validation and manipulation)"
echo "    - ValidationUtils (input validation)"
echo "    - DateUtils (date/time utilities)"
echo "    - SecurityUtils (security-related utilities)"
echo "    - PerformanceUtils (performance monitoring)"
echo "    - JsonUtils (JSON serialization utilities)"
echo ""
echo "  Additional script created:"
echo "    - scripts/generate-remaining-controllers.sh"