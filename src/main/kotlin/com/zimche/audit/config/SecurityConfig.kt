package com.zimche.audit.config

import com.zimche.audit.security.CustomUserDetailsService
import com.zimche.audit.security.JwtAuthenticationFilter
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.core.annotation.Order
import org.springframework.security.authentication.AuthenticationManager
import org.springframework.security.authentication.dao.DaoAuthenticationProvider
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity
import org.springframework.security.config.http.SessionCreationPolicy
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.security.web.SecurityFilterChain
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter
import org.springframework.security.web.util.matcher.AntPathRequestMatcher

@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
class SecurityConfig(
    private val customUserDetailsService: CustomUserDetailsService,
    private val jwtAuthenticationFilter: JwtAuthenticationFilter
) {

    @Bean
    fun passwordEncoder(): PasswordEncoder = BCryptPasswordEncoder()

    @Bean
    fun authenticationProvider(): DaoAuthenticationProvider {
        val authProvider = DaoAuthenticationProvider()
        authProvider.setUserDetailsService(customUserDetailsService)
        authProvider.setPasswordEncoder(passwordEncoder())
        return authProvider
    }

    @Bean
    fun authenticationManager(authConfig: AuthenticationConfiguration): AuthenticationManager {
        return authConfig.authenticationManager
    }

    // API Security Configuration (JWT)
    @Bean
    @Order(1)
    fun apiFilterChain(http: HttpSecurity): SecurityFilterChain {
        http.securityMatcher("/api/**")
            .csrf { it.disable() }
            .sessionManagement { it.sessionCreationPolicy(SessionCreationPolicy.STATELESS) }
            .authorizeHttpRequests { authz ->
                authz
                    // Public API endpoints
                    .requestMatchers(
                        "/api/auth/**",
                        "/actuator/health",
                        "/swagger-ui/**",
                        "/v3/api-docs/**",
                        "/swagger-resources/**",
                        "/webjars/**"
                    ).permitAll()

                    // Admin only endpoints
                    .requestMatchers(
                        "/api/admin/**",
                        "/api/users/*/role",
                        "/api/universities"
                    ).hasRole("ADMIN")

                    // University staff can access their own university data
                    .requestMatchers("/api/documents/upload").hasAnyRole("UNIVERSITY_STAFF", "ADMIN")

                    // Peer reviewers can review documents
                    .requestMatchers("/api/documents/*/status").hasAnyRole("PEER_REVIEWER", "ADMIN")

                    // AI analysis requires appropriate roles
                    .requestMatchers("/api/ai/**").hasAnyRole("PEER_REVIEWER", "ADMIN")

                    // All other API requests require authentication
                    .anyRequest().authenticated()
            }
            .authenticationProvider(authenticationProvider())
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter::class.java)

        return http.build()
    }

    // Web UI Security Configuration (Session-based)
    @Bean
    @Order(2)
    fun webFilterChain(http: HttpSecurity): SecurityFilterChain {
        http.securityMatcher("/**")
            .authorizeHttpRequests { authz ->
                authz
                    // Public web resources
                    .requestMatchers(
                        "/",
                        "/login",
                        "/register",
                        "/css/**",
                        "/js/**",
                        "/images/**",
                        "/favicon.ico",
                        "/error"
                    ).permitAll()

                    // Admin web pages
                    .requestMatchers("/admin/**").hasRole("ADMIN")

                    // University staff web pages
                    .requestMatchers("/university/**").hasAnyRole("UNIVERSITY_STAFF", "ADMIN")

                    // Peer reviewer web pages
                    .requestMatchers("/reviewer/**").hasAnyRole("PEER_REVIEWER", "ADMIN")

                    // All other web requests require authentication
                    .anyRequest().authenticated()
            }
            .formLogin { form ->
                form
                    .loginPage("/login")
                    .defaultSuccessUrl("/dashboard", true)
                    .failureUrl("/login?error=true")
                    .permitAll()
            }
            .logout { logout ->
                logout
                    .logoutRequestMatcher(AntPathRequestMatcher("/logout"))
                    .logoutSuccessUrl("/login?logout=true")
                    .invalidateHttpSession(true)
                    .deleteCookies("JSESSIONID")
                    .permitAll()
            }
            .sessionManagement { session ->
                session
                    .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)
                    .maximumSessions(1)
                    .maxSessionsPreventsLogin(false)
            }
            .authenticationProvider(authenticationProvider())

        return http.build()
    }
}