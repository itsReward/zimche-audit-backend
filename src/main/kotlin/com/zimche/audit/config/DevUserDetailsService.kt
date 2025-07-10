package com.zimche.audit.config

import org.springframework.security.core.userdetails.User
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.security.core.userdetails.UserDetailsService
import org.springframework.security.core.userdetails.UsernameNotFoundException
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.beans.factory.annotation.Autowired

@Service
class DevUserDetailsService @Autowired constructor(
    private val passwordEncoder: PasswordEncoder
) : UserDetailsService {

    override fun loadUserByUsername(username: String): UserDetails {
        // For development - create some test users
        // In production, this should load from your User entity/repository

        return when (username.lowercase()) {
            "admin@zimche.ac.zw", "admin" -> {
                User.builder()
                    .username(username)
                    .password(passwordEncoder.encode("admin123"))
                    .roles("ADMIN", "USER")
                    .build()
            }
            "user@zimche.ac.zw", "user" -> {
                User.builder()
                    .username(username)
                    .password(passwordEncoder.encode("user123"))
                    .roles("USER")
                    .build()
            }
            "test@zimche.ac.zw", "test" -> {
                User.builder()
                    .username(username)
                    .password(passwordEncoder.encode("test123"))
                    .roles("USER")
                    .build()
            }
            else -> throw UsernameNotFoundException("User not found: $username")
        }
    }
}
