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
