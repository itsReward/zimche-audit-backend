#!/bin/bash

# Generate Exception Classes for ZIMCHE Audit System

BASE_DIR="src/main/kotlin/com/zimche/audit"
EXCEPTION_DIR="$BASE_DIR/exception"

echo "⚠️  Generating Exception classes..."

mkdir -p $EXCEPTION_DIR

# Custom Exception Classes
cat > $EXCEPTION_DIR/ResourceNotFoundException.kt << 'EOF'
package com.zimche.audit.exception

/**
 * Exception thrown when a requested resource is not found
 */
class ResourceNotFoundException(message: String) : RuntimeException(message) {
    constructor(resource: String, id: Any) : this("$resource not found with id: $id")
    constructor(resource: String, field: String, value: Any) : this("$resource not found with $field: $value")
}
EOF

cat > $EXCEPTION_DIR/BadRequestException.kt << 'EOF'
package com.zimche.audit.exception

/**
 * Exception thrown when a request is malformed or contains invalid data
 */
class BadRequestException(message: String) : RuntimeException(message) {
    constructor(field: String, value: Any?, reason: String) : this("Invalid $field '$value': $reason")
}
EOF

cat > $EXCEPTION_DIR/UnauthorizedException.kt << 'EOF'
package com.zimche.audit.exception

/**
 * Exception thrown when a user is not authenticated or token is invalid
 */
class UnauthorizedException(message: String = "Authentication required") : RuntimeException(message)
EOF

cat > $EXCEPTION_DIR/ForbiddenException.kt << 'EOF'
package com.zimche.audit.exception

/**
 * Exception thrown when a user lacks permission to access a resource
 */
class ForbiddenException(message: String = "Access denied") : RuntimeException(message) {
    constructor(action: String, resource: String) : this("Permission denied to $action $resource")
}
EOF

cat > $EXCEPTION_DIR/ConflictException.kt << 'EOF'
package com.zimche.audit.exception

/**
 * Exception thrown when there's a conflict with the current state of the resource
 */
class ConflictException(message: String) : RuntimeException(message) {
    constructor(resource: String, field: String, value: Any) : this("$resource with $field '$value' already exists")
}
EOF

cat > $EXCEPTION_DIR/ValidationException.kt << 'EOF'
package com.zimche.audit.exception

/**
 * Exception thrown when business validation rules are violated
 */
class ValidationException(
    message: String,
    val field: String? = null,
    val code: String? = null
) : RuntimeException(message) {
    
    constructor(field: String, message: String) : this(message, field)
    constructor(field: String, message: String, code: String) : this(message, field, code)
}
EOF

cat > $EXCEPTION_DIR/ServiceException.kt << 'EOF'
package com.zimche.audit.exception

/**
 * Exception thrown when an external service fails or is unavailable
 */
class ServiceException(
    message: String,
    val service: String,
    cause: Throwable? = null
) : RuntimeException(message, cause) {
    
    constructor(service: String, operation: String, cause: Throwable) : 
        this("$service service failed during $operation: ${cause.message}", service, cause)
}
EOF

cat > $EXCEPTION_DIR/FileStorageException.kt << 'EOF'
package com.zimche.audit.exception

/**
 * Exception thrown when file storage operations fail
 */
class FileStorageException(
    message: String,
    val operation: String? = null,
    cause: Throwable? = null
) : RuntimeException(message, cause) {
    
    constructor(operation: String, filename: String, cause: Throwable) : 
        this("Failed to $operation file '$filename': ${cause.message}", operation, cause)
}
EOF

cat > $EXCEPTION_DIR/AIServiceException.kt << 'EOF'
package com.zimche.audit.exception

/**
 * Exception thrown when AI service operations fail
 */
class AIServiceException(
    message: String,
    val analysisType: String? = null,
    val documentId: Long? = null,
    cause: Throwable? = null
) : RuntimeException(message, cause) {
    
    constructor(analysisType: String, documentId: Long, cause: Throwable) : 
        this("AI analysis '$analysisType' failed for document $documentId: ${cause.message}", analysisType, documentId, cause)
}
EOF

cat > $EXCEPTION_DIR/EmailException.kt << 'EOF'
package com.zimche.audit.exception

/**
 * Exception thrown when email operations fail
 */
class EmailException(
    message: String,
    val recipient: String? = null,
    val emailType: String? = null,
    cause: Throwable? = null
) : RuntimeException(message, cause) {
    
    constructor(emailType: String, recipient: String, cause: Throwable) : 
        this("Failed to send $emailType email to $recipient: ${cause.message}", recipient, emailType, cause)
}
EOF

cat > $EXCEPTION_DIR/AuditException.kt << 'EOF'
package com.zimche.audit.exception

/**
 * Exception thrown when audit operations fail or are in invalid state
 */
class AuditException(
    message: String,
    val auditId: Long? = null,
    val auditStatus: String? = null
) : RuntimeException(message) {
    
    constructor(operation: String, auditId: Long, currentStatus: String) : 
        this("Cannot $operation audit $auditId in status $currentStatus", auditId, currentStatus)
}
EOF

cat > $EXCEPTION_DIR/DocumentProcessingException.kt << 'EOF'
package com.zimche.audit.exception

/**
 * Exception thrown when document processing fails
 */
class DocumentProcessingException(
    message: String,
    val documentId: Long? = null,
    val processingStep: String? = null,
    cause: Throwable? = null
) : RuntimeException(message, cause) {
    
    constructor(processingStep: String, documentId: Long, cause: Throwable) : 
        this("Document processing failed at step '$processingStep' for document $documentId: ${cause.message}", 
             documentId, processingStep, cause)
}
EOF

cat > $EXCEPTION_DIR/RateLimitException.kt << 'EOF'
package com.zimche.audit.exception

/**
 * Exception thrown when rate limits are exceeded
 */
class RateLimitException(
    message: String = "Rate limit exceeded",
    val retryAfterSeconds: Long? = null
) : RuntimeException(message) {
    
    constructor(operation: String, retryAfterSeconds: Long) : 
        this("Rate limit exceeded for $operation. Try again in $retryAfterSeconds seconds", retryAfterSeconds)
}
EOF

# Global Exception Handler
cat > $EXCEPTION_DIR/GlobalExceptionHandler.kt << 'EOF'
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
        val response = ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
            .apply {
                if (ex.retryAfterSeconds != null) {
                    header("Retry-After", ex.retryAfterSeconds.toString())
                }
            }
            .body(ApiResponse.error(ex.message ?: "Rate limit exceeded"))
        return response
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
EOF

echo "✅ Exception classes generated successfully!"
echo "Generated files:"
echo "  Custom Exceptions:"
echo "    - ResourceNotFoundException"
echo "    - BadRequestException"
echo "    - UnauthorizedException"
echo "    - ForbiddenException"
echo "    - ConflictException"
echo "    - ValidationException"
echo "    - ServiceException"
echo "    - FileStorageException"
echo "    - AIServiceException"
echo "    - EmailException"
echo "    - AuditException"
echo "    - DocumentProcessingException"
echo "    - RateLimitException"
echo ""
echo "  Exception Handler:"
echo "    - GlobalExceptionHandler (comprehensive error handling)"
echo ""
echo "Features included:"
echo "  ✅ HTTP status code mapping"
echo "  ✅ Structured error responses"
echo "  ✅ Security exception handling"
echo "  ✅ Validation error formatting"
echo "  ✅ Detailed logging with user context"
echo "  ✅ Rate limiting support"
echo "  ✅ File upload error handling"
echo "  ✅ Service-specific exceptions"