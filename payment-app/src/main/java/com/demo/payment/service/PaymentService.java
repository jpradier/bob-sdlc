package com.demo.payment.service;

import com.demo.payment.model.*;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Random;
import java.util.Set;

@Service
public class PaymentService {

    private final TransactionRepository transactionRepository;
    private final Random random = new Random();
    
    // Test card numbers
    private static final Set<String> VALID_CARDS = Set.of(
        "4263970000005262",  // Visa
        "5425230000004415",  // MasterCard
        "374101000000608"    // Amex
    );

    public PaymentService(TransactionRepository transactionRepository) {
        this.transactionRepository = transactionRepository;
    }

    public PaymentResponse authorize(PaymentRequest request) {
        // Simulate processing delay (200-500ms)
        simulateProcessingDelay();

        Transaction transaction = Transaction.builder()
                .cardNumber(maskCardNumber(request.getCardNumber()))
                .cardExpiry(request.getCardExpiry())
                .amount(request.getAmount())
                .type(TransactionType.AUTHORIZE)
                .build();

        // Validate card and simulate random declines
        if (!isValidCard(request.getCardNumber())) {
            transaction.setStatus(TransactionStatus.DECLINED);
            transaction.setResponseCode("INVALID_CARD");
            transaction.setResponseMessage("Invalid card number");
        } else if (isCardExpired(request.getCardExpiry())) {
            transaction.setStatus(TransactionStatus.DECLINED);
            transaction.setResponseCode("EXPIRED_CARD");
            transaction.setResponseMessage("Card has expired");
        } else if (shouldDeclineRandomly()) {
            transaction.setStatus(TransactionStatus.DECLINED);
            transaction.setResponseCode("INSUFFICIENT_FUNDS");
            transaction.setResponseMessage("Insufficient funds");
        } else {
            transaction.setStatus(TransactionStatus.AUTHORIZED);
            transaction.setResponseCode("APPROVED");
            transaction.setResponseMessage("Transaction authorized");
            transaction.setAuthorizationCode(generateAuthCode());
        }

        transaction = transactionRepository.save(transaction);

        return buildResponse(transaction);
    }

    public PaymentResponse capture(String transactionId) {
        // Simulate processing delay
        simulateProcessingDelay();

        Transaction authTransaction = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new IllegalArgumentException("Transaction not found"));

        if (authTransaction.getStatus() != TransactionStatus.AUTHORIZED) {
            throw new IllegalStateException("Transaction must be in AUTHORIZED status to capture");
        }

        // Check if already captured
        if (transactionRepository.findByParentTransactionIdAndType(transactionId, TransactionType.CAPTURE).isPresent()) {
            throw new IllegalStateException("Transaction has already been captured");
        }

        Transaction captureTransaction = Transaction.builder()
                .cardNumber(authTransaction.getCardNumber())
                .cardExpiry(authTransaction.getCardExpiry())
                .amount(authTransaction.getAmount())
                .type(TransactionType.CAPTURE)
                .status(TransactionStatus.CAPTURED)
                .responseCode("CAPTURED")
                .responseMessage("Transaction captured successfully")
                .authorizationCode(authTransaction.getAuthorizationCode())
                .parentTransactionId(transactionId)
                .build();

        captureTransaction = transactionRepository.save(captureTransaction);

        return buildResponse(captureTransaction);
    }

    public PaymentResponse refund(String transactionId) {
        // Simulate processing delay
        simulateProcessingDelay();

        Transaction captureTransaction = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new IllegalArgumentException("Transaction not found"));

        if (captureTransaction.getStatus() != TransactionStatus.CAPTURED) {
            throw new IllegalStateException("Transaction must be in CAPTURED status to refund");
        }

        // Check if already refunded
        if (transactionRepository.findByParentTransactionIdAndType(transactionId, TransactionType.REFUND).isPresent()) {
            throw new IllegalStateException("Transaction has already been refunded");
        }

        Transaction refundTransaction = Transaction.builder()
                .cardNumber(captureTransaction.getCardNumber())
                .cardExpiry(captureTransaction.getCardExpiry())
                .amount(captureTransaction.getAmount())
                .type(TransactionType.REFUND)
                .status(TransactionStatus.REFUNDED)
                .responseCode("REFUNDED")
                .responseMessage("Transaction refunded successfully")
                .parentTransactionId(transactionId)
                .build();

        refundTransaction = transactionRepository.save(refundTransaction);

        return buildResponse(refundTransaction);
    }

    @Cacheable(value = "transactions", key = "#id")
    public Transaction getTransaction(String id) {
        return transactionRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Transaction not found"));
    }

    public List<Transaction> getRecentTransactions() {
        return transactionRepository.findTop20ByOrderByCreatedAtDesc();
    }

    @CacheEvict(value = "transactions", allEntries = true)
    public void clearCache() {
        // Cache cleared
    }

    private void simulateProcessingDelay() {
        try {
            // Random delay between 200-500ms
            Thread.sleep(200 + random.nextInt(301));
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private boolean isValidCard(String cardNumber) {
        return VALID_CARDS.contains(cardNumber);
    }

    private boolean isCardExpired(String expiry) {
        // Simple check: MM/YY format
        String[] parts = expiry.split("/");
        if (parts.length != 2) return true;
        
        try {
            int month = Integer.parseInt(parts[0]);
            int year = 2000 + Integer.parseInt(parts[1]);
            
            LocalDateTime now = LocalDateTime.now();
            int currentYear = now.getYear();
            int currentMonth = now.getMonthValue();
            
            return year < currentYear || (year == currentYear && month < currentMonth);
        } catch (NumberFormatException e) {
            return true;
        }
    }

    private boolean shouldDeclineRandomly() {
        // 10% random decline rate
        return random.nextInt(100) < 10;
    }

    private String generateAuthCode() {
        return String.format("%06d", random.nextInt(1000000));
    }

    private String maskCardNumber(String cardNumber) {
        if (cardNumber.length() < 4) return cardNumber;
        return "**** **** **** " + cardNumber.substring(cardNumber.length() - 4);
    }

    private PaymentResponse buildResponse(Transaction transaction) {
        return PaymentResponse.builder()
                .transactionId(transaction.getId())
                .status(transaction.getStatus())
                .responseCode(transaction.getResponseCode())
                .responseMessage(transaction.getResponseMessage())
                .authorizationCode(transaction.getAuthorizationCode())
                .amount(transaction.getAmount())
                .timestamp(transaction.getCreatedAt())
                .build();
    }
}

// Made with Bob
