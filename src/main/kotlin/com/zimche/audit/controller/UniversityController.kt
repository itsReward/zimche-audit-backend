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
