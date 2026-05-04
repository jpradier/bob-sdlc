package com.demo.payment.controller;

import com.demo.payment.service.PaymentService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/admin")
@CrossOrigin(origins = "*")
public class AdminController {

    private final PaymentService paymentService;

    public AdminController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }

    @PostMapping("/cache/clear")
    public ResponseEntity<Map<String, String>> clearCache() {
        paymentService.clearCache();
        return ResponseEntity.ok(Map.of("message", "Cache cleared successfully"));
    }
}

// Made with Bob
