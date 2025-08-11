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

    public ExtractDTO getExtractByClientId(int clientId) {
        String sql = """
                    WITH acc AS (
                        SELECT id, balance AS total, limite, now() AS data_extrato
                        FROM accounts
                        WHERE id = ?
                    ), trx AS (
                        SELECT amount, type, description, created_at
                        FROM transactions
                        WHERE account_id = ?
                        ORDER BY created_at DESC
                        LIMIT 10
                    )
                    SELECT
                        acc.total,
                        acc.limite,
                        acc.data_extrato,
                        json_agg(
                            json_build_object(
                                'amount', trx.amount,
                                'type', trx.type,
                                'description', trx.description,
                                'created_at', trx.created_at
                            )
                            ORDER BY trx.created_at DESC
                        ) FILTER (WHERE trx.created_at IS NOT NULL) AS ultimas_transacoes
                    FROM acc
                    LEFT JOIN trx ON TRUE
                    GROUP BY acc.id, acc.total, acc.limite, acc.data_extrato;
                """;

        return jdbcTemplate.query(sql, ps -> {
            ps.setInt(1, clientId);
            ps.setInt(2, clientId);
        }, rs -> {
            if (rs.next()) {
                BigDecimal total = rs.getBigDecimal("total");
                BigDecimal limite = rs.getBigDecimal("limite");
                LocalDateTime dataExtrato = rs.getTimestamp("data_extrato").toLocalDateTime();

                String json = rs.getString("ultimas_transacoes");
                List<TransactionDTO> transacoes = (json != null && !json.equals("null"))
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

