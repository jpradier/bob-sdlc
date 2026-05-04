package com.demo.payment.controller;

import com.demo.payment.model.PaymentRequest;
import com.demo.payment.model.PaymentResponse;
import com.demo.payment.model.Transaction;
import com.demo.payment.service.PaymentService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/payments")
@CrossOrigin(origins = "*")
public class PaymentController {

    private final PaymentService paymentService;

    public PaymentController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }

    @PostMapping("/authorize")
    public ResponseEntity<PaymentResponse> authorize(@Valid @RequestBody PaymentRequest request) {
        PaymentResponse response = paymentService.authorize(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/capture")
    public ResponseEntity<PaymentResponse> capture(@RequestBody Map<String, String> request) {
        String transactionId = request.get("transactionId");
        if (transactionId == null || transactionId.isEmpty()) {
            return ResponseEntity.badRequest().build();
        }
        
        try {
            PaymentResponse response = paymentService.capture(transactionId);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/refund")
    public ResponseEntity<PaymentResponse> refund(@RequestBody Map<String, String> request) {
        String transactionId = request.get("transactionId");
        if (transactionId == null || transactionId.isEmpty()) {
            return ResponseEntity.badRequest().build();
        }
        
        try {
            PaymentResponse response = paymentService.refund(transactionId);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<Transaction> getTransaction(@PathVariable String id) {
        try {
            Transaction transaction = paymentService.getTransaction(id);
            return ResponseEntity.ok(transaction);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/history")
    public ResponseEntity<List<Transaction>> getHistory() {
        List<Transaction> transactions = paymentService.getRecentTransactions();
        return ResponseEntity.ok(transactions);
    }
}

// Made with Bob
