package com.rinha_backend.spring.service;

import java.math.BigDecimal;

import org.springframework.stereotype.Service;

import com.rinha_backend.spring.dto.transaction.TransactionRequestDTO;
import com.rinha_backend.spring.dto.transaction.TransactionResponseDTO;
import com.rinha_backend.spring.repository.TransactionRepository;

@Service
public class TransactionService {

    private final TransactionRepository repository;

    public TransactionService(TransactionRepository repository) {
        this.repository = repository;
    }

    public TransactionResponseDTO processTransaction(Integer clientId, TransactionRequestDTO dto)
            throws IllegalArgumentException, RuntimeException {
        if(clientId == null || clientId <= 0) throw new IllegalArgumentException("Id invalido");

        String descricao = dto.getDescricao();
        if (descricao == null || descricao.isBlank() || descricao.length() > 10) {
            throw new IllegalArgumentException("Descricao invalida");
        }

        String tipo = dto.getTipo();
        if (!"c".equals(tipo) && !"d".equals(tipo)) {
            throw new IllegalArgumentException("Tipo invalido");
        }

        BigDecimal valor = dto.getValor();
        if (valor == null || valor.signum() <= 0 || valor.scale() > 0) {
            // valor.signum() <= 0 garante que não seja nulo, zero ou negativo
            // valor.scale() > 0 verifica se há casas decimais (ou seja, não é inteiro)
            throw new IllegalArgumentException("Valor invalido");
        }
        return repository.processTransaction(clientId, dto);
    }
}