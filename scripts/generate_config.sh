#!/bin/bash

# Generate Configuration Classes for ZIMCHE Audit System

BASE_DIR="src/main/kotlin/com/zimche/audit"
CONFIG_DIR="$BASE_DIR/config"

echo "⚙️  Generating Configuration classes..."

mkdir -p $CONFIG_DIR

cat > $CONFIG_DIR/SecurityConfig.kt << 'EOF'
package com.zimche.audit.config

import com.zimche.audit.security.CustomUserDetailsService
import com.zimche.audit.security.JwtAuthenticationFilter
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
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

    @Bean
    fun filterChain(http: HttpSecurity): SecurityFilterChain {
        http.csrf { it.disable() }
            .sessionManagement { it.sessionCreationPolicy(SessionCreationPolicy.STATELESS) }
            .authorizeHttpRequests { authz ->
                authz
                    // Public endpoints
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
                    
                    // All other requests require authentication
                    .anyRequest().authenticated()
            }
            .authenticationProvider(authenticationProvider())
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter::class.java)

        return http.build()
    }
}
EOF

cat > $CONFIG_DIR/CorsConfig.kt << 'EOF'
package com.zimche.audit.config

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.cors.CorsConfiguration
import org.springframework.web.cors.CorsConfigurationSource
import org.springframework.web.cors.UrlBasedCorsConfigurationSource

@Configuration
class CorsConfig {

    @Bean
    fun corsConfigurationSource(): CorsConfigurationSource {
        val configuration = CorsConfiguration().apply {
            allowedOriginPatterns = listOf("*") // For development - restrict in production
            allowedMethods = listOf("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH")
            allowedHeaders = listOf("*")
            allowCredentials = true
            maxAge = 3600L
        }

        val source = UrlBasedCorsConfigurationSource()
        source.registerCorsConfiguration("/**", configuration)
        return source
    }
}
EOF

cat > $CONFIG_DIR/OpenAIConfig.kt << 'EOF'
package com.zimche.audit.config

import com.theokanning.openai.service.OpenAiService
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import java.time.Duration

@Configuration
class OpenAIConfig(
    @Value("\${app.openai.api-key}") private val apiKey: String
) {

    @Bean
    fun openAiService(): OpenAiService {
        return OpenAiService(apiKey, Duration.ofSeconds(60))
    }
}
EOF

cat > $CONFIG_DIR/DatabaseConfig.kt << 'EOF'
package com.zimche.audit.config

import org.springframework.context.annotation.Configuration
import org.springframework.data.jpa.repository.config.EnableJpaAuditing
import org.springframework.data.jpa.repository.config.EnableJpaRepositories
import org.springframework.transaction.annotation.EnableTransactionManagement

@Configuration
@EnableJpaRepositories(basePackages = ["com.zimche.audit.repository"])
@EnableJpaAuditing
@EnableTransactionManagement
class DatabaseConfig
EOF

cat > $CONFIG_DIR/AsyncConfig.kt << 'EOF'
package com.zimche.audit.config

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.scheduling.annotation.EnableAsync
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor
import java.util.concurrent.Executor

@Configuration
@EnableAsync
class AsyncConfig {

    @Bean(name = ["taskExecutor"])
    fun taskExecutor(): Executor {
        val executor = ThreadPoolTaskExecutor()
        executor.corePoolSize = 5
        executor.maxPoolSize = 10
        executor.queueCapacity = 25
        executor.setThreadNamePrefix("Async-")
        executor.initialize()
        return executor
    }

    @Bean(name = ["aiExecutor"])
    fun aiExecutor(): Executor {
        val executor = ThreadPoolTaskExecutor()
        executor.corePoolSize = 2
        executor.maxPoolSize = 5
        executor.queueCapacity = 100
        executor.setThreadNamePrefix("AI-")
        executor.initialize()
        return executor
    }
}
EOF

cat > $CONFIG_DIR/SwaggerConfig.kt << 'EOF'
package com.zimche.audit.config

import io.swagger.v3.oas.models.Components
import io.swagger.v3.oas.models.OpenAPI
import io.swagger.v3.oas.models.info.Contact
import io.swagger.v3.oas.models.info.Info
import io.swagger.v3.oas.models.info.License
import io.swagger.v3.oas.models.security.SecurityRequirement
import io.swagger.v3.oas.models.security.SecurityScheme
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration
class SwaggerConfig {

    @Bean
    fun openAPI(): OpenAPI {
        return OpenAPI()
            .info(
                Info()
                    .title("ZIMCHE University Audit Management API")
                    .description("REST API for ZIMCHE University Audit Management System")
                    .version("1.0.0")
                    .contact(
                        Contact()
                            .name("ZIMCHE Development Team")
                            .email("dev@zimche.ac.zw")
                    )
                    .license(
                        License()
                            .name("MIT License")
                            .url("https://opensource.org/licenses/MIT")
                    )
            )
            .addSecurityItem(SecurityRequirement().addList("Bearer Authentication"))
            .components(
                Components()
                    .addSecuritySchemes(
                        "Bearer Authentication",
                        SecurityScheme()
                            .type(SecurityScheme.Type.HTTP)
                            .scheme("bearer")
                            .bearerFormat("JWT")
                            .description("Enter JWT token")
                    )
            )
    }
}
EOF

cat > $CONFIG_DIR/WebConfig.kt << 'EOF'
package com.zimche.audit.config

import org.springframework.context.annotation.Configuration
import org.springframework.web.servlet.config.annotation.CorsRegistry
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer

@Configuration
class WebConfig : WebMvcConfigurer {

    override fun addCorsMappings(registry: CorsRegistry) {
        registry.addMapping("/api/**")
            .allowedOriginPatterns("*")
            .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH")
            .allowedHeaders("*")
            .allowCredentials(true)
            .maxAge(3600)
    }
}
EOF

echo "✅ Configuration classes generated successfully!"
echo "Generated files:"
echo "  - SecurityConfig (Spring Security configuration)"
echo "  - CorsConfig (CORS configuration)"
echo "  - OpenAIConfig (OpenAI service configuration)"
echo "  - DatabaseConfig (JPA configuration)"
echo "  - AsyncConfig (Async processing configuration)"
echo "  - SwaggerConfig (API documentation configuration)"
echo "  - WebConfig (Web MVC configuration)"