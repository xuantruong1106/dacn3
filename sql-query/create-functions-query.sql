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
    cvv TEXT,
    expiration_date TIMESTAMP,
    total_amount NUMERIC(15, 2)
) 
LANGUAGE sql
AS $$
    SELECT
        a.username, 
        a.phone, 
        a.address, 
        c.card_number, 
        c.cvv,
        c.expiration_date,
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

-- function check account with parameter is phone and pwd

CREATE OR REPLACE FUNCTION check_account_credentials(
    input_phone TEXT,
    input_password TEXT
) 
RETURNS INT AS $$
DECLARE
    account_id INT;
BEGIN
    -- Tìm ID của tài khoản nếu phone và password hợp lệ
    SELECT id INTO account_id
    FROM accounts 
    WHERE phone = input_phone 
      AND passwd = crypt(input_password, passwd);

    -- Trả về ID nếu tìm thấy, nếu không có thì trả về NULL
    RETURN account_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_passwd_current(
    user_id INT,
    input_password TEXT
) 
RETURNS BOOLEAN AS $$
DECLARE
    stored_passwd TEXT;
BEGIN
    -- Lấy mật khẩu đã lưu của user dựa trên user_id
    SELECT passwd INTO stored_passwd
    FROM accounts 
    WHERE id = user_id;

    -- Nếu không tìm thấy user, trả về FALSE
    IF stored_passwd IS NULL THEN
        RETURN FALSE;
    END IF;

    -- So sánh mật khẩu đã nhập với mật khẩu đã băm trong DB
    RETURN stored_passwd = crypt(input_password, stored_passwd);
END;
$$ LANGUAGE plpgsql;


-- create_account_and_card
CREATE OR REPLACE FUNCTION create_account_and_card3(
    p_username TEXT,
    p_password TEXT,
    p_card_number TEXT,
    p_cvv TEXT,
	p_phone TEXT,
    p_address TEXT
) 
RETURNS BOOLEAN AS $$ 
DECLARE
    new_account_id INT;
    hashed_password TEXT;
    encrypted_pin TEXT;
BEGIN
    -- Kiểm tra số điện thoại đã tồn tại chưa
    IF p_phone IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM accounts WHERE phone = p_phone) THEN
            RETURN FALSE; -- Số điện thoại đã tồn tại
        END IF;
    END IF;

    -- Mã hóa mật khẩu
    hashed_password := crypt(p_password, gen_salt('bf'));

    -- Tạo tài khoản mới
    INSERT INTO accounts (username, passwd, phone, address)
    VALUES (p_username, hashed_password, p_phone, p_address)
    RETURNING id INTO new_account_id;

    -- Tạo thẻ cho tài khoản mới
    INSERT INTO cards (id_account, card_number, cvv)
    VALUES 				(new_account_id, p_card_number, p_cvv);

    RETURN TRUE;
EXCEPTION
    WHEN unique_violation THEN
        RETURN FALSE; -- Trả về FALSE nếu username hoặc card_number trùng
END;
$$ LANGUAGE plpgsql;

SELECT * from create_account_and_card(
    'Ngyen2',  
    '12345',              
    '0356593937',  
    '1234',
	'1111111111',
	'Da nang'
);



CREATE OR REPLACE FUNCTION get_transactions_in_current_month(user_id INT)
RETURNS TABLE (
    transaction_id INT,
    transaction_type INT,
    category_name TEXT,
    card_balance NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id AS transaction_id,
        t.type_transaction AS transaction_type,
        c.name_category AS category_name,
        ca.total_amount AS card_balance
    FROM transactions t
    LEFT JOIN categories c ON t.category_id = c.id
    LEFT JOIN cards ca ON t.card_id = ca.id
    WHERE t.sender_id = user_id
    AND DATE_TRUNC('month', t.timestamps) = DATE_TRUNC('month', CURRENT_DATE);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_all_categories()
RETURNS TABLE (
    category_id INT,
    category_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT id AS category_id, name_category AS category_name FROM categories;
END;
$$ LANGUAGE plpgsql;


-- Edited function

CREATE OR REPLACE FUNCTION get_transactions_in_current_month(user_id INT)
RETURNS TABLE (
    transaction_id INT,
    transaction_type INT,
    category_name TEXT,
    card_balance NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id AS transaction_id,
        t.type_transaction AS transaction_type,
        c.name_category AS category_name,
        ca.total_amount AS card_balance
    FROM transactions t
    LEFT JOIN categories c ON t.category_id = c.id
    LEFT JOIN cards ca ON t.card_id = ca.id
    WHERE t.sender_id = user_id
    AND DATE_TRUNC('month', t.timestamp) = DATE_TRUNC('month', CURRENT_DATE);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_all_categories()
RETURNS TABLE (
    category_id INT,
    category_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT id AS category_id, name_category AS category_name FROM categories;
END;
$$ LANGUAGE plpgsql;

select * from get_transactions_in_current_month(1232)

CREATE OR REPLACE FUNCTION get_transaction_details(
  transaction_id INT,
  user_id INT
)
RETURNS TABLE (
  id INT,
  type_transaction INT,
  transaction_amount NUMERIC,
  sender_name VARCHAR,
  account_recevier VARCHAR,
  name_receiver VARCHAR,
  category_name VARCHAR,
  icon TEXT,
  description TEXT,
  transaction_date TIMESTAMP,
  status VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.id,
    t.type_transaction,
    t.amount,
    t.sender_name,
    t.account_receiver,
    t.name_receiver,
    c.name_category::VARCHAR,
    c.icon,
    t.messages,
    t.timestamp::TIMESTAMP,
    'Completed'::VARCHAR as status
  FROM transactions t
  JOIN categories c ON t.category_id = c.id
  WHERE t.id = transaction_id; -- Thêm dấu chấm phẩy còn thiếu ở đây
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_receivername(p_account_id INT)
RETURNS TABLE(username TEXT, card_number TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT a.username, c.card_number
    FROM accounts a
    JOIN cards c ON a.id = c.id_account
    WHERE a.id = p_account_id
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_receivername(p_account_id INT)
RETURNS TABLE(username TEXT, card_number TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT a.username, c.card_number
    FROM accounts a
    JOIN cards c ON a.id = c.id_account
    WHERE a.id = p_account_id
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_user_info(
    p_id INT,
    p_username TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$

CREATE OR REPLACE FUNCTION get_receivername(p_account_id INT)
RETURNS TABLE(username TEXT, card_number TEXT) AS $$
>>>>>>> Stashed changes
BEGIN
    UPDATE accounts
    SET username = COALESCE(p_username, username),
        phone = COALESCE(p_phone, phone),
        address = COALESCE(p_address, address)
    WHERE id = p_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_user_info(
    p_id INT,
    p_username TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE accounts
    SET username = COALESCE(p_username, username),
        phone = COALESCE(p_phone, phone),
        address = COALESCE(p_address, address)
    WHERE id = p_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_cards_by_account(p_id_account INTEGER)
RETURNS TABLE (
    id INTEGER,
    card_number TEXT,
    private_key TEXT,
    total_amount NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.card_number, c.private_key, c.total_amount
    FROM cards c
    WHERE c.id_account = p_id_account;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_balance(account_id INTEGER, amount NUMERIC(23,0))
RETURNS BOOLEAN AS $$
DECLARE 
    balance NUMERIC(23,0);
BEGIN
    -- Lấy tổng số dư của tài khoản
    SELECT COALESCE(SUM(total_amount), 0) 
    INTO balance
    FROM cards
    WHERE id_account = account_id;

    -- Kiểm tra số dư có đủ không
    IF balance >= amount THEN
        RETURN TRUE;  -- Đủ tiền
    ELSE
        RETURN FALSE; -- Không đủ tiền
    END IF;
END;
$$ LANGUAGE plpgsql;


