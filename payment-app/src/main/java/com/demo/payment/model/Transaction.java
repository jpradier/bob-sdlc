package com.demo.payment.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "transactions")
public class Transaction {

    @Id
    private String id;

    @Column(nullable = false)
    private String cardNumber;

    @Column(nullable = false)
    private String cardExpiry;

    @Column(nullable = false)
    private BigDecimal amount;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private TransactionType type;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private TransactionStatus status;

    @Column
    private String responseCode;

    @Column
    private String responseMessage;

    @Column
    private String authorizationCode;

    @Column
    private String parentTransactionId;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        if (id == null) {
            id = UUID.randomUUID().toString();
        }
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }

    // Constructors
    public Transaction() {
    }

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

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

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }

    public TransactionType getType() {
        return type;
    }

    public void setType(TransactionType type) {
        this.type = type;
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

    public String getParentTransactionId() {
        return parentTransactionId;
    }

    public void setParentTransactionId(String parentTransactionId) {
        this.parentTransactionId = parentTransactionId;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    // Builder pattern
    public static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private Transaction transaction = new Transaction();

        public Builder id(String id) {
            transaction.id = id;
            return this;
        }

        public Builder cardNumber(String cardNumber) {
            transaction.cardNumber = cardNumber;
            return this;
        }

        public Builder cardExpiry(String cardExpiry) {
            transaction.cardExpiry = cardExpiry;
            return this;
        }

        public Builder amount(BigDecimal amount) {
            transaction.amount = amount;
            return this;
        }

        public Builder type(TransactionType type) {
            transaction.type = type;
            return this;
        }

        public Builder status(TransactionStatus status) {
            transaction.status = status;
            return this;
        }

        public Builder responseCode(String responseCode) {
            transaction.responseCode = responseCode;
            return this;
        }

        public Builder responseMessage(String responseMessage) {
            transaction.responseMessage = responseMessage;
            return this;
        }

        public Builder authorizationCode(String authorizationCode) {
            transaction.authorizationCode = authorizationCode;
            return this;
        }

        public Builder parentTransactionId(String parentTransactionId) {
            transaction.parentTransactionId = parentTransactionId;
            return this;
        }

        public Builder createdAt(LocalDateTime createdAt) {
            transaction.createdAt = createdAt;
            return this;
        }

        public Transaction build() {
            return transaction;
        }
    }
}

// Made with Bob
