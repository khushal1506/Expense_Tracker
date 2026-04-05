package com.zovryn.finance.service;

import com.zovryn.finance.dto.TransactionDto;
import com.zovryn.finance.entity.Transaction;
import com.zovryn.finance.entity.User;
import com.zovryn.finance.exception.EntityNotFoundException;
import com.zovryn.finance.repository.TransactionRepository;
import com.zovryn.finance.util.MapperUtil;
import com.zovryn.finance.util.SecurityUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final SecurityUtil securityUtil;

    @Transactional(readOnly = true)
    public List<TransactionDto> getUserTransactions() {
        User user = securityUtil.getCurrentUser();
        return transactionRepository.findAllByUserAndIsDeletedFalse(user)
                .stream()
                .map(MapperUtil::toTransactionDto)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<TransactionDto> getUnsyncedTransactions() {
        User user = securityUtil.getCurrentUser();
        return transactionRepository.findAllByUserAndIsDeletedFalse(user)
                .stream()
                .filter(t -> !t.getIsSynced())
                .map(MapperUtil::toTransactionDto)
                .toList();
    }

    @Transactional(readOnly = true)
    public TransactionDto getTransactionById(UUID id) {
        User user = securityUtil.getCurrentUser();
        Transaction transaction = transactionRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Transaction not found"));

        if (!transaction.getUser().getId().equals(user.getId())) {
            throw new EntityNotFoundException("Transaction not owned by this user");
        }

        return MapperUtil.toTransactionDto(transaction);
    }

    @Transactional
    public TransactionDto createTransaction(TransactionDto dto) {
        User user = securityUtil.getCurrentUser();
        Transaction transaction = MapperUtil.toTransactionEntity(dto, user);
        transaction = transactionRepository.save(transaction);
        return MapperUtil.toTransactionDto(transaction);
    }

    @Transactional
    public TransactionDto updateTransaction(UUID id, TransactionDto dto) {
        User user = securityUtil.getCurrentUser();
        Transaction transaction = transactionRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Transaction not found"));

        if (!transaction.getUser().getId().equals(user.getId())) {
            throw new EntityNotFoundException("Transaction not owned by this user");
        }

        transaction.setAmount(dto.getAmount());
        transaction.setType(dto.getType());
        transaction.setCategory(dto.getCategory());
        transaction.setDate(dto.getDate());
        transaction.setNotes(dto.getNotes());
        transaction.setIsSynced(false);

        transaction = transactionRepository.save(transaction);
        return MapperUtil.toTransactionDto(transaction);
    }

    @Transactional
    public void deleteTransaction(UUID id) {
        User user = securityUtil.getCurrentUser();
        Transaction transaction = transactionRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Transaction not found"));

        if (!transaction.getUser().getId().equals(user.getId())) {
            throw new EntityNotFoundException("Transaction not owned by this user");
        }

        transaction.setIsDeleted(true);
        transaction.setIsSynced(false);
        transactionRepository.save(transaction);
    }

    @Transactional(readOnly = true)
    public List<TransactionDto> getChangedSince(Instant since) {
        User user = securityUtil.getCurrentUser();
        return transactionRepository.findAllByUserAndIsDeletedFalseAndUpdatedAtAfter(user, since)
                .stream()
                .map(MapperUtil::toTransactionDto)
                .toList();
    }
}
