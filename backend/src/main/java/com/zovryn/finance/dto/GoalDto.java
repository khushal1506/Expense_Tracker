package com.zovryn.finance.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GoalDto {
    private UUID id;

    @NotBlank(message = "Name is required")
    private String name;

    @NotNull(message = "Target amount is required")
    @DecimalMin(value = "0", inclusive = false, message = "Target amount must be greater than 0")
    private BigDecimal targetAmount;

    @NotBlank(message = "Month is required")
    @Pattern(regexp = "^\\d{4}-\\d{2}$", message = "Month format must be YYYY-MM")
    private String month;

    private Boolean isSynced;
    private Boolean isDeleted;

    private Instant updatedAt;
}
