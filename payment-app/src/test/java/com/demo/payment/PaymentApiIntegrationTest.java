package com.demo.payment;

import com.demo.payment.model.PaymentRequest;
import com.demo.payment.model.TransactionRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Integration tests for Payment API endpoints.
 * Tests cover authorization, capture, refund operations with various scenarios.
 */
@SpringBootTest
@AutoConfigureMockMvc
@DisplayName("Payment API Integration Tests")
class PaymentApiIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private TransactionRepository transactionRepository;

    // Valid test card numbers
    private static final String VALID_VISA = "4263970000005262";
    private static final String VALID_MASTERCARD = "5425230000004415";
    private static final String INVALID_CARD = "1234567890123456";

    @BeforeEach
    void setUp() {
        // Clean up database before each test
        transactionRepository.deleteAll();
    }

    /**
     * Helper method to authorize a transaction, retrying if declined due to random decline simulation.
     * Returns the transaction ID of an authorized transaction.
     */
    private String authorizeTransaction(String cardNumber, String expiry, String cvv, BigDecimal amount) throws Exception {
        for (int i = 0; i < 20; i++) {
            PaymentRequest authRequest = new PaymentRequest(cardNumber, expiry, cvv, amount);
            
            MvcResult authResult = mockMvc.perform(post("/api/payments/authorize")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(authRequest)))
                    .andExpect(status().isOk())
                    .andReturn();

            String authResponse = authResult.getResponse().getContentAsString();
            String status = objectMapper.readTree(authResponse).get("status").asText();
            
            if ("AUTHORIZED".equals(status)) {
                return objectMapper.readTree(authResponse).get("transactionId").asText();
            }
        }
        throw new RuntimeException("Failed to get authorized transaction after 20 attempts");
    }

    @Test
    @DisplayName("Test 1: Successful Authorization - Valid Card")
    void testSuccessfulAuthorization() throws Exception {
        // Given
        PaymentRequest request = new PaymentRequest(
                VALID_VISA,
                "12/28",
                "123",
                new BigDecimal("100.00")
        );

        // When & Then
        mockMvc.perform(post("/api/payments/authorize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.transactionId").exists())
                .andExpect(jsonPath("$.transactionId").isNotEmpty())
                .andExpect(jsonPath("$.status").value("AUTHORIZED"))
                .andExpect(jsonPath("$.responseCode").value("APPROVED"))
                .andExpect(jsonPath("$.responseMessage").value("Transaction authorized"))
                .andExpect(jsonPath("$.authorizationCode").exists())
                .andExpect(jsonPath("$.authorizationCode").isNotEmpty())
                .andExpect(jsonPath("$.amount").value(100.00))
                .andExpect(jsonPath("$.timestamp").exists());
    }

    @Test
    @DisplayName("Test 2: Declined Card - Invalid Card Number")
    void testDeclinedCardInvalidNumber() throws Exception {
        // Given
        PaymentRequest request = new PaymentRequest(
                INVALID_CARD,
                "12/28",
                "123",
                new BigDecimal("50.00")
        );

        // When & Then
        mockMvc.perform(post("/api/payments/authorize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.transactionId").exists())
                .andExpect(jsonPath("$.status").value("DECLINED"))
                .andExpect(jsonPath("$.responseCode").value("INVALID_CARD"))
                .andExpect(jsonPath("$.responseMessage").value("Invalid card number"))
                .andExpect(jsonPath("$.authorizationCode").doesNotExist())
                .andExpect(jsonPath("$.amount").value(50.00))
                .andExpect(jsonPath("$.timestamp").exists());
    }

    @Test
    @DisplayName("Test 3: Declined Card - Expired Card")
    void testDeclinedCardExpired() throws Exception {
        // Given - expired card (01/20)
        PaymentRequest request = new PaymentRequest(
                VALID_VISA,
                "01/20",
                "123",
                new BigDecimal("75.00")
        );

        // When & Then
        mockMvc.perform(post("/api/payments/authorize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.transactionId").exists())
                .andExpect(jsonPath("$.status").value("DECLINED"))
                .andExpect(jsonPath("$.responseCode").value("EXPIRED_CARD"))
                .andExpect(jsonPath("$.responseMessage").value("Card has expired"))
                .andExpect(jsonPath("$.authorizationCode").doesNotExist())
                .andExpect(jsonPath("$.amount").value(75.00));
    }

    @Test
    @DisplayName("Test 4: Capture After Authorization - Success")
    void testCaptureAfterAuthorization() throws Exception {
        // Given - First authorize a transaction
        String transactionId = authorizeTransaction(VALID_MASTERCARD, "06/27", "456", new BigDecimal("200.00"));

        // When - Capture the authorized transaction
        Map<String, String> captureRequest = new HashMap<>();
        captureRequest.put("transactionId", transactionId);

        // Then
        mockMvc.perform(post("/api/payments/capture")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(captureRequest)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.transactionId").exists())
                .andExpect(jsonPath("$.transactionId").isNotEmpty())
                .andExpect(jsonPath("$.status").value("CAPTURED"))
                .andExpect(jsonPath("$.responseCode").value("CAPTURED"))
                .andExpect(jsonPath("$.responseMessage").value("Transaction captured successfully"))
                .andExpect(jsonPath("$.amount").value(200.00))
                .andExpect(jsonPath("$.timestamp").exists());
    }

    @Test
    @DisplayName("Test 5: Capture Non-Existent Transaction - Not Found")
    void testCaptureNonExistentTransaction() throws Exception {
        // Given
        Map<String, String> captureRequest = new HashMap<>();
        captureRequest.put("transactionId", "non-existent-id");

        // When & Then
        mockMvc.perform(post("/api/payments/capture")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(captureRequest)))
                .andExpect(status().isNotFound());
    }

    @Test
    @DisplayName("Test 6: Capture Already Captured Transaction - Bad Request")
    void testCaptureAlreadyCapturedTransaction() throws Exception {
        // Given - Authorize and capture a transaction
        PaymentRequest authRequest = new PaymentRequest(
                VALID_VISA,
                "09/26",
                "789",
                new BigDecimal("150.00")
        );

        MvcResult authResult = mockMvc.perform(post("/api/payments/authorize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(authRequest)))
                .andExpect(status().isOk())
                .andReturn();

        String authResponse = authResult.getResponse().getContentAsString();
        String transactionId = objectMapper.readTree(authResponse).get("transactionId").asText();

        Map<String, String> captureRequest = new HashMap<>();
        captureRequest.put("transactionId", transactionId);

        // First capture - should succeed
        mockMvc.perform(post("/api/payments/capture")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(captureRequest)))
                .andExpect(status().isOk());

        // When - Try to capture again
        // Then - Should fail with bad request
        mockMvc.perform(post("/api/payments/capture")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(captureRequest)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Test 7: Refund After Capture - Success")
    void testRefundAfterCapture() throws Exception {
        // Given - Authorize and capture a transaction
        String authTransactionId = authorizeTransaction(VALID_MASTERCARD, "03/29", "321", new BigDecimal("300.00"));

        Map<String, String> captureRequest = new HashMap<>();
        captureRequest.put("transactionId", authTransactionId);

        MvcResult captureResult = mockMvc.perform(post("/api/payments/capture")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(captureRequest)))
                .andExpect(status().isOk())
                .andReturn();

        String captureResponse = captureResult.getResponse().getContentAsString();
        String captureTransactionId = objectMapper.readTree(captureResponse).get("transactionId").asText();

        // When - Refund the captured transaction
        Map<String, String> refundRequest = new HashMap<>();
        refundRequest.put("transactionId", captureTransactionId);

        // Then
        mockMvc.perform(post("/api/payments/refund")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(refundRequest)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.transactionId").exists())
                .andExpect(jsonPath("$.transactionId").isNotEmpty())
                .andExpect(jsonPath("$.status").value("REFUNDED"))
                .andExpect(jsonPath("$.responseCode").value("REFUNDED"))
                .andExpect(jsonPath("$.responseMessage").value("Transaction refunded successfully"))
                .andExpect(jsonPath("$.amount").value(300.00))
                .andExpect(jsonPath("$.timestamp").exists());
    }

    @Test
    @DisplayName("Test 8: Duplicate Refund Attempt - Bad Request")
    void testDuplicateRefundAttempt() throws Exception {
        // Given - Authorize, capture, and refund a transaction
        // Retry authorization until we get an approved one (to handle random declines)
        String authTransactionId = null;
        for (int i = 0; i < 20; i++) {
            PaymentRequest authRequest = new PaymentRequest(
                    VALID_VISA,
                    "11/27",
                    "654",
                    new BigDecimal("250.00")
            );

            MvcResult authResult = mockMvc.perform(post("/api/payments/authorize")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(authRequest)))
                    .andExpect(status().isOk())
                    .andReturn();

            String authResponse = authResult.getResponse().getContentAsString();
            String status = objectMapper.readTree(authResponse).get("status").asText();
            
            if ("AUTHORIZED".equals(status)) {
                authTransactionId = objectMapper.readTree(authResponse).get("transactionId").asText();
                break;
            }
        }

        if (authTransactionId == null) {
            throw new RuntimeException("Failed to get authorized transaction after 20 attempts");
        }

        Map<String, String> captureRequest = new HashMap<>();
        captureRequest.put("transactionId", authTransactionId);

        MvcResult captureResult = mockMvc.perform(post("/api/payments/capture")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(captureRequest)))
                .andExpect(status().isOk())
                .andReturn();

        String captureResponse = captureResult.getResponse().getContentAsString();
        String captureTransactionId = objectMapper.readTree(captureResponse).get("transactionId").asText();

        Map<String, String> refundRequest = new HashMap<>();
        refundRequest.put("transactionId", captureTransactionId);

        // First refund - should succeed
        mockMvc.perform(post("/api/payments/refund")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(refundRequest)))
                .andExpect(status().isOk());

        // When - Try to refund again
        // Then - Should fail with bad request
        mockMvc.perform(post("/api/payments/refund")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(refundRequest)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Test 9: Refund Non-Existent Transaction - Not Found")
    void testRefundNonExistentTransaction() throws Exception {
        // Given
        Map<String, String> refundRequest = new HashMap<>();
        refundRequest.put("transactionId", "non-existent-id");

        // When & Then
        mockMvc.perform(post("/api/payments/refund")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(refundRequest)))
                .andExpect(status().isNotFound());
    }

    @Test
    @DisplayName("Test 10: Refund Authorized Transaction - Bad Request")
    void testRefundAuthorizedTransaction() throws Exception {
        // Given - Only authorize, don't capture
        PaymentRequest authRequest = new PaymentRequest(
                VALID_MASTERCARD,
                "08/28",
                "987",
                new BigDecimal("180.00")
        );

        MvcResult authResult = mockMvc.perform(post("/api/payments/authorize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(authRequest)))
                .andExpect(status().isOk())
                .andReturn();

        String authResponse = authResult.getResponse().getContentAsString();
        String transactionId = objectMapper.readTree(authResponse).get("transactionId").asText();

        // When - Try to refund without capturing
        Map<String, String> refundRequest = new HashMap<>();
        refundRequest.put("transactionId", transactionId);

        // Then - Should fail with bad request
        mockMvc.perform(post("/api/payments/refund")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(refundRequest)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Test 11: Authorization with Missing Card Number - Bad Request")
    void testAuthorizationMissingCardNumber() throws Exception {
        // Given - Request with null card number
        String invalidJson = "{\"cardExpiry\":\"12/28\",\"cvv\":\"123\",\"amount\":100.00}";

        // When & Then
        mockMvc.perform(post("/api/payments/authorize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidJson))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Test 12: Authorization with Invalid Card Format - Bad Request")
    void testAuthorizationInvalidCardFormat() throws Exception {
        // Given - Card number with invalid format (too short)
        PaymentRequest request = new PaymentRequest(
                "123",
                "12/28",
                "123",
                new BigDecimal("100.00")
        );

        // When & Then
        mockMvc.perform(post("/api/payments/authorize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Test 13: Authorization with Invalid Expiry Format - Bad Request")
    void testAuthorizationInvalidExpiryFormat() throws Exception {
        // Given - Invalid expiry format
        PaymentRequest request = new PaymentRequest(
                VALID_VISA,
                "13/2028",
                "123",
                new BigDecimal("100.00")
        );

        // When & Then
        mockMvc.perform(post("/api/payments/authorize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Test 14: Capture with Missing Transaction ID - Bad Request")
    void testCaptureMissingTransactionId() throws Exception {
        // Given - Empty request
        Map<String, String> captureRequest = new HashMap<>();

        // When & Then
        mockMvc.perform(post("/api/payments/capture")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(captureRequest)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Test 15: Get Transaction by ID - Success")
    void testGetTransactionById() throws Exception {
        // Given - Create a transaction (retry until authorized)
        String transactionId = null;
        for (int i = 0; i < 20; i++) {
            PaymentRequest authRequest = new PaymentRequest(
                    VALID_VISA,
                    "05/27",
                    "111",
                    new BigDecimal("125.00")
            );

            MvcResult authResult = mockMvc.perform(post("/api/payments/authorize")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(authRequest)))
                    .andExpect(status().isOk())
                    .andReturn();

            String authResponse = authResult.getResponse().getContentAsString();
            String status = objectMapper.readTree(authResponse).get("status").asText();
            
            if ("AUTHORIZED".equals(status)) {
                transactionId = objectMapper.readTree(authResponse).get("transactionId").asText();
                break;
            }
        }

        if (transactionId == null) {
            throw new RuntimeException("Failed to get authorized transaction after 20 attempts");
        }

        // When & Then
        mockMvc.perform(get("/api/payments/" + transactionId))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.id").value(transactionId))
                .andExpect(jsonPath("$.amount").value(125.00))
                .andExpect(jsonPath("$.status").value("AUTHORIZED"))
                .andExpect(jsonPath("$.type").value("AUTHORIZE"));
    }

    @Test
    @DisplayName("Test 16: Get Non-Existent Transaction - Not Found")
    void testGetNonExistentTransaction() throws Exception {
        // When & Then
        mockMvc.perform(get("/api/payments/non-existent-id"))
                .andExpect(status().isNotFound());
    }

    @Test
    @DisplayName("Test 17: Get Transaction History - Success")
    void testGetTransactionHistory() throws Exception {
        // Given - Create multiple transactions
        PaymentRequest request1 = new PaymentRequest(VALID_VISA, "12/27", "123", new BigDecimal("100.00"));
        PaymentRequest request2 = new PaymentRequest(VALID_MASTERCARD, "06/28", "456", new BigDecimal("200.00"));

        mockMvc.perform(post("/api/payments/authorize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request1)))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/payments/authorize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request2)))
                .andExpect(status().isOk());

        // When & Then
        mockMvc.perform(get("/api/payments/history"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$.length()").value(greaterThanOrEqualTo(2)));
    }

    @Test
    @DisplayName("Test 18: Complete Payment Flow - Authorize, Capture, Refund")
    void testCompletePaymentFlow() throws Exception {
        // Given
        PaymentRequest authRequest = new PaymentRequest(
                VALID_VISA,
                "12/30",
                "999",
                new BigDecimal("500.00")
        );

        // Step 1: Authorize
        MvcResult authResult = mockMvc.perform(post("/api/payments/authorize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(authRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("AUTHORIZED"))
                .andExpect(jsonPath("$.amount").value(500.00))
                .andReturn();

        String authResponse = authResult.getResponse().getContentAsString();
        String authTransactionId = objectMapper.readTree(authResponse).get("transactionId").asText();

        // Step 2: Capture
        Map<String, String> captureRequest = new HashMap<>();
        captureRequest.put("transactionId", authTransactionId);

        MvcResult captureResult = mockMvc.perform(post("/api/payments/capture")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(captureRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CAPTURED"))
                .andExpect(jsonPath("$.amount").value(500.00))
                .andReturn();

        String captureResponse = captureResult.getResponse().getContentAsString();
        String captureTransactionId = objectMapper.readTree(captureResponse).get("transactionId").asText();

        // Step 3: Refund
        Map<String, String> refundRequest = new HashMap<>();
        refundRequest.put("transactionId", captureTransactionId);

        mockMvc.perform(post("/api/payments/refund")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(refundRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("REFUNDED"))
                .andExpect(jsonPath("$.amount").value(500.00));
    }
}

// Made with Bob