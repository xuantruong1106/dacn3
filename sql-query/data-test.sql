INSERT INTO accounts (id, username, passwd, phone, address, creator)
VALUES 
    (1, 'john_doe', 'password123', '1234567890', '123 Main St', 0),
    (2, 'jane_doe', 'securepass', '0987654321', '456 Elm St', 0);

INSERT INTO cards (id, id_account, card_number, card_holder_name, pin, cvv, total_amount)
VALUES 
    (1, 1, '1234567812345678', 'John Doe', '123456', '123', 1000.00),
    (2, 2, '8765432187654321', 'Jane Doe', '654321', '456', 2000.00);


INSERT INTO savings (id, id_account, goal_name, goal_amount, current_amount, deadline)
VALUES 
    (1, 1, 'Car Savings', 15000.00, 2000.00, '2025-12-31'),
    (2, 2, 'Vacation Fund', 5000.00, 1000.00, '2025-06-30');


INSERT INTO notifications (id, id_account, messages)
VALUES 
    (1, 1, 'Your balance is low.'),
    (2, 2, 'Your goal is 50% completed.');


INSERT INTO categories (id, type_category, name_category, icon, note, id_card)
VALUES 
    (1, 0, 'Groceries', '🛒', 'Monthly grocery shopping', 1),
    (2, 1, 'Entertainment', '🎮', 'Gaming expenses', 2);


INSERT INTO transactions (id, type_transaction, transaction_hash, account_receiver, name_receiver, sender_id, sender_name, amount, messages, category_id, card_id)
VALUES 
    (1, 0, 'tx123abc', '5678901234', 'Store A', '1234567890', 'John Doe', 50.00, 'Grocery purchase', 1, 1),
    (2, 1, 'tx456def', '0987654321', 'John Smith', '8765432187654321', 'Jane Doe', 100.00, 'Game purchase', 2, 2);
