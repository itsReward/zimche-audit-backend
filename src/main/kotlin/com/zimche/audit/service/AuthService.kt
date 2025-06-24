package com.zimche.audit.service

import com.zimche.audit.dto.request.LoginRequest
import com.zimche.audit.dto.request.RegisterRequest
import com.zimche.audit.dto.response.AuthResponse
import com.zimche.audit.entity.User
import com.zimche.audit.enums.UserRole
import com.zimche.audit.exception.BadRequestException
import com.zimche.audit.exception.UnauthorizedException
import com.zimche.audit.repository.UserRepository
import com.zimche.audit.security.JwtTokenProvider
import org.springframework.security.authentication.AuthenticationManager
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional
class AuthService(
    private val userRepository: UserRepository,
    private val passwordEncoder: PasswordEncoder,
    private val authenticationManager: AuthenticationManager,
    private val jwtTokenProvider: JwtTokenProvider,
    private val universityService: UniversityService,
    private val emailService: EmailService
) {

    fun login(loginRequest: LoginRequest): AuthResponse {
        try {
            authenticationManager.authenticate(
                UsernamePasswordAuthenticationToken(
                    loginRequest.email,
                    loginRequest.password
                )
            )
        } catch (e: Exception) {
            throw UnauthorizedException("Invalid email or password")
        }

        val user = userRepository.findByEmail(loginRequest.email)
            .orElseThrow { UnauthorizedException("User not found") }

        if (!user.isActive) {
            throw UnauthorizedException("Account is deactivated")
        }

        val token = jwtTokenProvider.generateToken(user.email)

        return AuthResponse(
            token = token,
            type = "Bearer",
            email = user.email,
            role = user.role.name,
            fullName = user.fullName,
            universityId = user.university?.id
        )
    }

    fun register(registerRequest: RegisterRequest): AuthResponse {
        if (userRepository.existsByEmail(registerRequest.email)) {
            throw BadRequestException("Email is already registered")
        }

        val university = registerRequest.universityId?.let {
            universityService.findById(it)
        }

        val user = User(
            email = registerRequest.email,
            password = passwordEncoder.encode(registerRequest.password),
            firstName = registerRequest.firstName,
            lastName = registerRequest.lastName,
            role = registerRequest.role ?: UserRole.UNIVERSITY_STAFF,
            phoneNumber = registerRequest.phoneNumber,
            university = university
        )

        val savedUser = userRepository.save(user)

        // Send welcome email
        emailService.sendWelcomeEmail(savedUser)

        val token = jwtTokenProvider.generateToken(savedUser.email)

        return AuthResponse(
            token = token,
            type = "Bearer",
            email = savedUser.email,
            role = savedUser.role.name,
            fullName = savedUser.fullName,
            universityId = savedUser.university?.id
        )
    }

    fun getCurrentUser(email: String): User {
        return userRepository.findByEmail(email)
            .orElseThrow { UnauthorizedException("User not found") }
    }

    fun changePassword(email: String, oldPassword: String, newPassword: String) {
        val user = getCurrentUser(email)

        if (!passwordEncoder.matches(oldPassword, user.password)) {
            throw BadRequestException("Current password is incorrect")
        }

        val updatedUser = user.copy(password = passwordEncoder.encode(newPassword))
        userRepository.save(updatedUser)
    }

    fun forgotPassword(email: String) {
        val user = userRepository.findByEmail(email)
            .orElseThrow { BadRequestException("Email not found") }

        // Generate reset token and send email
        val resetToken = jwtTokenProvider.generatePasswordResetToken(email)
        emailService.sendPasswordResetEmail(user, resetToken)
    }

    fun resetPassword(token: String, newPassword: String) {
        val email = jwtTokenProvider.getEmailFromToken(token)
        if (!jwtTokenProvider.validateToken(token)) {
            throw BadRequestException("Invalid or expired reset token")
        }

        val user = getCurrentUser(email)
        val updatedUser = user.copy(password = passwordEncoder.encode(newPassword))
        userRepository.save(updatedUser)
    }
}
