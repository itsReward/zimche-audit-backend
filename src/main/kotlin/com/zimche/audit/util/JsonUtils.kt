package com.zimche.audit.util

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.fasterxml.jackson.module.kotlin.readValue

object JsonUtils {

    val objectMapper: ObjectMapper = jacksonObjectMapper()

    fun <T> toJson(obj: T): String {
        return objectMapper.writeValueAsString(obj)
    }

    inline fun <reified T> fromJson(json: String): T {
        return objectMapper.readValue(json)
    }

    fun <T> fromJson(json: String, clazz: Class<T>): T {
        return objectMapper.readValue(json, clazz)
    }

    fun isValidJson(json: String): Boolean {
        return try {
            objectMapper.readTree(json)
            true
        } catch (e: Exception) {
            false
        }
    }

    fun prettifyJson(json: String): String {
        return try {
            val jsonNode = objectMapper.readTree(json)
            objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(jsonNode)
        } catch (e: Exception) {
            json
        }
    }

    fun minifyJson(json: String): String {
        return try {
            val jsonNode = objectMapper.readTree(json)
            objectMapper.writeValueAsString(jsonNode)
        } catch (e: Exception) {
            json
        }
    }
}
