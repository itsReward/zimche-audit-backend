package com.zimche.audit.util

import com.zimche.audit.exception.BadRequestException
import org.springframework.web.multipart.MultipartFile
import java.util.*

object FileUtils {

    private val ALLOWED_EXTENSIONS = setOf("pdf", "doc", "docx", "txt", "xlsx", "xls", "ppt", "pptx")
    private val MAX_FILE_SIZE = 50 * 1024 * 1024L // 50MB

    fun validateFile(file: MultipartFile) {
        if (file.isEmpty) {
            throw BadRequestException("File cannot be empty")
        }

        if (file.size > MAX_FILE_SIZE) {
            throw BadRequestException("File size cannot exceed ${MAX_FILE_SIZE / (1024 * 1024)}MB")
        }

        val extension = getFileExtension(file.originalFilename ?: "")
        if (extension !in ALLOWED_EXTENSIONS) {
            throw BadRequestException("File type not allowed. Allowed types: ${ALLOWED_EXTENSIONS.joinToString(", ")}")
        }
    }

    fun getFileExtension(filename: String): String {
        return filename.substringAfterLast(".", "").lowercase()
    }

    fun generateUniqueFileName(originalFilename: String): String {
        val timestamp = System.currentTimeMillis()
        val uuid = UUID.randomUUID().toString().substring(0, 8)
        val extension = getFileExtension(originalFilename)
        val name = originalFilename.substringBeforeLast(".")
            .replace(" ", "_")
            .replace("[^a-zA-Z0-9._-]".toRegex(), "")
            .take(50) // Limit name length

        return if (extension.isNotEmpty()) {
            "${name}_${timestamp}_${uuid}.${extension}"
        } else {
            "${name}_${timestamp}_${uuid}"
        }
    }

    fun formatFileSize(sizeInBytes: Long): String {
        val units = arrayOf("B", "KB", "MB", "GB", "TB")
        var size = sizeInBytes.toDouble()
        var unitIndex = 0

        while (size >= 1024 && unitIndex < units.size - 1) {
            size /= 1024
            unitIndex++
        }

        return String.format("%.2f %s", size, units[unitIndex])
    }

    fun isImageFile(filename: String): Boolean {
        val imageExtensions = setOf("jpg", "jpeg", "png", "gif", "bmp", "webp")
        return getFileExtension(filename) in imageExtensions
    }

    fun isDocumentFile(filename: String): Boolean {
        val documentExtensions = setOf("pdf", "doc", "docx", "txt", "rtf")
        return getFileExtension(filename) in documentExtensions
    }

    fun isSpreadsheetFile(filename: String): Boolean {
        val spreadsheetExtensions = setOf("xlsx", "xls", "csv")
        return getFileExtension(filename) in spreadsheetExtensions
    }

    fun isPresentationFile(filename: String): Boolean {
        val presentationExtensions = setOf("ppt", "pptx")
        return getFileExtension(filename) in presentationExtensions
    }
}
