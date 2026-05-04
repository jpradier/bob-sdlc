package com.demo.payment.model;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, String> {
    
    List<Transaction> findTop20ByOrderByCreatedAtDesc();
    
    Optional<Transaction> findByParentTransactionIdAndType(String parentTransactionId, TransactionType type);
}

// Made with Bob
