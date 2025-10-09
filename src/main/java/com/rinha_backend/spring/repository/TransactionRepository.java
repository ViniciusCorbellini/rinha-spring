package com.rinha_backend.spring.repository;

import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import com.rinha_backend.spring.dto.transaction.TransactionRequestDTO;
import com.rinha_backend.spring.dto.transaction.TransactionResponseDTO;
import com.rinha_backend.spring.exceptions.EntityNotFoundException;

@Repository
public class TransactionRepository {

    private static final String sql = "SELECT novo_saldo, novo_limite FROM realizar_transacao(?, ?, ?, ?)";

    private final JdbcTemplate jdbcTemplate;

    public TransactionRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Transactional
    public TransactionResponseDTO processTransaction(int clientId, TransactionRequestDTO dto)
            throws IllegalArgumentException, EntityNotFoundException {

        try {
            return jdbcTemplate.queryForObject(sql, (rs, rowNum) -> new TransactionResponseDTO(
                    rs.getBigDecimal("novo_limite"),
                    rs.getBigDecimal("novo_saldo")
            ), clientId, dto.getValor(), dto.getTipo(), dto.getDescricao());

        } catch (DataAccessException e) {
            String message = e.getMostSpecificCause().getMessage();

            if (message.contains("CLIENTE_NAO_ENCONTRADO")) {
                throw new EntityNotFoundException("Cliente não encontrado");
            }

            if (message.contains("LIMITE_INDISPONIVEL")) {
                throw new IllegalArgumentException("Limite excedido");
            }

            throw e;
        }
    }
}