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
