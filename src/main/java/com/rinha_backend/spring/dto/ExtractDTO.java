package com.rinha_backend.spring.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record ExtractDTO(
        SaldoDto saldo,
        List<TransactionDTO> ultimas_transacoes
) {
    public record SaldoDto(
            String total,
            String limite,
            LocalDateTime data_extrato
    ) {}
}
