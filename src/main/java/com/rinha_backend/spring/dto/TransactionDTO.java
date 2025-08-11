package com.rinha_backend.spring.dto;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record TransactionDTO(
        BigDecimal amount,
        String type,
        String description,
        LocalDateTime created_at
) {
    public static List<TransactionDTO> fromJsonArray(String json) {
        try {
            ObjectMapper mapper = new ObjectMapper();
            return mapper.readValue(json, new TypeReference<List<TransactionDTO>>() {});
        } catch (Exception e) {
            throw new RuntimeException("Erro ao desserializar transações", e);
        }
    }
}
