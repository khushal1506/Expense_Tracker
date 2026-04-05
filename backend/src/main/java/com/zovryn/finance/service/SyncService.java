package com.zovryn.finance.service;

import com.zovryn.finance.dto.GoalDto;
import com.zovryn.finance.dto.SyncPullResponse;
import com.zovryn.finance.dto.SyncPushRequest;
import com.zovryn.finance.dto.SyncPushResponse;
import com.zovryn.finance.dto.TransactionDto;
import com.zovryn.finance.entity.Goal;
import com.zovryn.finance.entity.Transaction;
import com.zovryn.finance.entity.User;
import com.zovryn.finance.repository.GoalRepository;
import com.zovryn.finance.repository.TransactionRepository;
import com.zovryn.finance.util.MapperUtil;
import com.zovryn.finance.util.SecurityUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class SyncService {

    private final TransactionRepository transactionRepository;
    private final GoalRepository goalRepository;
    private final SecurityUtil securityUtil;

    public SyncPushResponse syncPush(SyncPushRequest request) {
        User user = securityUtil.getCurrentUser();
        List<UUID> skippedIds = new ArrayList<>();
        int successCount = 0;

        // Process transactions
        if (request.getTransactions() != null) {
            for (TransactionDto dto : request.getTransactions()) {
                try {
                    Optional<Transaction> existingOpt = transactionRepository.findById(dto.getId());

                    if (existingOpt.isPresent()) {
                        Transaction existing = existingOpt.get();

                        if (!existing.getUser().getId().equals(user.getId())) {
                            skippedIds.add(dto.getId());
                            continue;
                        }

                        // Client's record is newer - update
                        if (dto.getUpdatedAt().isAfter(existing.getUpdatedAt())) {
                            existing.setAmount(dto.getAmount());
                            existing.setType(dto.getType());
                            existing.setCategory(dto.getCategory());
                            existing.setDate(dto.getDate());
                            existing.setNotes(dto.getNotes());
                            existing.setIsDeleted(dto.getIsDeleted() != null ? dto.getIsDeleted() : false);
                            existing.setIsSynced(true);
                            transactionRepository.save(existing);
                            successCount++;
                        } else {
                            skippedIds.add(dto.getId());
                        }
                    } else {
                        // New transaction
                        Transaction transaction = MapperUtil.toTransactionEntity(dto, user);
                        transaction.setIsSynced(true);
                        transactionRepository.save(transaction);
                        successCount++;
                    }
                } catch (Exception e) {
                    log.warn("Skipping transaction {} during sync push: {}", dto.getId(), e.getMessage(), e);
                    skippedIds.add(dto.getId());
                }
            }
        }

        // Process goals
        if (request.getGoals() != null) {
            for (GoalDto dto : request.getGoals()) {
                try {
                    Optional<Goal> existingOpt = goalRepository.findById(dto.getId());

                    if (existingOpt.isPresent()) {
                        Goal existing = existingOpt.get();

                        if (!existing.getUser().getId().equals(user.getId())) {
                            skippedIds.add(dto.getId());
                            continue;
                        }

                        // Client's record is newer - update
                        if (dto.getUpdatedAt().isAfter(existing.getUpdatedAt())) {
                            existing.setName(dto.getName());
                            existing.setTargetAmount(dto.getTargetAmount());
                            existing.setMonth(dto.getMonth());
                            existing.setIsDeleted(dto.getIsDeleted() != null ? dto.getIsDeleted() : false);
                            existing.setIsSynced(true);
                            goalRepository.save(existing);
                            successCount++;
                        } else {
                            skippedIds.add(dto.getId());
                        }
                    } else {
                        // New goal
                        Goal goal = MapperUtil.toGoalEntity(dto, user);
                        goal.setIsSynced(true);
                        goalRepository.save(goal);
                        successCount++;
                    }
                } catch (Exception e) {
                    log.warn("Skipping goal {} during sync push: {}", dto.getId(), e.getMessage(), e);
                    skippedIds.add(dto.getId());
                }
            }
        }

        return SyncPushResponse.builder()
                .successCount(successCount)
                .skippedIds(skippedIds)
                .build();
    }

    @Transactional(readOnly = true)
    public SyncPullResponse syncPull(Instant since) {
        User user = securityUtil.getCurrentUser();

        List<TransactionDto> transactions = transactionRepository
                .findAllByUserAndIsDeletedFalseAndUpdatedAtAfter(user, since)
                .stream()
                .map(MapperUtil::toTransactionDto)
                .toList();

        List<GoalDto> goals = goalRepository
                .findAllByUserAndIsDeletedFalseAndUpdatedAtAfter(user, since)
                .stream()
                .map(MapperUtil::toGoalDto)
                .toList();

        return SyncPullResponse.builder()
                .transactions(transactions)
                .goals(goals)
                .serverTime(Instant.now())
                .build();
    }
}
