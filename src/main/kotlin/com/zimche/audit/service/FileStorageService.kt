package com.zimche.audit.service

import com.zimche.audit.exception.BadRequestException
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import org.springframework.web.multipart.MultipartFile
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider
import software.amazon.awssdk.core.sync.RequestBody
import software.amazon.awssdk.regions.Region
import software.amazon.awssdk.services.s3.S3Client
import software.amazon.awssdk.services.s3.model.*
import software.amazon.awssdk.services.s3.presigner.S3Presigner
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest
import java.time.Duration
import java.util.*

@Service
class FileStorageService(
    @Value("\${app.aws.access-key}") private val accessKey: String,
    @Value("\${app.aws.secret-key}") private val secretKey: String,
    @Value("\${app.aws.region}") private val region: String,
    @Value("\${app.aws.s3-bucket}") private val bucketName: String
) {

    private val s3Client: S3Client by lazy {
        val credentials = AwsBasicCredentials.create(accessKey, secretKey)
        S3Client.builder()
            .region(Region.of(region))
            .credentialsProvider(StaticCredentialsProvider.create(credentials))
            .build()
    }

    private val s3Presigner: S3Presigner by lazy {
        val credentials = AwsBasicCredentials.create(accessKey, secretKey)
        S3Presigner.builder()
            .region(Region.of(region))
            .credentialsProvider(StaticCredentialsProvider.create(credentials))
            .build()
    }

    fun uploadFile(file: MultipartFile, folder: String): String {
        try {
            val fileName = generateUniqueFileName(file.originalFilename ?: "file")
            val key = "$folder/$fileName"

            val putObjectRequest = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .contentType(file.contentType)
                .contentLength(file.size)
                .build()

            s3Client.putObject(putObjectRequest, RequestBody.fromInputStream(file.inputStream, file.size))

            return "https://$bucketName.s3.$region.amazonaws.com/$key"
        } catch (e: Exception) {
            throw BadRequestException("Failed to upload file: ${e.message}")
        }
    }

    fun deleteFile(fileUrl: String) {
        try {
            val key = extractKeyFromUrl(fileUrl)
            val deleteObjectRequest = DeleteObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .build()

            s3Client.deleteObject(deleteObjectRequest)
        } catch (e: Exception) {
            // Log error but don't throw exception to avoid breaking document deletion
            println("Failed to delete file from S3: ${e.message}")
        }
    }

    fun generateDownloadUrl(fileUrl: String): String {
        return try {
            val key = extractKeyFromUrl(fileUrl)
            val getObjectRequest = GetObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .build()

            val presignRequest = GetObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(60)) // URL valid for 1 hour
                .getObjectRequest(getObjectRequest)
                .build()

            s3Presigner.presignGetObject(presignRequest).url().toString()
        } catch (e: Exception) {
            throw BadRequestException("Failed to generate download URL: ${e.message}")
        }
    }

    private fun generateUniqueFileName(originalFileName: String): String {
        val timestamp = System.currentTimeMillis()
        val uuid = UUID.randomUUID().toString().substring(0, 8)
        val extension = originalFileName.substringAfterLast(".", "")
        val name = originalFileName.substringBeforeLast(".")
            .replace(" ", "_")
            .replace("[^a-zA-Z0-9._-]".toRegex(), "")

        return if (extension.isNotEmpty()) {
            "${name}_${timestamp}_${uuid}.$extension"
        } else {
            "${name}_${timestamp}_${uuid}"
        }
    }

    private fun extractKeyFromUrl(fileUrl: String): String {
        // Extract key from S3 URL format: https://bucket.s3.region.amazonaws.com/key
        return fileUrl.substringAfter("amazonaws.com/")
    }
}
