package com.rinha_backend.spring.repository;


import com.rinha_backend.spring.dto.transaction.TransactionRequestDTO;
import com.rinha_backend.spring.dto.transaction.TransactionResponseDTO;
import com.rinha_backend.spring.dto.account.AccountData;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

@Repository
public class TransactionRepository {    
    private final JdbcTemplate jdbcTemplate;    

    public TransactionRepository(JdbcTemplate jdbcTemplate) {   
        this.jdbcTemplate = jdbcTemplate;   
    }   

    @Transactional
    public TransactionResponseDTO processTransaction(int clientId, TransactionRequestDTO dto) throws IllegalArgumentException{
        AccountData account = jdbcTemplate.queryForObject(
            "SELECT limite, balance FROM accounts WHERE id = ? FOR UPDATE",
            (rs, rowNum) -> new AccountData(
                    rs.getBigDecimal("limite"),
                    rs.getBigDecimal("balance")
            ),
            clientId
        );

        if (account == null) {
            throw new RuntimeException("Cliente não encontrado");
        }

        BigDecimal accountLimit = account.limite();
        BigDecimal balance = account.balance();
        BigDecimal newBalance = balance;

        if ("c".equals(dto.getTipo())) {
            newBalance = newBalance.add(dto.getValor());
        } else {
            newBalance = newBalance.subtract(dto.getValor());
            if (newBalance.compareTo(accountLimit.negate()) < 0) {
                throw new IllegalArgumentException("Limite excedido");
            }
        }

        jdbcTemplate.update(
            "UPDATE accounts SET balance = ? WHERE id = ?",
            newBalance, clientId
        );

        jdbcTemplate.update(
            "INSERT INTO transactions (amount, type, description, account_id) VALUES (?, ?, ?, ?)",
            dto.getValor(), dto.getTipo(), dto.getDescricao(), clientId
        );

        return new TransactionResponseDTO(accountLimit, newBalance);
    }
}