package com.zovryn.finance.util;

import com.zovryn.finance.dto.TransactionDto;
import com.zovryn.finance.dto.GoalDto;
import com.zovryn.finance.dto.UserDto;
import com.zovryn.finance.entity.Goal;
import com.zovryn.finance.entity.Transaction;
import com.zovryn.finance.entity.User;

public class MapperUtil {

    public static UserDto toUserDto(User user) {
        return UserDto.builder()
                .id(user.getId())
                .email(user.getEmail())
                .name(user.getName())
                .createdAt(user.getCreatedAt())
                .build();
    }

    public static TransactionDto toTransactionDto(Transaction transaction) {
        return TransactionDto.builder()
                .id(transaction.getId())
                .amount(transaction.getAmount())
                .type(transaction.getType())
                .category(transaction.getCategory())
                .date(transaction.getDate())
                .notes(transaction.getNotes())
                .isSynced(transaction.getIsSynced())
                .isDeleted(transaction.getIsDeleted())
                .updatedAt(transaction.getUpdatedAt())
                .build();
    }

    public static Transaction toTransactionEntity(TransactionDto dto, User user) {
        Transaction transaction = Transaction.builder()
            .amount(dto.getAmount())
            .type(dto.getType())
            .category(dto.getCategory())
            .date(dto.getDate())
            .notes(dto.getNotes())
            .user(user)
            .build();
        transaction.setId(dto.getId());
        transaction.setIsSynced(dto.getIsSynced() != null ? dto.getIsSynced() : false);
        transaction.setIsDeleted(dto.getIsDeleted() != null ? dto.getIsDeleted() : false);
        return transaction;
    }

    public static GoalDto toGoalDto(Goal goal) {
        return GoalDto.builder()
                .id(goal.getId())
                .name(goal.getName())
                .targetAmount(goal.getTargetAmount())
                .month(goal.getMonth())
                .isSynced(goal.getIsSynced())
                .isDeleted(goal.getIsDeleted())
                .updatedAt(goal.getUpdatedAt())
                .build();
    }

    public static Goal toGoalEntity(GoalDto dto, User user) {
        Goal goal = Goal.builder()
            .name(dto.getName())
            .targetAmount(dto.getTargetAmount())
            .month(dto.getMonth())
            .user(user)
            .build();
        goal.setId(dto.getId());
        goal.setIsSynced(dto.getIsSynced() != null ? dto.getIsSynced() : false);
        goal.setIsDeleted(dto.getIsDeleted() != null ? dto.getIsDeleted() : false);
        return goal;
    }
}
