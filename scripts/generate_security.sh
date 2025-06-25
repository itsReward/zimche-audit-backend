#!/bin/bash

# Generate Security Classes for ZIMCHE Audit System

BASE_DIR="src/main/kotlin/com/zimche/audit"
SECURITY_DIR="$BASE_DIR/security"

echo "🔐 Generating Security classes..."

mkdir -p $SECURITY_DIR

cat > $SECURITY_DIR/JwtTokenProvider.kt << 'EOF'
package com.zimche.audit.security

import io.jsonwebtoken.Claims
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.SignatureAlgorithm
import io.jsonwebtoken.security.Keys
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Component
import java.util.*
import javax.crypto.SecretKey

@Component
class JwtTokenProvider(
    @Value("\${app.jwt.secret}") private val jwtSecret: String,
    @Value("\${app.jwt.expiration}") private val jwtExpiration: Long
) {

    private val secretKey: SecretKey by lazy {
        Keys.hmacShaKeyFor(jwtSecret.toByteArray())
    }

    fun generateToken(email: String): String {
        val now = Date()
        val expiryDate = Date(now.time + jwtExpiration)

        return Jwts.builder()
            .setSubject(email)
            .setIssuedAt(now)
            .setExpiration(expiryDate)
            .signWith(secretKey, SignatureAlgorithm.HS512)
            .compact()
    }

    fun generatePasswordResetToken(email: String): String {
        val now = Date()
        val expiryDate = Date(now.time + 3600000) // 1 hour

        return Jwts.builder()
            .setSubject(email)
            .setIssuedAt(now)
            .setExpiration(expiryDate)
            .claim("type", "password-reset")
            .signWith(secretKey, SignatureAlgorithm.HS512)
            .compact()
    }

    fun getEmailFromToken(token: String): String {
        val claims = getAllClaimsFromToken(token)
        return claims.subject
    }

    fun validateToken(token: String): Boolean {
        return try {
            getAllClaimsFromToken(token)
            true
        } catch (e: Exception) {
            false
        }
    }

    fun isTokenExpired(token: String): Boolean {
        return try {
            val claims = getAllClaimsFromToken(token)
            claims.expiration.before(Date())
        } catch (e: Exception) {
            true
        }
    }

    private fun getAllClaimsFromToken(token: String): Claims {
        return Jwts.parserBuilder()
            .setSigningKey(secretKey)
            .build()
            .parseClaimsJws(token)
            .body
    }
}
EOF

cat > $SECURITY_DIR/JwtAuthenticationFilter.kt << 'EOF'
package com.zimche.audit.security

import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource
import org.springframework.stereotype.Component
import org.springframework.web.filter.OncePerRequestFilter

@Component
class JwtAuthenticationFilter(
    private val jwtTokenProvider: JwtTokenProvider,
    private val customUserDetailsService: CustomUserDetailsService
) : OncePerRequestFilter() {

    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        filterChain: FilterChain
    ) {
        try {
            val token = getTokenFromRequest(request)
            
            if (token != null && jwtTokenProvider.validateToken(token)) {
                val email = jwtTokenProvider.getEmailFromToken(token)
                val userDetails = customUserDetailsService.loadUserByUsername(email)
                
                val authentication = UsernamePasswordAuthenticationToken(
                    userDetails, null, userDetails.authorities
                )
                authentication.details = WebAuthenticationDetailsSource().buildDetails(request)
                
                SecurityContextHolder.getContext().authentication = authentication
            }
        } catch (e: Exception) {
            logger.error("Cannot set user authentication: {}", e.message)
        }
        
        filterChain.doFilter(request, response)
    }

    private fun getTokenFromRequest(request: HttpServletRequest): String? {
        val bearerToken = request.getHeader("Authorization")
        return if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            bearerToken.substring(7)
        } else null
    }
}
EOF

cat > $SECURITY_DIR/CustomUserDetailsService.kt << 'EOF'
package com.zimche.audit.security

import com.zimche.audit.repository.UserRepository
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.security.core.userdetails.UserDetailsService
import org.springframework.security.core.userdetails.UsernameNotFoundException
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional
class CustomUserDetailsService(
    private val userRepository: UserRepository
) : UserDetailsService {

    override fun loadUserByUsername(email: String): UserDetails {
        val user = userRepository.findByEmail(email)
            .orElseThrow { UsernameNotFoundException("User not found with email: $email") }
        
        return UserPrincipal.create(user)
    }

    fun loadUserById(id: Long): UserDetails {
        val user = userRepository.findById(id)
            .orElseThrow { UsernameNotFoundException("User not found with id: $id") }
        
        return UserPrincipal.create(user)
    }
}
EOF

cat > $SECURITY_DIR/UserPrincipal.kt << 'EOF'
package com.zimche.audit.security

import com.zimche.audit.entity.User
import org.springframework.security.core.GrantedAuthority
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.security.core.userdetails.UserDetails

data class UserPrincipal(
    val id: Long,
    val email: String,
    private val password: String,
    val fullName: String,
    val universityId: Long?,
    private val authorities: Collection<GrantedAuthority>,
    private val isActive: Boolean
) : UserDetails {

    override fun getAuthorities(): Collection<GrantedAuthority> = authorities

    override fun getPassword(): String = password

    override fun getUsername(): String = email

    override fun isAccountNonExpired(): Boolean = true

    override fun isAccountNonLocked(): Boolean = true

    override fun isCredentialsNonExpired(): Boolean = true

    override fun isEnabled(): Boolean = isActive

    companion object {
        fun create(user: User): UserPrincipal {
            val authorities = listOf(SimpleGrantedAuthority("ROLE_${user.role.name}"))
            
            return UserPrincipal(
                id = user.id,
                email = user.email,
                password = user.password,
                fullName = user.fullName,
                universityId = user.university?.id,
                authorities = authorities,
                isActive = user.isActive
            )
        }
    }
}
EOF

echo "✅ Security classes generated successfully!"
echo "Generated files:"
echo "  - JwtTokenProvider (JWT token generation and validation)"
echo "  - JwtAuthenticationFilter (JWT authentication filter)"
echo "  - CustomUserDetailsService (Spring Security UserDetailsService)"
echo "  - UserPrincipal (Spring Security UserDetails implementation)"