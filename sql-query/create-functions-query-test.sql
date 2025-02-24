CREATE OR REPLACE FUNCTION create_account_and_card2(
    p_username TEXT,
    p_password TEXT,
    p_card_number TEXT,
    p_cvv TEXT,
    p_phone TEXT,
    p_address TEXT,
    p_creator INT DEFAULT 0
) 
RETURNS BOOLEAN AS $$ 
DECLARE
    new_account_id INT;
    hashed_password TEXT;
BEGIN
    -- Kiểm tra số điện thoại đã tồn tại chưa
    IF p_phone IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM accounts WHERE phone = p_phone) THEN
            RETURN "-- Số điện thoại đã tồn tại"; -- Số điện thoại đã tồn tại
        END IF;
    END IF;

    -- Mã hóa mật khẩu
    hashed_password := crypt(p_password, gen_salt('bf'));

    -- Tạo tài khoản mới
    INSERT INTO accounts (username, passwd, phone, address, creator)
    VALUES (p_username, hashed_password, p_phone, p_address, p_creator)
    RETURNING id INTO new_account_id;

    -- Tạo thẻ cho tài khoản mới
    INSERT INTO cards (id_account, card_number, cvv)
    VALUES 			(new_account_id, p_card_number, p_cvv);

    RETURN TRUE;
EXCEPTION
    WHEN unique_violation THEN
        RETURN "username hoặc card_number trùng"; -- Trả về FALSE nếu username hoặc card_number trùng
    WHEN OTHERS THEN
        RETURN "Bắt lỗi không xác định"; -- Bắt lỗi không xác định
END;
$$ LANGUAGE plpgsql;


SELECT * FROM create_account_and_card2(
    'Nguyen',  
    '12345',              
    '1212121212121212',  
    '123',
    '093282626342342',  -- Added missing comma
    'Da nang'
);

SELECT * FROM accounts WHERE phone = '093282626342342';
SELECT * FROM accounts WHERE username = 'Nguyen';
SELECT * FROM cards WHERE card_number = '1212121212121212';

