package com.rinha_backend.spring.service;

import com.rinha_backend.spring.dto.transaction.TransactionRequestDTO;
import com.rinha_backend.spring.dto.transaction.TransactionResponseDTO;
import com.rinha_backend.spring.repository.TransactionRepository;

import java.math.BigDecimal;

import org.springframework.stereotype.Service;

@Service
public class TransactionService {

    private final TransactionRepository repository;

    public TransactionService(TransactionRepository repository) {
        this.repository = repository;
    }

    public TransactionResponseDTO processTransaction(Integer clientId, TransactionRequestDTO dto) throws IllegalArgumentException{
        return repository.processTransaction(clientId, dto);
    }
}