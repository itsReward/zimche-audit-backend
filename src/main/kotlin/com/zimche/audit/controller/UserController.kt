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
