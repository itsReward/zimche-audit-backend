package com.zimche.audit.service

import com.zimche.audit.dto.request.UniversityCreateRequest
import com.zimche.audit.dto.response.UniversityResponse
import com.zimche.audit.entity.University
import com.zimche.audit.exception.BadRequestException
import com.zimche.audit.exception.ResourceNotFoundException
import com.zimche.audit.repository.UniversityRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional
class UniversityService(
    private val universityRepository: UniversityRepository
) {

    fun findById(id: Long): University {
        return universityRepository.findById(id)
            .orElseThrow { ResourceNotFoundException("University not found with id: $id") }
    }

    fun findByCode(code: String): University {
        return universityRepository.findByCode(code)
            .orElseThrow { ResourceNotFoundException("University not found with code: $code") }
    }

    @Transactional(readOnly = true)
    fun getAllUniversities(pageable: Pageable): Page<UniversityResponse> {
        return universityRepository.findAll(pageable).map { UniversityResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun getActiveUniversities(): List<UniversityResponse> {
        return universityRepository.findByIsActiveTrue().map { UniversityResponse.from(it) }
    }

    @Transactional(readOnly = true)
    fun searchUniversities(search: String?, pageable: Pageable): Page<UniversityResponse> {
        return universityRepository.findUniversitiesWithSearch(search, pageable)
            .map { UniversityResponse.from(it) }
    }

    fun createUniversity(request: UniversityCreateRequest): UniversityResponse {
        if (universityRepository.existsByCode(request.code)) {
            throw BadRequestException("University with code '${request.code}' already exists")
        }

        if (universityRepository.existsByName(request.name)) {
            throw BadRequestException("University with name '${request.name}' already exists")
        }

        val university = University(
            name = request.name,
            code = request.code,
            address = request.address,
            contactEmail = request.contactEmail,
            contactPhone = request.contactPhone,
            website = request.website,
            establishedYear = request.establishedYear
        )

        return UniversityResponse.from(universityRepository.save(university))
    }

    fun updateUniversity(
        id: Long,
        request: UniversityCreateRequest
    ): UniversityResponse {
        val university = findById(id)

        // Check for duplicate code (excluding current university)
        universityRepository.findByCode(request.code).ifPresent { existing ->
            if (existing.id != id) {
                throw BadRequestException("University with code '${request.code}' already exists")
            }
        }

        val updatedUniversity = university.copy(
            name = request.name,
            code = request.code,
            address = request.address,
            contactEmail = request.contactEmail,
            contactPhone = request.contactPhone,
            website = request.website,
            establishedYear = request.establishedYear
        )

        return UniversityResponse.from(universityRepository.save(updatedUniversity))
    }

    fun deactivateUniversity(id: Long): UniversityResponse {
        val university = findById(id)
        val updatedUniversity = university.copy(isActive = false)
        return UniversityResponse.from(universityRepository.save(updatedUniversity))
    }

    fun activateUniversity(id: Long): UniversityResponse {
        val university = findById(id)
        val updatedUniversity = university.copy(isActive = true)
        return UniversityResponse.from(universityRepository.save(updatedUniversity))
    }

    fun deleteUniversity(id: Long) {
        val university = findById(id)

        // Check if university has associated users or documents
        if (university.users.isNotEmpty()) {
            throw BadRequestException("Cannot delete university with associated users")
        }

        if (university.documents.isNotEmpty()) {
            throw BadRequestException("Cannot delete university with associated documents")
        }

        universityRepository.delete(university)
    }

    @Transactional(readOnly = true)
    fun getUniversityWithUsers(id: Long): University {
        return universityRepository.findByIdWithUsers(id)
            .orElseThrow { ResourceNotFoundException("University not found with id: $id") }
    }

    @Transactional(readOnly = true)
    fun getUniversityStats(): Map<String, Any> {
        val totalUniversities = universityRepository.count()
        val activeUniversities = universityRepository.countActiveUniversities()

        return mapOf(
            "totalUniversities" to totalUniversities,
            "activeUniversities" to activeUniversities
        )
    }
}
