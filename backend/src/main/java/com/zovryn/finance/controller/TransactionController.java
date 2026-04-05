package com.zovryn.finance.controller;

import com.zovryn.finance.dto.ApiResponse;
import com.zovryn.finance.dto.TransactionDto;
import com.zovryn.finance.service.TransactionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/transactions")
@RequiredArgsConstructor
@CrossOrigin(origins = "*", maxAge = 3600)
public class TransactionController {

    private final TransactionService transactionService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<TransactionDto>>> getTransactions() {
        List<TransactionDto> transactions = transactionService.getUserTransactions();
        return ResponseEntity.ok(ApiResponse.success(transactions, "Transactions retrieved successfully"));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<TransactionDto>> getTransaction(@PathVariable UUID id) {
        TransactionDto transaction = transactionService.getTransactionById(id);
        return ResponseEntity.ok(ApiResponse.success(transaction, "Transaction retrieved successfully"));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<TransactionDto>> createTransaction(@Valid @RequestBody TransactionDto dto) {
        TransactionDto transaction = transactionService.createTransaction(dto);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success(transaction, "Transaction created successfully"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<TransactionDto>> updateTransaction(
            @PathVariable UUID id,
            @Valid @RequestBody TransactionDto dto) {
        TransactionDto transaction = transactionService.updateTransaction(id, dto);
        return ResponseEntity.ok(ApiResponse.success(transaction, "Transaction updated successfully"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteTransaction(@PathVariable UUID id) {
        transactionService.deleteTransaction(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Transaction deleted successfully"));
    }
}
