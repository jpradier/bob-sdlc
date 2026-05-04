package com.demo.payment.model;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import java.math.BigDecimal;

public class PaymentRequest {

    @NotBlank(message = "Card number is required")
    @Pattern(regexp = "\\d{13,19}", message = "Invalid card number")
    private String cardNumber;

    @NotBlank(message = "Card expiry is required")
    @Pattern(regexp = "\\d{2}/\\d{2}", message = "Invalid expiry format (MM/YY)")
    private String cardExpiry;

    @NotBlank(message = "CVV is required")
    @Pattern(regexp = "\\d{3,4}", message = "Invalid CVV")
    private String cvv;

    @NotNull(message = "Amount is required")
    @Positive(message = "Amount must be positive")
    private BigDecimal amount;

    // Constructors
    public PaymentRequest() {
    }

    public PaymentRequest(String cardNumber, String cardExpiry, String cvv, BigDecimal amount) {
        this.cardNumber = cardNumber;
        this.cardExpiry = cardExpiry;
        this.cvv = cvv;
        this.amount = amount;
    }

    // Getters and Setters
    public String getCardNumber() {
        return cardNumber;
    }

    public void setCardNumber(String cardNumber) {
        this.cardNumber = cardNumber;
    }

    public String getCardExpiry() {
        return cardExpiry;
    }

    public void setCardExpiry(String cardExpiry) {
        this.cardExpiry = cardExpiry;
    }

    public String getCvv() {
        return cvv;
    }

    public void setCvv(String cvv) {
        this.cvv = cvv;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }
}

// Made with Bob
