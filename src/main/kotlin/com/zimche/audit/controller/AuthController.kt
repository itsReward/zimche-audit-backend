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
