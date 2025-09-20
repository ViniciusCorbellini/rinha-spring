package com.rinha_backend.spring.controller;

import com.rinha_backend.spring.dto.ExtractDTO;
import com.rinha_backend.spring.service.ExtractService;
import com.rinha_backend.spring.dto.transaction.TransactionRequestDTO;
import com.rinha_backend.spring.dto.transaction.TransactionResponseDTO;
import com.rinha_backend.spring.service.TransactionService;
import com.rinha_backend.exceptions.EntityNotFoundException;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

@RestController
@RequestMapping("/clientes")
public class Controller {

    private final ExtractService extractService;
    private final TransactionService transactionService;

    public Controller(ExtractService extractService, TransactionService transactionService) {
        this.extractService = extractService;
        this.transactionService = transactionService;
    }

    @GetMapping("/{id}/extrato")
    public ResponseEntity<?> getExtrato(@PathVariable Integer id) {
        if(id == null || id <= 0) return ResponseEntity.unprocessableEntity().body("{ \"error\": \"ID inválido\" }");
        try{
            ExtractDTO extract = extractService.getExtract(id);
            return ResponseEntity.ok(extract);
        } catch (EntityNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("{ \"error\": \"Client not found\" }");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("{ \"error\": \"Internal Error\" }");
        }
    }

    @PostMapping("/{id}/transacoes")
    public ResponseEntity<?> createTransaction(
            @PathVariable Integer id,
            @RequestBody TransactionRequestDTO dto) {
        if(id == null || id <= 0) {
            return ResponseEntity.status(422).body("{\"erro\": \"ID inválido\"}");
        }
        try {
            TransactionResponseDTO response = transactionService.processTransaction(id, dto);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(422).body("{\"erro\": \"" + e.getMessage() + "\"}");
        } catch (EntityNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("{\"erro\": \"" + e.getMessage() + "\"}");
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("{\"erro\": \"Erro interno\"}");
        }
    }
}