package com.demo.payment.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class PaymentResponse {

    private String transactionId;
    private TransactionStatus status;
    private String responseCode;
    private String responseMessage;
    private String authorizationCode;
    private BigDecimal amount;
    private LocalDateTime timestamp;

    // Constructors
    public PaymentResponse() {
    }

    // Getters and Setters
    public String getTransactionId() {
        return transactionId;
    }

    public void setTransactionId(String transactionId) {
        this.transactionId = transactionId;
    }

    public TransactionStatus getStatus() {
        return status;
    }

    public void setStatus(TransactionStatus status) {
        this.status = status;
    }

    public String getResponseCode() {
        return responseCode;
    }

    public void setResponseCode(String responseCode) {
        this.responseCode = responseCode;
    }

    public String getResponseMessage() {
        return responseMessage;
    }

    public void setResponseMessage(String responseMessage) {
        this.responseMessage = responseMessage;
    }

    public String getAuthorizationCode() {
        return authorizationCode;
    }

    public void setAuthorizationCode(String authorizationCode) {
        this.authorizationCode = authorizationCode;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }

    // Builder pattern
    public static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private PaymentResponse response = new PaymentResponse();

        public Builder transactionId(String transactionId) {
            response.transactionId = transactionId;
            return this;
        }

        public Builder status(TransactionStatus status) {
            response.status = status;
            return this;
        }

        public Builder responseCode(String responseCode) {
            response.responseCode = responseCode;
            return this;
        }

        public Builder responseMessage(String responseMessage) {
            response.responseMessage = responseMessage;
            return this;
        }

        public Builder authorizationCode(String authorizationCode) {
            response.authorizationCode = authorizationCode;
            return this;
        }

        public Builder amount(BigDecimal amount) {
            response.amount = amount;
            return this;
        }

        public Builder timestamp(LocalDateTime timestamp) {
            response.timestamp = timestamp;
            return this;
        }

        public PaymentResponse build() {
            return response;
        }
    }
}

// Made with Bob
