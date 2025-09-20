package com.rinha_backend.spring.repository;

import com.rinha_backend.spring.dto.ExtractDTO;
import com.rinha_backend.spring.dto.TransactionDTO;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public class ExtractRepository {
    private final JdbcTemplate jdbcTemplate;

    public ExtractRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public ExtractDTO getExtractByClientId(int accountId) {
        String sql = """
            WITH acc AS (
                SELECT id, balance AS total, limite, now() AS data_extrato
                FROM accounts
                WHERE id = ?
            ),
            latest_transactions AS (
                SELECT amount, type, description, created_at
                FROM transactions
                WHERE account_id = (SELECT id FROM acc)
                ORDER BY created_at DESC
                LIMIT 10
            )
            SELECT
                acc.total,
                acc.limite,
                acc.data_extrato,
                (
                    SELECT json_agg(json_build_object(
                                'valor', t.amount,
                                'tipo', t.type,
                                'descricao', t.description,
                                'realizada_em', t.created_at
                            ))
                    FROM latest_transactions t
                ) AS ultimas_transacoes
            FROM acc;
        """;

        return jdbcTemplate.query(sql, ps -> ps.setInt(1, accountId), rs -> {
            if (rs.next()) {
                BigDecimal total = rs.getBigDecimal("total");
                BigDecimal limite = rs.getBigDecimal("limite");
                LocalDateTime dataExtrato = rs.getTimestamp("data_extrato").toLocalDateTime();

                String json = rs.getString("ultimas_transacoes");
                List<TransactionDTO> transacoes = (json != null && !json.equals("null"))
                        ? TransactionDTO.fromJsonArray(json)
                        : List.of();

                ExtractDTO.SaldoDto saldo = new ExtractDTO.SaldoDto(
                        total != null ? total.toPlainString() : null,
                        limite != null ? limite.toPlainString() : null,
                        dataExtrato
                );

                return new ExtractDTO(saldo, transacoes);
            } else {
                return null;
            }
        });
    }
}

