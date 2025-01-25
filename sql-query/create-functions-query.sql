-- ====================
-- Function: showCategory
-- ====================
CREATE OR REPLACE FUNCTION showCategory(id_card INT)
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
CREATE OR REPLACE FUNCTION getNameCategory(id_category INT)
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
CREATE OR REPLACE FUNCTION updateBalanceAfterTransaction(card_id INT, amount NUMERIC)
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
CREATE OR REPLACE FUNCTION sendNotification(id_account INT, message TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO notifications (id_account, message, sent_at)
    VALUES (id_account, message, NOW());
END;
$$ LANGUAGE plpgsql;

-- ====================
-- Function: getNotifications
-- ====================
CREATE OR REPLACE FUNCTION getNotifications(id_account INT)
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
CREATE OR REPLACE FUNCTION deleteNotification(notificationId INT)
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
