package com.rinha_backend.spring.service;

import com.rinha_backend.spring.dto.ExtractDTO;
import com.rinha_backend.spring.exceptions.EntityNotFoundException;
import com.rinha_backend.spring.repository.ExtractRepository;

import org.springframework.stereotype.Service;

@Service
public class ExtractService {

    private ExtractRepository repository;

    public ExtractService(ExtractRepository repository) {
        this.repository = repository;
    }

    public ExtractDTO getExtract(Integer clientId) throws EntityNotFoundException, IllegalArgumentException {
        if(clientId == null || clientId <= 0) throw new IllegalArgumentException("Id invalido");

        ExtractDTO extract = repository.getExtractByClientId(clientId);

        if(extract == null) throw new EntityNotFoundException("Client not found");

        return extract;
    }
}
