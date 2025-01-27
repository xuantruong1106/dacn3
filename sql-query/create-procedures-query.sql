CREATE OR REPLACE PROCEDURE getTransactions(IN account_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Truy vấn giao dịch của tài khoản
    PERFORM 
        t.id AS transaction_id,
        t.type_transaction,
        t.transaction_hash,
        t.account_receiver,
        t.name_receiver,
        t.sender_id,
        t.sender_name,
        t.amount,
        t.messages,
        t.timestamp,
        t.category_id,
        t.card_id,
        c.card_number,
        c.card_holder_name,
        a.username AS account_owner
    FROM 
        transactions t
    INNER JOIN 
        cards c ON t.card_id = c.id
    INNER JOIN 
        accounts a ON c.id_account = a.id
    WHERE 
        a.id = account_id;

    -- Bạn có thể sử dụng RAISE NOTICE để hiển thị kết quả
    RAISE NOTICE 'Transactions fetched for account_id: %', account_id;
END;
$$;
