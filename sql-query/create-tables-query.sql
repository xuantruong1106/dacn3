-- ====================
-- Table: accounts
-- ====================
CREATE TABLE accounts (
    id serial PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    passwd TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    time_created TIMESTAMP DEFAULT NOW(),
    time_updated TIMESTAMP DEFAULT NOW(),
    creator INT DEFAULT 0,
    updater INT
);

-- ====================
-- Table: cards
-- ====================
CREATE TABLE cards (
    id serial PRIMARY KEY,
    id_account INT NOT NULL,
    card_number TEXT NOT NULL UNIQUE,
    card_holder_name TEXT NOT NULL,
    pin TEXT,
    cvv TEXT NOT NULL,
    total_amount NUMERIC(15, 2) DEFAULT 0.00,
    time_created TIMESTAMP DEFAULT NOW(),
    time_updated TIMESTAMP DEFAULT NOW(),
	expiration_date TIMESTAMP DEFAULT (CURRENT_TIMESTAMP + INTERVAL '5 years');
    CONSTRAINT fk_account FOREIGN KEY (id_account) REFERENCES accounts (id) ON DELETE CASCADE
);

-- ====================
-- Table: savings
-- ====================
CREATE TABLE savings (
    id serial PRIMARY KEY,
    id_account INT NOT NULL,
    goal_name TEXT NOT NULL,
    goal_amount NUMERIC(15, 2) NOT NULL,
    current_amount NUMERIC(15, 2) DEFAULT 0.00,
    deadline TIMESTAMP,
    CONSTRAINT fk_account FOREIGN KEY (id_account) REFERENCES accounts (id) ON DELETE CASCADE
);

-- ====================
-- Table: notifications
-- ====================
CREATE TABLE notifications (
    id serial PRIMARY KEY,
    id_account INT NOT NULL,
    messages TEXT NOT NULL,
    sent_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT fk_account FOREIGN KEY (id_account) REFERENCES accounts (id) ON DELETE CASCADE
);

-- ====================
-- Table: categories
-- ====================
CREATE TABLE categories (
    id serial PRIMARY KEY,
    type_category INT NOT NULL CHECK (type_category IN (0, 1)),
    name_category TEXT NOT NULL,
    icon TEXT,
    note TEXT,
    time_created TIMESTAMP DEFAULT NOW(),
    time_updated TIMESTAMP DEFAULT NOW(),
);

-- ====================
-- Table: transactions
-- ====================
CREATE TABLE transactions (
    id serial PRIMARY KEY,
    type_transaction INT NOT NULL CHECK (type_transaction IN (1, 2)),
    transaction_hash VARCHAR(256) NOT NULL UNIQUE,
    account_receiver VARCHAR(255) NOT NULL,
    name_receiver VARCHAR(255) NOT NULL,
    sender_id VARCHAR(255) NOT NULL,
    sender_name VARCHAR(255) NOT NULL,
    amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    messages TEXT,
    timestamps TIMESTAMPTZ DEFAULT NOW(),
    category_id INT,
    card_id INT NOT NULL,
    CONSTRAINT fk_category FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
    CONSTRAINT fk_card FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE
);


ALTER TABLE transactions
DROP CONSTRAINT transactions_type_transaction_check;





