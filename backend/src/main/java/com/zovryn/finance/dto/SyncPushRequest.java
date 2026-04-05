package com.zovryn.finance.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SyncPushRequest {
    private List<TransactionDto> transactions;
    private List<GoalDto> goals;
}
