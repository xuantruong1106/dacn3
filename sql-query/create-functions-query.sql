-- ====================
-- Function: showCategory
-- ====================
CREATE OR REPLACE FUNCTION show_category(id_card INT)
RETURNS TABLE(
    id INT,
    type_category INT,
    name_category TEXT,
    icon TEXT,
    note TEXT,
    time_created TIMESTAMP,
    time_updated TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT id, type_category, name_category, icon, note, time_created, time_updated
    FROM categories
    WHERE id_card = id_card
    ORDER BY time_created DESC;
END;
$$ LANGUAGE plpgsql;

-- ====================
-- Function: getNameCategory
-- ====================
CREATE OR REPLACE FUNCTION get_name_category(id_category INT)
RETURNS TEXT AS $$
DECLARE
    category_name TEXT;
BEGIN
    SELECT name_category INTO category_name
    FROM categories
    WHERE id = id_category;

    RETURN category_name;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Category not found';
END;
$$ LANGUAGE plpgsql;

-- ====================
-- Function: checkBalanceBeforeTransaction
-- ====================
CREATE OR REPLACE FUNCTION checkBalanceBeforeTransaction(card_id INT, transactionAmount NUMERIC)
RETURNS BOOLEAN AS $$
DECLARE
    current_balance NUMERIC;
BEGIN
    SELECT total_amount INTO current_balance
    FROM cards
    WHERE id = card_id;

    IF current_balance >= transactionAmount THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ====================
-- Function: updateBalanceAfterTransaction
-- ====================
CREATE OR REPLACE FUNCTION update_blance_after_transaction(card_id INT, amount NUMERIC)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE cards
    SET total_amount = total_amount - amount,
        time_updated = NOW()
    WHERE id = card_id;

    IF FOUND THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ====================
-- Function: sendNotification
-- ====================
CREATE OR REPLACE FUNCTION send_notification(id_account INT, message TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO notifications (id_account, message, sent_at)
    VALUES (id_account, message, NOW());
END;
$$ LANGUAGE plpgsql;

-- ====================
-- Function: getNotifications
-- ====================
CREATE OR REPLACE FUNCTION get_notifications(id_account INT)
RETURNS TABLE(
    id INT,
    message TEXT,
    sent_at TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT id, message, sent_at
    FROM notifications
    WHERE id_account = id_account
    ORDER BY sent_at DESC;
END;
$$ LANGUAGE plpgsql;

-- ====================
-- Function: deleteNotification
-- ====================
CREATE OR REPLACE FUNCTION delete_notification(notificationId INT)
RETURNS BOOLEAN AS $$
BEGIN
    DELETE FROM notifications
    WHERE id = notificationId;

    IF FOUND THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ====================
-- Function: insert_transaction
-- ====================
CREATE OR REPLACE FUNCTION insert_transaction(
    type_transaction INT,
    transaction_hash VARCHAR,
    account_receiver VARCHAR,
    name_receiver VARCHAR,
    sender_id VARCHAR,
    sender_name VARCHAR,
    amount NUMERIC,
    mess TEXT,
    time_transtion TIMESTAMP,
    category_id INT,
    card_id INT
)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO transactions (
        type_transaction, transaction_hash, account_receiver, name_receiver,
        sender_id, sender_name, amount, mess, time_transtion, category_id, card_id
    ) VALUES (
        type_transaction, transaction_hash, account_receiver, name_receiver,
        sender_id, sender_name, amount, mess, time_transtion, category_id, card_id
    );

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION get_transactions(account_id INT)
RETURNS TABLE (
    transaction_id INT,
    type_transaction INT,
    transaction_hash VARCHAR,
    account_receiver VARCHAR,
    name_receiver VARCHAR,
    sender_id VARCHAR,
    sender_name VARCHAR,
    amount NUMERIC,
    messages TEXT,
    timestamps TIMESTAMPTZ,
    category_id INT,
    card_id INT,
    card_number VARCHAR,
    card_holder_name VARCHAR,
    account_owner TEXT
) 
LANGUAGE sql
AS $$
    SELECT 
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
$$;


CREATE OR REPLACE FUNCTION get_user_and_card_info(account_id INT)
RETURNS TABLE (
    username TEXT,
    phone TEXT,
    address TEXT,
    card_number TEXT,
    card_holder_name TEXT,
    total_amount NUMERIC(15, 2)
) 
LANGUAGE sql
AS $$
    SELECT
		a.id
        a.username, 
        a.phone, 
        a.address, 
        c.card_number, 
        c.card_holder_name, 
        c.total_amount
    FROM 
        accounts a
    INNER JOIN 
        cards c ON a.id = c.id_account
    WHERE 
        a.id = account_id;
$$;


CREATE OR REPLACE FUNCTION get_basic_transaction_info(
    account_id INT
)
RETURNS TABLE(
    transaction_id INT,
    type_transaction TEXT,
    transaction_amount NUMERIC(10, 2),
    category_name TEXT,
	icon TEXT,
    message TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id AS transaction_id,
        CASE t.type_transaction
            WHEN 0 THEN 'Income'
            WHEN 1 THEN 'Expense'
        END AS type_transaction,
        t.amount AS transaction_amount,
        c.name_category AS category_name,
		c.icon AS icon,
        t.messages AS message
    FROM 
        transactions t
    LEFT JOIN 
        categories c ON t.category_id = c.id
    INNER JOIN 
        cards ca ON t.card_id = ca.id
    WHERE 
        ca.id_account = account_id; -- Chỉ lấy giao dịch thuộc tài khoản được chỉ định
END;
$$ LANGUAGE plpgsql;
