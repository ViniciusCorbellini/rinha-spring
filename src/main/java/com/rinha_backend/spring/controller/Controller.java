package com.rinha_backend.spring.controller;

import com.rinha_backend.spring.dto.ExtractDTO;
import com.rinha_backend.spring.service.ExtractService;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/clientes")
public class Controller {

    private ExtractService extractService;

    public Controller(ExtractService extractService) {
        this.extractService = extractService;
    }

    @GetMapping("/{id}/extrato")
    public ResponseEntity<?> getExtrato(@PathVariable Integer id) {
        if(id == null || id <= 0) return ResponseEntity.unprocessableEntity().body("{ \"error\": \"ID inválido\" }");

        try{
            ExtractDTO extract = extractService.getExtract(id);
            return ResponseEntity.ok(extract);
        } catch (EmptyResultDataAccessException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("{ \"error\": \"Client not found\" }");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("{ \"error\": \"Internal Error\" }");
        }
    }
}