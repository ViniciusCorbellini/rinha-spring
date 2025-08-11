package com.rinha_backend.spring.service;

import com.rinha_backend.spring.dto.ExtractDTO;
import com.rinha_backend.spring.repository.ExtractRepository;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.stereotype.Service;

@Service
public class ExtractService {

    private ExtractRepository repository;

    public ExtractService(ExtractRepository repository) {
        this.repository = repository;
    }

    public ExtractDTO getExtract(int clientId) throws EmptyResultDataAccessException {
        ExtractDTO extract = repository.getExtractByClientId(clientId);

        if(extract == null) throw new EmptyResultDataAccessException("Client not found", 1);

        return extract;
    }
}
