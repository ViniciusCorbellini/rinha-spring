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

    private final JdbcTemplate jdbcTemplate;

    public TransactionRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Transactional
    public TransactionResponseDTO processTransaction(int clientId, TransactionRequestDTO dto)
            throws IllegalArgumentException, EntityNotFoundException {
        String sql = "SELECT limite, novo_saldo FROM realizar_transacao(?, ?, ?, ?);";

        try {
            // Usando queryForObject porque espera-se apenas uma linha de retorno
            return jdbcTemplate.queryForObject(
                    sql,
                    (rs, rowNum) -> new TransactionResponseDTO(
                            rs.getBigDecimal("limite"),
                            rs.getBigDecimal("novo_saldo")
                    ),
                    clientId,
                    dto.getValor(),
                    dto.getTipo(),
                    dto.getDescricao()
            );
        } catch (DataAccessException e) {
            String causeMessage = e.getCause().getMessage();

            if (causeMessage.contains("Cliente não encontrado")) {
                throw new EntityNotFoundException(causeMessage);
            }
            if (causeMessage.contains("Limite da conta excedido")) {
                throw new IllegalArgumentException(causeMessage);
            }
            // Lança uma exceção genérica para outros erros inesperados do BD.
            throw new RuntimeException("Erro inesperado ao processar a transação.", e);
        }
    }
}