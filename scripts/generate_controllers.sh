#!/bin/bash

# Generate Controller Classes for ZIMCHE Audit System

BASE_DIR="src/main/kotlin/com/zimche/audit"
CONTROLLER_DIR="$BASE_DIR/controller"

echo "🎮 Generating Controller classes..."

mkdir -p $CONTROLLER_DIR

cat > $CONTROLLER_DIR/AuthController.kt << 'EOF'
package com.zimche.audit.controller

import com.zimche.audit.dto.request.LoginRequest
import com.zimche.audit.dto.request.PasswordChangeRequest
import com.zimche.audit.dto.request.RegisterRequest
import com.zimche.audit.dto.response.ApiResponse
import com.zimche.audit.dto.response.AuthResponse
import com.zimche.audit.dto.response.UserResponse
import com.zimche.audit.security.UserPrincipal
import com.zimche.audit.service.AuthService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/auth")
@Tag(name = "Authentication", description = "Authentication endpoints")
class AuthController(
    private val authService: AuthService
) {

    @PostMapping("/login")
    @Operation(summary = "User login", description = "Authenticate user and return JWT token")
    fun login(@Valid @RequestBody loginRequest: LoginRequest): ResponseEntity<ApiResponse<AuthResponse>> {
        val authResponse = authService.login(loginRequest)
        return ResponseEntity.ok(ApiResponse.success(authResponse, "Login successful"))
    }

    @PostMapping("/register")
    @Operation(summary = "User registration", description = "Register a new user")
    fun register(@Valid @RequestBody registerRequest: RegisterRequest): ResponseEntity<ApiResponse<AuthResponse>> {
        val authResponse = authService.register(registerRequest)
        return ResponseEntity.ok(ApiResponse.success(authResponse, "Registration successful"))
    }

    @GetMapping("/me")
    @Operation(summary = "Get current user", description = "Get current authenticated user details")
    fun getCurrentUser(@AuthenticationPrincipal userPrincipal: UserPrincipal): ResponseEntity<ApiResponse<UserResponse>> {
        val user = authService.getCurrentUser(userPrincipal.email)
        return ResponseEntity.ok(ApiResponse.success(UserResponse.from(user)))
    }

    @PostMapping("/change-password")
    @Operation(summary = "Change password", description = "Change user password")
    fun changePassword(
        @Valid @RequestBody request: PasswordChangeRequest,
        @AuthenticationPrincipal userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<Unit>> {
        authService.changePassword(userPrincipal.email, request.currentPassword, request.newPassword)
        return ResponseEntity.ok(ApiResponse.success(message = "Password changed successfully"))
    }

    @PostMapping("/forgot-password")
    @Operation(summary = "Forgot password", description = "Send password reset email")
    fun forgotPassword(@RequestParam email: String): ResponseEntity<ApiResponse<Unit>> {
        authService.forgotPassword(email)
        return ResponseEntity.ok(ApiResponse.success(message = "Password reset email sent"))
    }

    @PostMapping("/reset-password")
    @Operation(summary = "Reset password", description = "Reset password with token")
    fun resetPassword(
        @RequestParam token: String,
        @RequestParam newPassword: String
    ): ResponseEntity<ApiResponse<Unit>> {
        authService.resetPassword(token, newPassword)
        return ResponseEntity.ok(ApiResponse.success(message = "Password reset successful"))
    }
}
EOF

cat > $CONTROLLER_DIR/UserController.kt << 'EOF'
package com.zimche.audit.controller

import com.zimche.audit.dto.response.ApiResponse
import com.zimche.audit.dto.response.UserResponse
import com.zimche.audit.enums.UserRole
import com.zimche.audit.security.UserPrincipal
import com.zimche.audit.service.UserService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Page
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Sort
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/users")
@Tag(name = "Users", description = "User management endpoints")
class UserController(
    private val userService: UserService
) {

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Get all users", description = "Get paginated list of all users")
    fun getAllUsers(
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "10") size: Int,
        @RequestParam(defaultValue = "createdAt") sortBy: String,
        @RequestParam(defaultValue = "desc") sortDir: String
    ): ResponseEntity<ApiResponse<Page<UserResponse>>> {
        val direction = if (sortDir.lowercase() == "desc") Sort.Direction.DESC else Sort.Direction.ASC
        val pageable = PageRequest.of(page, size, Sort.by(direction, sortBy))
        val users = userService.getAllUsers(pageable)
        return ResponseEntity.ok(ApiResponse.success(users))
    }

    @GetMapping("/search")
    @Operation(summary = "Search users", description = "Search users with filters")
    fun searchUsers(
        @RequestParam(required = false) role: UserRole?,
        @RequestParam(required = false) universityId: Long?,
        @RequestParam(required = false) search: String?,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "10") size: Int,
        @RequestParam(defaultValue = "createdAt") sortBy: String,
        @RequestParam(defaultValue = "desc") sortDir: String
    ): ResponseEntity<ApiResponse<Page<UserResponse>>> {
        val direction = if (sortDir.lowercase() == "desc") Sort.Direction.DESC else Sort.Direction.ASC
        val pageable = PageRequest.of(page, size, Sort.by(direction, sortBy))
        val users = userService.searchUsers(role, universityId, search, pageable)
        return ResponseEntity.ok(ApiResponse.success(users))
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get user by ID", description = "Get user details by ID")
    fun getUserById(@PathVariable id: Long): ResponseEntity<ApiResponse<UserResponse>> {
        val user = userService.findById(id)
        return ResponseEntity.ok(ApiResponse.success(UserResponse.from(user)))
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or #id == authentication.principal.id")
    @Operation(summary = "Update user", description = "Update user details")
    fun updateUser(
        @PathVariable id: Long,
        @RequestParam(required = false) firstName: String?,
        @RequestParam(required = false) lastName: String?,
        @RequestParam(required = false) phoneNumber: String?,
        @RequestParam(required = false) universityId: Long?
    ): ResponseEntity<ApiResponse<UserResponse>> {
        val user = userService.updateUser(id, firstName, lastName, phoneNumber, universityId)
        return ResponseEntity.ok(ApiResponse.success(user, "User updated successfully"))
    }

    @PutMapping("/{id}/role")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Update user role", description = "Update user role (Admin only)")
    fun updateUserRole(
        @PathVariable id: Long,
        @RequestParam role: UserRole
    ): ResponseEntity<ApiResponse<UserResponse>> {
        val user = userService.updateUserRole(id, role)
        return ResponseEntity.ok(ApiResponse.success(user, "User role updated successfully"))
    }

    @PutMapping("/{id}/deactivate")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Deactivate user", description = "Deactivate user account")
    fun deactivateUser(@PathVariable id: Long): ResponseEntity<ApiResponse<UserResponse>> {
        val user = userService.deactivateUser(id)
        return ResponseEntity.ok(ApiResponse.success(user, "User deactivated successfully"))
    }

    @PutMapping("/{id}/activate")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Activate user", description = "Activate user account")
    fun activateUser(@PathVariable id: Long): ResponseEntity<ApiResponse<UserResponse>> {
        val user = userService.activateUser(id)
        return ResponseEntity.ok(ApiResponse.success(user, "User activated successfully"))
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Delete user", description = "Delete user account")
    fun deleteUser(@PathVariable id: Long): ResponseEntity<ApiResponse<Unit>> {
        userService.deleteUser(id)
        return ResponseEntity.ok(ApiResponse.success(message = "User deleted successfully"))
    }

    @GetMapping("/stats")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Get user statistics", description = "Get user statistics")
    fun getUserStats(): ResponseEntity<ApiResponse<Map<String, Any>>> {
        val stats = userService.getUserStats()
        return ResponseEntity.ok(ApiResponse.success(stats))
    }
}
EOF

cat > $CONTROLLER_DIR/DocumentController.kt << 'EOF'
package com.zimche.audit.controller

import com.zimche.audit.dto.request.DocumentUploadRequest
import com.zimche.audit.dto.request.StatusUpdateRequest
import com.zimche.audit.dto.response.ApiResponse
import com.zimche.audit.dto.response.DocumentResponse
import com.zimche.audit.enums.DocumentStatus
import com.zimche.audit.security.UserPrincipal
import com.zimche.audit.service.DocumentService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.data.domain.Page
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Sort
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.*
import org.springframework.web.multipart.MultipartFile

@RestController
@RequestMapping("/api/documents")
@Tag(name = "Documents", description = "Document management endpoints")
class DocumentController(
    private val documentService: DocumentService
) {

    @PostMapping("/upload", consumes = ["multipart/form-data"])
    @PreAuthorize("hasRole('UNIVERSITY_STAFF') or hasRole('ADMIN')")
    @Operation(summary = "Upload document", description = "Upload a new document")
    fun uploadDocument(
        @RequestPart("file") file: MultipartFile,
        @RequestPart("metadata") @Valid request: DocumentUploadRequest,
        @AuthenticationPrincipal userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<DocumentResponse>> {
        val document = documentService.uploadDocument(
            file, request.title, request.description, request.universityId, userPrincipal.email
        )
        return ResponseEntity.ok(ApiResponse.success(document, "Document uploaded successfully"))
    }

    @GetMapping
    @Operation(summary = "Get documents", description = "Get paginated list of documents with filters")
    fun getDocuments(
        @RequestParam(required = false) universityId: Long?,
        @RequestParam(required = false) status: DocumentStatus?,
        @RequestParam(required = false) uploadedById: Long?,
        @RequestParam(required = false) search: String?,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "10") size: Int,
        @RequestParam(defaultValue = "createdAt") sortBy: String,
        @RequestParam(defaultValue = "desc") sortDir: String,
        @AuthenticationPrincipal userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<Page<DocumentResponse>>> {
        val direction = if (sortDir.lowercase() == "desc") Sort.Direction.DESC else Sort.Direction.ASC
        val pageable = PageRequest.of(page, size, Sort.by(direction, sortBy))
        
        // Filter by university for non-admin users
        val filterUniversityId = if (userPrincipal.authorities.any { it.authority == "ROLE_ADMIN" }) {
            universityId
        } else {
            userPrincipal.universityId
        }
        
        val documents = documentService.searchDocuments(filterUniversityId, status, uploadedById, search, pageable)
        return ResponseEntity.ok(ApiResponse.success(documents))
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get document by ID", description = "Get document details by ID")
    fun getDocumentById(@PathVariable id: Long): ResponseEntity<ApiResponse<DocumentResponse>> {
        val document = documentService.findById(id)
        return ResponseEntity.ok(ApiResponse.success(DocumentResponse.from(document)))
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasRole('PEER_REVIEWER') or hasRole('ADMIN')")
    @Operation(summary = "Update document status", description = "Update document review status")
    fun updateDocumentStatus(
        @PathVariable id: Long,
        @Valid @RequestBody request: StatusUpdateRequest,
        @AuthenticationPrincipal userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<DocumentResponse>> {
        val document = documentService.updateDocumentStatus(
            id, request.status, request.comments, userPrincipal.email
        )
        return ResponseEntity.ok(ApiResponse.success(document, "Document status updated successfully"))
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update document", description = "Update document details")
    fun updateDocument(
        @PathVariable id: Long,
        @RequestParam(required = false) title: String?,
        @RequestParam(required = false) description: String?,
        @AuthenticationPrincipal userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<DocumentResponse>> {
        val document = documentService.updateDocument(id, title, description, userPrincipal.email)
        return ResponseEntity.ok(ApiResponse.success(document, "Document updated successfully"))
    }

    @GetMapping("/{id}/download")
    @Operation(summary = "Download document", description = "Get document download URL")
    fun downloadDocument(
        @PathVariable id: Long,
        @AuthenticationPrincipal userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<String>> {
        val downloadUrl = documentService.downloadDocument(id, userPrincipal.email)
        return ResponseEntity.ok(ApiResponse.success(downloadUrl, "Download URL generated"))
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete document", description = "Delete document")
    fun deleteDocument(
        @PathVariable id: Long,
        @AuthenticationPrincipal userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<Unit>> {
        documentService.deleteDocument(id, userPrincipal.email)
        return ResponseEntity.ok(ApiResponse.success(message = "Document deleted successfully"))
    }

    @GetMapping("/stats")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Get document statistics", description = "Get document statistics")
    fun getDocumentStats(): ResponseEntity<ApiResponse<Map<String, Any>>> {
        val stats = documentService.getDocumentStats()
        return ResponseEntity.ok(ApiResponse.success(stats))
    }

    @GetMapping("/university/{universityId}/stats")
    @Operation(summary = "Get university document statistics", description = "Get document statistics for a university")
    fun getUniversityDocumentStats(@PathVariable universityId: Long): ResponseEntity<ApiResponse<Map<String, Any>>> {
        val stats = documentService.getUniversityDocumentStats(universityId)
        return ResponseEntity.ok(ApiResponse.success(stats))
    }
}
EOF

cat > $CONTROLLER_DIR/UniversityController.kt << 'EOF'
package com.zimche.audit.controller

import com.zimche.audit.dto.request.UniversityCreateRequest
import com.zimche.audit.dto.response.ApiResponse
import com.zimche.audit.dto.response.UniversityResponse
import com.zimche.audit.service.UniversityService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.data.domain.Page
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Sort
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/universities")
@Tag(name = "Universities", description = "University management endpoints")
class UniversityController(
    private val universityService: UniversityService
) {

    @GetMapping
    @Operation(summary = "Get all universities", description = "Get paginated list of universities")
    fun getAllUniversities(
        @RequestParam(required = false) search: String?,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "10") size: Int,
        @RequestParam(defaultValue = "name") sortBy: String,
        @RequestParam(defaultValue = "asc") sortDir: String
    ): ResponseEntity<ApiResponse<Page<UniversityResponse>>> {
        val direction = if (sortDir.lowercase() == "desc") Sort.Direction.DESC else Sort.Direction.ASC
        val pageable = PageRequest.of(page, size, Sort.by(direction, sortBy))
        val universities = universityService.searchUniversities(search, pageable)
        return ResponseEntity.ok(ApiResponse.success(universities))
    }

    @GetMapping("/active")
    @Operation(summary = "Get active universities", description = "Get list of active universities")
    fun getActiveUniversities(): ResponseEntity<ApiResponse<List<UniversityResponse>>> {
        val universities = universityService.getActiveUniversities()
        return ResponseEntity.ok(ApiResponse.success(universities))
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get university by ID", description = "Get university details by ID")
    fun getUniversityById(@PathVariable id: Long): ResponseEntity<ApiResponse<UniversityResponse>> {
        val university = universityService.findById(id)
        return ResponseEntity.ok(ApiResponse.success(UniversityResponse.from(university)))
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Create university", description = "Create a new university")
    fun createUniversity(@Valid @RequestBody request: UniversityCreateRequest): ResponseEntity<ApiResponse<UniversityResponse>> {
        val university = universityService.createUniversity(request)
        return ResponseEntity.ok(ApiResponse.success(university, "University created successfully"))
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Update university", description = "Update university details")
    fun updateUniversity(
        @PathVariable id: Long,
        @Valid @RequestBody request: UniversityCreateRequest
    ): ResponseEntity<ApiResponse<UniversityResponse>> {
        val university = universityService.updateUniversity(id, request)
        return ResponseEntity.ok(ApiResponse.success(university, "University updated successfully"))
    }

    @PutMapping("/{id}/deactivate")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Deactivate university", description = "Deactivate university")
    fun deactivateUniversity(@PathVariable id: Long): ResponseEntity<ApiResponse<UniversityResponse>> {
        val university = universityService.deactivateUniversity(id)
        return ResponseEntity.ok(ApiResponse.success(university, "University deactivated successfully"))
    }

    @PutMapping("/{id}/activate")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Activate university", description = "Activate university")
    fun activateUniversity(@PathVariable id: Long): ResponseEntity<ApiResponse<UniversityResponse>> {
        val university = universityService.activateUniversity(id)
        return ResponseEntity.ok(ApiResponse.success(university, "University activated successfully"))
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Delete university", description = "Delete university")
    fun deleteUniversity(@PathVariable id: Long): ResponseEntity<ApiResponse<Unit>> {
        universityService.deleteUniversity(id)
        return ResponseEntity.ok(ApiResponse.success(message = "University deleted successfully"))
    }

    @GetMapping("/stats")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Get university statistics", description = "Get university statistics")
    fun getUniversityStats(): ResponseEntity<ApiResponse<Map<String, Any>>> {
        val stats = universityService.getUniversityStats()
        return ResponseEntity.ok(ApiResponse.success(stats))
    }
}
EOF

echo "✅ Controller classes generated successfully!"
echo "Generated files:"
echo "  - AuthController (Authentication endpoints)"
echo "  - UserController (User management endpoints)"
echo "  - DocumentController (Document management endpoints)"
echo "  - UniversityController (University management endpoints)"