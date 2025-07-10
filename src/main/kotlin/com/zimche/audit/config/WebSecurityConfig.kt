package com.zimche.audit.config
/*

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.security.authentication.AuthenticationManager
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity
import org.springframework.security.config.http.SessionCreationPolicy
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.security.web.SecurityFilterChain

@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
class WebSecurityConfig (
    private val passwordEncoder: PasswordEncoder,
    private val authenticationManager: AuthenticationManager
){
    @Bean
    fun securityFilterChain(http: HttpSecurity): SecurityFilterChain {
        http
            .authorizeHttpRequests { auth ->
                auth
                    // Public static resources
                    .requestMatchers(
                        "/css/**", "/js/**", "/images/**", "/static/**",
                        "/favicon.ico", "/error", "/webjars/**"
                    ).permitAll()
                    // Public web pages
                    .requestMatchers("/", "/home", "/login", "/register", "/public-test", "/debug").permitAll()
                    // Public API endpoints (if JWT classes exist, they'll handle API auth separately)
                    .requestMatchers("/api/auth/**", "/api/public/**").permitAll()
                    // Documentation endpoints
                    .requestMatchers("/swagger-ui/**", "/v3/api-docs/**", "/actuator/**").permitAll()
                    // Protected web pages - require authentication
                    .requestMatchers("/dashboard", "/universities/**", "/documents/**",
                                   "/audits/**", "/messages/**", "/profile/**").authenticated()
                    // Admin pages - require ADMIN role
                    .requestMatchers("/admin/**").hasRole("ADMIN")
                    // For now, allow API access (we'll secure it later when JWT is working)
                    .requestMatchers("/api/**").permitAll()
                    // All other requests require authentication
                    .anyRequest().authenticated()
            }
            .formLogin { form ->
                form
                    .loginPage("/login")
                    .loginProcessingUrl("/perform-login")
                    .usernameParameter("email")
                    .passwordParameter("password")
                    .defaultSuccessUrl("/dashboard", true)
                    .failureUrl("/login?error=true")
                    .permitAll()
            }
            .logout { logout ->
                logout
                    .logoutUrl("/logout")
                    .logoutSuccessUrl("/login?logout=true")
                    .invalidateHttpSession(true)
                    .deleteCookies("JSESSIONID")
                    .permitAll()
            }
            .sessionManagement { session ->
                session
                    .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)
                    .maximumSessions(5)
                    .maxSessionsPreventsLogin(false)
            }
            .csrf { csrf ->
                csrf.disable() // Disable CSRF for simplicity in development
            }

        return http.build()
    }
}
*/