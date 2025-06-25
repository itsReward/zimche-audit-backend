package com.zimche.audit.exception

import com.zimche.audit.dto.response.ApiResponse
import com.zimche.audit.dto.response.ValidationErrorResponse
import com.zimche.audit.util.SecurityUtils
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.http.converter.HttpMessageNotReadableException
import org.springframework.security.access.AccessDeniedException
import org.springframework.security.authentication.BadCredentialsException
import org.springframework.security.core.AuthenticationException
import org.springframework.validation.FieldError
import org.springframework.web.HttpRequestMethodNotSupportedException
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.MissingServletRequestParameterException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice
import org.springframework.web.context.request.WebRequest
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException
import org.springframework.web.multipart.MaxUploadSizeExceededException
import org.springframework.web.servlet.NoHandlerFoundException
import java.time.LocalDateTime

@RestControllerAdvice
class GlobalExceptionHandler {

    private val logger = LoggerFactory.getLogger(GlobalExceptionHandler::class.java)

    @ExceptionHandler(ResourceNotFoundException::class)
    fun handleResourceNotFound(
        ex: ResourceNotFoundException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("ResourceNotFound", ex, request)
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(ApiResponse.error(ex.message ?: "Resource not found"))
    }

    @ExceptionHandler(BadRequestException::class)
    fun handleBadRequest(
        ex: BadRequestException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("BadRequest", ex, request)
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(ApiResponse.error(ex.message ?: "Bad request"))
    }

    @ExceptionHandler(UnauthorizedException::class)
    fun handleUnauthorized(
        ex: UnauthorizedException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("Unauthorized", ex, request)
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
            .body(ApiResponse.error(ex.message ?: "Authentication required"))
    }

    @ExceptionHandler(ForbiddenException::class)
    fun handleForbidden(
        ex: ForbiddenException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("Forbidden", ex, request)
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
            .body(ApiResponse.error(ex.message ?: "Access denied"))
    }

    @ExceptionHandler(ConflictException::class)
    fun handleConflict(
        ex: ConflictException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("Conflict", ex, request)
        return ResponseEntity.status(HttpStatus.CONFLICT)
            .body(ApiResponse.error(ex.message ?: "Resource conflict"))
    }

    @ExceptionHandler(ValidationException::class)
    fun handleValidation(
        ex: ValidationException,
        request: WebRequest
    ): ResponseEntity<ValidationErrorResponse> {
        logException("Validation", ex, request)
        val errors = if (ex.field != null) {
            mapOf(ex.field to (ex.message ?: "Validation failed"))
        } else {
            mapOf("general" to (ex.message ?: "Validation failed"))
        }
        
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(ValidationErrorResponse(message = "Validation failed", errors = errors))
    }

    @ExceptionHandler(ServiceException::class)
    fun handleServiceException(
        ex: ServiceException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("Service", ex, request)
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
            .body(ApiResponse.error("Service temporarily unavailable: ${ex.service}"))
    }

    @ExceptionHandler(FileStorageException::class)
    fun handleFileStorage(
        ex: FileStorageException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("FileStorage", ex, request)
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(ApiResponse.error("File operation failed: ${ex.operation}"))
    }

    @ExceptionHandler(AIServiceException::class)
    fun handleAIService(
        ex: AIServiceException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("AIService", ex, request)
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
            .body(ApiResponse.error("AI analysis service temporarily unavailable"))
    }

    @ExceptionHandler(EmailException::class)
    fun handleEmail(
        ex: EmailException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("Email", ex, request)
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(ApiResponse.error("Email service error"))
    }

    @ExceptionHandler(AuditException::class)
    fun handleAudit(
        ex: AuditException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("Audit", ex, request)
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(ApiResponse.error(ex.message ?: "Audit operation failed"))
    }

    @ExceptionHandler(DocumentProcessingException::class)
    fun handleDocumentProcessing(
        ex: DocumentProcessingException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("DocumentProcessing", ex, request)
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(ApiResponse.error("Document processing failed"))
    }

    @ExceptionHandler(RateLimitException::class)
    fun handleRateLimit(
        ex: RateLimitException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("RateLimit", ex, request)

        val responseBuilder = ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
        if (ex.retryAfterSeconds != null) {
            responseBuilder.header("Retry-After", ex.retryAfterSeconds.toString())
        }

        return responseBuilder.body(ApiResponse.error<Nothing>(ex.message ?: "Rate limit exceeded"))
    }

    // Spring Security Exceptions
    @ExceptionHandler(AccessDeniedException::class)
    fun handleAccessDenied(
        ex: AccessDeniedException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("AccessDenied", ex, request)
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
            .body(ApiResponse.error("Access denied"))
    }

    @ExceptionHandler(AuthenticationException::class)
    fun handleAuthentication(
        ex: AuthenticationException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("Authentication", ex, request)
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
            .body(ApiResponse.error("Authentication failed"))
    }

    @ExceptionHandler(BadCredentialsException::class)
    fun handleBadCredentials(
        ex: BadCredentialsException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("BadCredentials", ex, request)
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
            .body(ApiResponse.error("Invalid credentials"))
    }

    // Validation Exceptions
    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidationErrors(
        ex: MethodArgumentNotValidException,
        request: WebRequest
    ): ResponseEntity<ValidationErrorResponse> {
        logException("MethodArgumentNotValid", ex, request)
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

    @ExceptionHandler(MethodArgumentTypeMismatchException::class)
    fun handleTypeMismatch(
        ex: MethodArgumentTypeMismatchException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("TypeMismatch", ex, request)
        val message = "Invalid parameter '${ex.name}': expected ${ex.requiredType?.simpleName}"
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(ApiResponse.error(message))
    }

    @ExceptionHandler(MissingServletRequestParameterException::class)
    fun handleMissingParameter(
        ex: MissingServletRequestParameterException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("MissingParameter", ex, request)
        val message = "Required parameter '${ex.parameterName}' is missing"
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(ApiResponse.error(message))
    }

    @ExceptionHandler(HttpMessageNotReadableException::class)
    fun handleMessageNotReadable(
        ex: HttpMessageNotReadableException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("MessageNotReadable", ex, request)
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(ApiResponse.error("Invalid request body"))
    }

    // HTTP Method Exceptions
    @ExceptionHandler(HttpRequestMethodNotSupportedException::class)
    fun handleMethodNotSupported(
        ex: HttpRequestMethodNotSupportedException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("MethodNotSupported", ex, request)
        val message = "HTTP method '${ex.method}' not supported. Supported methods: ${ex.supportedMethods?.joinToString()}"
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED)
            .body(ApiResponse.error(message))
    }

    @ExceptionHandler(NoHandlerFoundException::class)
    fun handleNoHandlerFound(
        ex: NoHandlerFoundException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("NoHandlerFound", ex, request)
        val message = "Endpoint '${ex.httpMethod} ${ex.requestURL}' not found"
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(ApiResponse.error(message))
    }

    // File Upload Exceptions
    @ExceptionHandler(MaxUploadSizeExceededException::class)
    fun handleMaxUploadSizeExceeded(
        ex: MaxUploadSizeExceededException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("MaxUploadSizeExceeded", ex, request)
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(ApiResponse.error("File size exceeds maximum allowed size"))
    }

    // Generic Exceptions
    @ExceptionHandler(IllegalArgumentException::class)
    fun handleIllegalArgument(
        ex: IllegalArgumentException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("IllegalArgument", ex, request)
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(ApiResponse.error(ex.message ?: "Invalid argument"))
    }

    @ExceptionHandler(IllegalStateException::class)
    fun handleIllegalState(
        ex: IllegalStateException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("IllegalState", ex, request)
        return ResponseEntity.status(HttpStatus.CONFLICT)
            .body(ApiResponse.error(ex.message ?: "Invalid operation state"))
    }

    @ExceptionHandler(Exception::class)
    fun handleGenericException(
        ex: Exception,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logException("Generic", ex, request, true)
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(ApiResponse.error("An unexpected error occurred"))
    }

    private fun logException(
        type: String, 
        ex: Exception, 
        request: WebRequest, 
        includeStackTrace: Boolean = false
    ) {
        val userId = SecurityUtils.getCurrentUserId()
        val userEmail = SecurityUtils.getCurrentUserEmail()
        val path = request.getDescription(false)
        
        val logMessage = "Exception[$type] - User: $userEmail ($userId), Path: $path, Message: ${ex.message}"
        
        if (includeStackTrace) {
            logger.error(SecurityUtils.sanitizeForLog(logMessage), ex)
        } else {
            logger.warn(SecurityUtils.sanitizeForLog(logMessage))
        }
    }
}
