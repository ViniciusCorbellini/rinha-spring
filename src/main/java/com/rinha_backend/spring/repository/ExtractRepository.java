package com.rinha_backend.spring.repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import com.rinha_backend.spring.dto.ExtractDTO;
import com.rinha_backend.spring.dto.TransactionDTO;

@Repository
public class ExtractRepository {

    private final JdbcTemplate jdbcTemplate;

    public ExtractRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public ExtractDTO getExtractByClientId(int accountId) {
        String sql = "SELECT total, limite, data_extrato, ultimas_transacoes FROM obter_extrato(?);";

        return jdbcTemplate.query(sql, ps -> ps.setInt(1, accountId), rs -> {
            if (rs.next()) {
                BigDecimal total = rs.getBigDecimal("total");
                BigDecimal limite = rs.getBigDecimal("limite");
                LocalDateTime dataExtrato = rs.getTimestamp("data_extrato").toLocalDateTime();
                String json = rs.getString("ultimas_transacoes");

                List<TransactionDTO> transacoes = (json != null)
                        ? TransactionDTO.fromJsonArray(json)
                        : List.of();

                ExtractDTO.SaldoDto saldo = new ExtractDTO.SaldoDto(total, limite, dataExtrato);
                return new ExtractDTO(saldo, transacoes);
            } else {
                return null;
            }
        });
    }
}
