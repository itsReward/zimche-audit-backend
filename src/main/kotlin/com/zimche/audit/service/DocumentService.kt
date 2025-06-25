package com.zimche.audit.service

import com.zimche.audit.dto.response.DocumentResponse
import com.zimche.audit.entity.Document
import com.zimche.audit.enums.DocumentStatus
import com.zimche.audit.exception.BadRequestException
import com.zimche.audit.exception.ResourceNotFoundException
import com.zimche.audit.repository.DocumentRepository
import com.zimche.audit.repository.UserRepository
import com.zimche.audit.repository.UniversityRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.multipart.MultipartFile
import java.time.LocalDateTime

@Service
@Transactional
class DocumentService(
    private val documentRepository: DocumentRepository,
    private val userRepository: UserRepository,
    private val universityRepository: UniversityRepository,
    private val fileStorageService: FileStorageService,
    private val emailService: EmailService
) {

    fun findById(id: Long): Document {
        return documentRepository.findById(id)
            .orElseThrow { ResourceNotFoundException("Document not found with id: $id") }
    }

    @Transactional(readOnly = true)
    fun getAllDocuments(pageable: Pageable): Page<DocumentResponse> {
        return documentRepository.findAll(pageable).map { DocumentResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun searchDocuments(
        universityId: Long?,
        status: DocumentStatus?,
        uploadedById: Long?,
        search: String?,
        pageable: Pageable
    ): Page<DocumentResponse> {
        return documentRepository.findDocumentsWithFilters(
            universityId, status, uploadedById, search, pageable
        ).map { DocumentResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun getDocumentsByUniversity(universityId: Long, pageable: Pageable): Page<DocumentResponse> {
        return documentRepository.findByUniversityId(universityId, pageable)
            .map { DocumentResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun getDocumentsByStatus(status: DocumentStatus): List<DocumentResponse> {
        return documentRepository.findByStatus(status).map { DocumentResponse.from(it) }
    }

    fun uploadDocument(
        file: MultipartFile,
        title: String,
        description: String?,
        universityId: Long,
        userEmail: String
    ): DocumentResponse {
        val user = userRepository.findByEmail(userEmail)
            .orElseThrow { ResourceNotFoundException("User not found with email: $userEmail") }
        val university = universityRepository.findById(universityId)
            .orElseThrow { ResourceNotFoundException("University not found with id: $universityId") }

        // Validate file
        if (file.isEmpty) {
            throw BadRequestException("File cannot be empty")
        }

        val maxFileSize = 50 * 1024 * 1024 // 50MB
        if (file.size > maxFileSize) {
            throw BadRequestException("File size cannot exceed 50MB")
        }

        // Upload file to storage
        val fileUrl = fileStorageService.uploadFile(file, "documents")

        val document = Document(
            title = title,
            fileName = file.originalFilename ?: "unknown",
            fileUrl = fileUrl,
            fileSize = file.size,
            contentType = file.contentType,
            description = description,
            university = university,
            uploadedBy = user
        )

        val savedDocument = documentRepository.save(document)

        // Notify document uploaded - will be implemented by MessagingService
        // messagingService.notifyDocumentUploaded(savedDocument)

        return DocumentResponse.from(savedDocument)
    }

    fun updateDocumentStatus(
        documentId: Long,
        status: DocumentStatus,
        reviewComments: String?,
        reviewerEmail: String
    ): DocumentResponse {
        val document = findById(documentId)
        val reviewer = userRepository.findByEmail(reviewerEmail)
            .orElseThrow { ResourceNotFoundException("Reviewer not found with email: $reviewerEmail") }

        val updatedDocument = document.copy(
            status = status,
            reviewedBy = reviewer,
            reviewedAt = LocalDateTime.now(),
            reviewComments = reviewComments
        )

        val savedDocument = documentRepository.save(updatedDocument)

        // Send notification to uploader - will be implemented by MessagingService
        // messagingService.notifyDocumentStatusChanged(savedDocument)

        return DocumentResponse.from(savedDocument)
    }

    fun updateDocument(
        documentId: Long,
        title: String?,
        description: String?,
        userEmail: String
    ): DocumentResponse {
        val document = findById(documentId)
        val user = userRepository.findByEmail(userEmail)
            .orElseThrow { ResourceNotFoundException("User not found with email: $userEmail") }

        // Check if user has permission to update
        if (document.uploadedBy.id != user.id && user.role.name != "ADMIN") {
            throw BadRequestException("You don't have permission to update this document")
        }

        val updatedDocument = document.copy(
            title = title ?: document.title,
            description = description ?: document.description
        )

        return DocumentResponse.from(documentRepository.save(updatedDocument))
    }

    fun deleteDocument(documentId: Long, userEmail: String) {
        val document = findById(documentId)
        val user = userRepository.findByEmail(userEmail)
            .orElseThrow { ResourceNotFoundException("User not found with email: $userEmail") }

        // Check if user has permission to delete
        if (document.uploadedBy.id != user.id && user.role.name != "ADMIN") {
            throw BadRequestException("You don't have permission to delete this document")
        }

        // Delete file from storage
        fileStorageService.deleteFile(document.fileUrl)

        // Delete document record
        documentRepository.delete(document)
    }

    @Transactional(readOnly = true)
    fun getDocumentWithAnalyses(documentId: Long): Document {
        return documentRepository.findByIdWithAnalyses(documentId)
            ?: throw ResourceNotFoundException("Document not found with id: $documentId")
    }

    @Transactional(readOnly = true)
    fun downloadDocument(documentId: Long, userEmail: String): String {
        val document = findById(documentId)
        val user = userRepository.findByEmail(userEmail)
            .orElseThrow { ResourceNotFoundException("User not found with email: $userEmail") }

        // Check access permissions based on user role and university
        when (user.role) {
            com.zimche.audit.enums.UserRole.ADMIN,
            com.zimche.audit.enums.UserRole.PEER_REVIEWER -> {
                // Admins and reviewers can access all documents
            }
            com.zimche.audit.enums.UserRole.UNIVERSITY_STAFF -> {
                // University staff can only access their university's documents
                if (document.university.id != user.university?.id) {
                    throw BadRequestException("You don't have permission to access this document")
                }
            }
            else -> throw BadRequestException("You don't have permission to access this document")
        }

        return fileStorageService.generateDownloadUrl(document.fileUrl)
    }

    @Transactional(readOnly = true)
    fun getDocumentStats(): Map<String, Any> {
        val totalDocuments = documentRepository.count()
        val documentsByStatus = DocumentStatus.values().associate { status ->
            status.name to documentRepository.countByStatus(status)
        }

        return mapOf(
            "totalDocuments" to totalDocuments,
            "documentsByStatus" to documentsByStatus
        )
    }

    @Transactional(readOnly = true)
    fun getUniversityDocumentStats(universityId: Long): Map<String, Any> {
        val totalDocuments = documentRepository.countByUniversityId(universityId)
        val totalFileSize = documentRepository.getTotalFileSizeByUniversity(universityId) ?: 0L

        return mapOf(
            "totalDocuments" to totalDocuments,
            "totalFileSize" to totalFileSize
        )
    }
}
