PGDMP                      }            dacn3    16.6    16.6 D    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    17272    dacn3    DATABASE     }   CREATE DATABASE dacn3 WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Vietnamese_Vietnam.1252';
    DROP DATABASE dacn3;
                postgres    false                        3079    17402    pgcrypto 	   EXTENSION     <   CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
    DROP EXTENSION pgcrypto;
                   false            �           0    0    EXTENSION pgcrypto    COMMENT     <   COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';
                        false    2                       1255    17446 %   check_account_credentials(text, text)    FUNCTION     �  CREATE FUNCTION public.check_account_credentials(input_phone text, input_password text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
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
$$;
 W   DROP FUNCTION public.check_account_credentials(input_phone text, input_password text);
       public          postgres    false            #           1255    17595    check_balance(integer, numeric)    FUNCTION     �  CREATE FUNCTION public.check_balance(account_id integer, amount numeric) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE balance NUMERIC(23,0);
BEGIN
    -- Lấy số dư của tài khoản
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
$$;
 H   DROP FUNCTION public.check_balance(account_id integer, amount numeric);
       public          postgres    false            $           1255    17585 B   create_account_and_card3(text, text, text, text, text, text, text)    FUNCTION     �  CREATE FUNCTION public.create_account_and_card3(p_username text, p_password text, p_card_number text, p_private_key text, p_cvv text, p_phone text, p_address text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$ 
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
    INSERT INTO cards (id_account, card_number, private_key, cvv)
    VALUES 				(new_account_id, p_card_number, p_private_key, p_cvv);

    RETURN TRUE;
EXCEPTION
    WHEN unique_violation THEN
        RETURN FALSE; -- Trả về FALSE nếu username hoặc card_number trùng
END;
$$;
 �   DROP FUNCTION public.create_account_and_card3(p_username text, p_password text, p_card_number text, p_private_key text, p_cvv text, p_phone text, p_address text);
       public          postgres    false            �            1255    17371    delete_notification(integer)    FUNCTION       CREATE FUNCTION public.delete_notification(notificationid integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM notifications
    WHERE id = notificationId;

    IF FOUND THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$;
 B   DROP FUNCTION public.delete_notification(notificationid integer);
       public          postgres    false                       1255    17730    get_all_categories()    FUNCTION     �   CREATE FUNCTION public.get_all_categories() RETURNS TABLE(category_id integer, category_name text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT id AS category_id, name_category AS category_name FROM categories;
END;
$$;
 +   DROP FUNCTION public.get_all_categories();
       public          postgres    false                       1255    17381 #   get_basic_transaction_info(integer)    FUNCTION     �  CREATE FUNCTION public.get_basic_transaction_info(account_id integer) RETURNS TABLE(transaction_id integer, type_transaction integer, transaction_amount numeric, category_name text, icon text, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id AS transaction_id,
        t.type_transaction AS type_transaction,
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
$$;
 E   DROP FUNCTION public.get_basic_transaction_info(account_id integer);
       public          postgres    false                       1255    17587    get_cards_by_account(integer)    FUNCTION     K  CREATE FUNCTION public.get_cards_by_account(p_id_account integer) RETURNS TABLE(id integer, card_number text, private_key text, total_amount numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.card_number, c.private_key, c.total_amount
    FROM cards c
    WHERE c.id_account = p_id_account;
END;
$$;
 A   DROP FUNCTION public.get_cards_by_account(p_id_account integer);
       public          postgres    false            �            1255    17366    get_name_category(integer)    FUNCTION     [  CREATE FUNCTION public.get_name_category(id_category integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
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
$$;
 =   DROP FUNCTION public.get_name_category(id_category integer);
       public          postgres    false            �            1255    17370    get_notifications(integer)    FUNCTION     =  CREATE FUNCTION public.get_notifications(id_account integer) RETURNS TABLE(id integer, message text, sent_at timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT id, message, sent_at
    FROM notifications
    WHERE id_account = id_account
    ORDER BY sent_at DESC;
END;
$$;
 <   DROP FUNCTION public.get_notifications(id_account integer);
       public          postgres    false                        1255    17733    get_receivername(integer)    FUNCTION     8  CREATE FUNCTION public.get_receivername(p_account_id integer) RETURNS TABLE(username text, card_number text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT a.username, c.card_number
    FROM accounts a
    JOIN cards c ON a.id = c.id_account
    WHERE a.id = p_account_id
    LIMIT 1;
END;
$$;
 =   DROP FUNCTION public.get_receivername(p_account_id integer);
       public          postgres    false            "           1255    17753 )   get_transaction_details(integer, integer)    FUNCTION     W  CREATE FUNCTION public.get_transaction_details(transaction_id integer, user_id integer) RETURNS TABLE(id integer, type_transaction integer, transaction_amount numeric, sender_name character varying, account_recevier character varying, name_receiver character varying, category_name character varying, icon text, description text, transaction_date timestamp without time zone, status character varying)
    LANGUAGE plpgsql
    AS $$
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
$$;
 W   DROP FUNCTION public.get_transaction_details(transaction_id integer, user_id integer);
       public          postgres    false                       1255    17374    get_transactions(integer)    FUNCTION     7  CREATE FUNCTION public.get_transactions(account_id integer) RETURNS TABLE(transaction_id integer, type_transaction integer, transaction_hash character varying, account_receiver character varying, name_receiver character varying, sender_id character varying, sender_name character varying, amount numeric, messages text, timestamps timestamp with time zone, category_id integer, card_id integer, card_number character varying, card_holder_name character varying, account_owner text)
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
 ;   DROP FUNCTION public.get_transactions(account_id integer);
       public          postgres    false                       1255    17729 *   get_transactions_in_current_month(integer)    FUNCTION     �  CREATE FUNCTION public.get_transactions_in_current_month(user_id integer) RETURNS TABLE(transaction_id integer, transaction_type integer, category_name text, card_balance numeric)
    LANGUAGE plpgsql
    AS $$
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
$$;
 I   DROP FUNCTION public.get_transactions_in_current_month(user_id integer);
       public          postgres    false                       1255    17580    get_user_and_card_info(integer)    FUNCTION       CREATE FUNCTION public.get_user_and_card_info(account_id integer) RETURNS TABLE(username text, phone text, address text, card_number text, cvv text, expiration_date timestamp without time zone, total_amount numeric)
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
 A   DROP FUNCTION public.get_user_and_card_info(account_id integer);
       public          postgres    false                       1255    17621 �   insert_transaction(integer, character varying, integer, character varying, integer, character varying, numeric, text, integer, integer)    FUNCTION     n  CREATE FUNCTION public.insert_transaction(type_transaction integer, transaction_hash character varying, account_receiver integer, name_receiver character varying, sender_id integer, sender_name character varying, amount numeric, mess text, category_id integer, card_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$

DECLARE
    receiver_card_id INT;

BEGIN
    -- Lấy ID của thẻ người nhận
    SELECT id INTO receiver_card_id 
    FROM cards 
    WHERE id_account = account_receiver
    LIMIT 1;

    -- Chèn giao dịch vào bảng transactions
    INSERT INTO transactions (
        type_transaction, transaction_hash, account_receiver, name_receiver,
        sender_id, sender_name, amount, messages, category_id, card_id
    ) VALUES (
        type_transaction, transaction_hash, account_receiver, name_receiver,
        sender_id, sender_name, amount, mess, category_id, card_id
    );

    -- Trừ số tiền từ thẻ của người gửi
    UPDATE cards 
    SET total_amount = total_amount - amount, time_updated = NOW()
    WHERE id = card_id;

    -- Cộng số tiền vào thẻ của người nhận
    UPDATE cards 
    SET total_amount = total_amount + amount, time_updated = NOW()
    WHERE id = receiver_card_id;

    RETURN TRUE;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Lỗi xảy ra: %', SQLERRM;
        RETURN FALSE;
END;
$$;
   DROP FUNCTION public.insert_transaction(type_transaction integer, transaction_hash character varying, account_receiver integer, name_receiver character varying, sender_id integer, sender_name character varying, amount numeric, mess text, category_id integer, card_id integer);
       public          postgres    false                       1255    17369     send_notification(integer, text)    FUNCTION     �   CREATE FUNCTION public.send_notification(id_account integer, message text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO notifications (id_account, message, sent_at)
    VALUES (id_account, message, NOW());
END;
$$;
 J   DROP FUNCTION public.send_notification(id_account integer, message text);
       public          postgres    false                       1255    17365    show_category(integer)    FUNCTION     �  CREATE FUNCTION public.show_category(id_card integer) RETURNS TABLE(id integer, type_category integer, name_category text, icon text, note text, time_created timestamp without time zone, time_updated timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT id, type_category, name_category, icon, note, time_created, time_updated
    FROM categories
    WHERE id_card = id_card
    ORDER BY time_created DESC;
END;
$$;
 5   DROP FUNCTION public.show_category(id_card integer);
       public          postgres    false            �            1255    17368 2   update_balance_after_transaction(integer, numeric)    FUNCTION     ^  CREATE FUNCTION public.update_balance_after_transaction(card_id integer, amount numeric) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
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
$$;
 X   DROP FUNCTION public.update_balance_after_transaction(card_id integer, amount numeric);
       public          postgres    false            !           1255    17751 +   update_user_info(integer, text, text, text)    FUNCTION     �  CREATE FUNCTION public.update_user_info(p_id integer, p_username text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE accounts
    SET username = COALESCE(p_username, username),
        phone = COALESCE(p_phone, phone),
        address = COALESCE(p_address, address)
    WHERE id = p_id;

    RETURN FOUND;
END;
$$;
 d   DROP FUNCTION public.update_user_info(p_id integer, p_username text, p_phone text, p_address text);
       public          postgres    false            �            1259    17273    accounts    TABLE     P  CREATE TABLE public.accounts (
    id integer NOT NULL,
    username text NOT NULL,
    passwd text NOT NULL,
    phone text NOT NULL,
    address text NOT NULL,
    time_created timestamp without time zone DEFAULT now(),
    time_updated timestamp without time zone DEFAULT now(),
    creator integer DEFAULT 0,
    updater integer
);
    DROP TABLE public.accounts;
       public         heap    postgres    false            �            1259    17442    accounts_id_seq    SEQUENCE     x   CREATE SEQUENCE public.accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.accounts_id_seq;
       public          postgres    false    216            �           0    0    accounts_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.accounts_id_seq OWNED BY public.accounts.id;
          public          postgres    false    220            �            1259    17448    cards_id_seq    SEQUENCE     u   CREATE SEQUENCE public.cards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE public.cards_id_seq;
       public          postgres    false            �            1259    17285    cards    TABLE     �  CREATE TABLE public.cards (
    id integer DEFAULT nextval('public.cards_id_seq'::regclass) NOT NULL,
    id_account integer NOT NULL,
    card_number text NOT NULL,
    cvv text NOT NULL,
    total_amount numeric(23,0) DEFAULT 0.00,
    time_created timestamp without time zone DEFAULT now(),
    time_updated timestamp without time zone DEFAULT now(),
    expiration_date timestamp without time zone DEFAULT (CURRENT_TIMESTAMP + '5 years'::interval),
    private_key text
);
    DROP TABLE public.cards;
       public         heap    postgres    false    221            �            1259    17328 
   categories    TABLE     �  CREATE TABLE public.categories (
    id integer DEFAULT nextval('public.accounts_id_seq'::regclass) NOT NULL,
    type_category integer NOT NULL,
    name_category text NOT NULL,
    icon text,
    note text,
    time_created timestamp without time zone DEFAULT now(),
    time_updated timestamp without time zone DEFAULT now(),
    CONSTRAINT categories_type_category_check CHECK ((type_category = ANY (ARRAY[0, 1])))
);
    DROP TABLE public.categories;
       public         heap    postgres    false    220            �            1259    17315    notifications    TABLE     �   CREATE TABLE public.notifications (
    id integer NOT NULL,
    id_account integer NOT NULL,
    messages text NOT NULL,
    sent_at timestamp without time zone DEFAULT now()
);
 !   DROP TABLE public.notifications;
       public         heap    postgres    false            �            1259    17723    receiver_card_id    TABLE     9   CREATE TABLE public.receiver_card_id (
    id integer
);
 $   DROP TABLE public.receiver_card_id;
       public         heap    postgres    false            �            1259    17735    savings_accounts    TABLE     �  CREATE TABLE public.savings_accounts (
    id integer NOT NULL,
    user_id integer NOT NULL,
    amount numeric(10,2) NOT NULL,
    interest_rate numeric(5,2) NOT NULL,
    term_months integer NOT NULL,
    start_date timestamp with time zone NOT NULL,
    end_date timestamp with time zone NOT NULL,
    description text,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
 $   DROP TABLE public.savings_accounts;
       public         heap    postgres    false            �            1259    17734    savings_accounts_id_seq    SEQUENCE     �   CREATE SEQUENCE public.savings_accounts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.savings_accounts_id_seq;
       public          postgres    false    226            �           0    0    savings_accounts_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.savings_accounts_id_seq OWNED BY public.savings_accounts.id;
          public          postgres    false    225            �            1259    17700    transactions    TABLE     �  CREATE TABLE public.transactions (
    id integer NOT NULL,
    type_transaction integer NOT NULL,
    transaction_hash character varying(256) NOT NULL,
    account_receiver integer NOT NULL,
    name_receiver character varying(255) NOT NULL,
    sender_id integer NOT NULL,
    sender_name character varying(255) NOT NULL,
    amount numeric(10,2) NOT NULL,
    messages text,
    timestamps timestamp with time zone DEFAULT now(),
    category_id integer,
    card_id integer NOT NULL,
    CONSTRAINT transactions_amount_check CHECK ((amount >= (0)::numeric)),
    CONSTRAINT transactions_type_transaction_check CHECK ((type_transaction = ANY (ARRAY[0, 1])))
);
     DROP TABLE public.transactions;
       public         heap    postgres    false            �            1259    17699    transactions_id_seq    SEQUENCE     �   CREATE SEQUENCE public.transactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.transactions_id_seq;
       public          postgres    false    223            �           0    0    transactions_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.transactions_id_seq OWNED BY public.transactions.id;
          public          postgres    false    222            �           2604    17443    accounts id    DEFAULT     j   ALTER TABLE ONLY public.accounts ALTER COLUMN id SET DEFAULT nextval('public.accounts_id_seq'::regclass);
 :   ALTER TABLE public.accounts ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    220    216            �           2604    17738    savings_accounts id    DEFAULT     z   ALTER TABLE ONLY public.savings_accounts ALTER COLUMN id SET DEFAULT nextval('public.savings_accounts_id_seq'::regclass);
 B   ALTER TABLE public.savings_accounts ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    226    225    226            �           2604    17703    transactions id    DEFAULT     r   ALTER TABLE ONLY public.transactions ALTER COLUMN id SET DEFAULT nextval('public.transactions_id_seq'::regclass);
 >   ALTER TABLE public.transactions ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    223    222    223            �          0    17273    accounts 
   TABLE DATA           v   COPY public.accounts (id, username, passwd, phone, address, time_created, time_updated, creator, updater) FROM stdin;
    public          postgres    false    216   z       �          0    17285    cards 
   TABLE DATA           �   COPY public.cards (id, id_account, card_number, cvv, total_amount, time_created, time_updated, expiration_date, private_key) FROM stdin;
    public          postgres    false    217   v{       �          0    17328 
   categories 
   TABLE DATA           n   COPY public.categories (id, type_category, name_category, icon, note, time_created, time_updated) FROM stdin;
    public          postgres    false    219   �|       �          0    17315    notifications 
   TABLE DATA           J   COPY public.notifications (id, id_account, messages, sent_at) FROM stdin;
    public          postgres    false    218   �}       �          0    17723    receiver_card_id 
   TABLE DATA           .   COPY public.receiver_card_id (id) FROM stdin;
    public          postgres    false    224   ~       �          0    17735    savings_accounts 
   TABLE DATA           �   COPY public.savings_accounts (id, user_id, amount, interest_rate, term_months, start_date, end_date, description, status, created_at) FROM stdin;
    public          postgres    false    226   #~       �          0    17700    transactions 
   TABLE DATA           �   COPY public.transactions (id, type_transaction, transaction_hash, account_receiver, name_receiver, sender_id, sender_name, amount, messages, timestamps, category_id, card_id) FROM stdin;
    public          postgres    false    223   @~       �           0    0    accounts_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.accounts_id_seq', 1286, true);
          public          postgres    false    220            �           0    0    cards_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.cards_id_seq', 34, true);
          public          postgres    false    221            �           0    0    savings_accounts_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.savings_accounts_id_seq', 1, false);
          public          postgres    false    225            �           0    0    transactions_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.transactions_id_seq', 34, true);
          public          postgres    false    222            �           2606    17282    accounts accounts_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);
 @   ALTER TABLE ONLY public.accounts DROP CONSTRAINT accounts_pkey;
       public            postgres    false    216            �           2606    17284    accounts accounts_username_key 
   CONSTRAINT     ]   ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_username_key UNIQUE (username);
 H   ALTER TABLE ONLY public.accounts DROP CONSTRAINT accounts_username_key;
       public            postgres    false    216            �           2606    17296    cards cards_card_number_key 
   CONSTRAINT     ]   ALTER TABLE ONLY public.cards
    ADD CONSTRAINT cards_card_number_key UNIQUE (card_number);
 E   ALTER TABLE ONLY public.cards DROP CONSTRAINT cards_card_number_key;
       public            postgres    false    217            �           2606    17294    cards cards_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public.cards
    ADD CONSTRAINT cards_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.cards DROP CONSTRAINT cards_pkey;
       public            postgres    false    217            �           2606    17337    categories categories_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);
 D   ALTER TABLE ONLY public.categories DROP CONSTRAINT categories_pkey;
       public            postgres    false    219            �           2606    17322     notifications notifications_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.notifications DROP CONSTRAINT notifications_pkey;
       public            postgres    false    218            �           2606    17744 &   savings_accounts savings_accounts_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.savings_accounts
    ADD CONSTRAINT savings_accounts_pkey PRIMARY KEY (id);
 P   ALTER TABLE ONLY public.savings_accounts DROP CONSTRAINT savings_accounts_pkey;
       public            postgres    false    226            �           2606    17710    transactions transactions_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);
 H   ALTER TABLE ONLY public.transactions DROP CONSTRAINT transactions_pkey;
       public            postgres    false    223            �           2606    17712 .   transactions transactions_transaction_hash_key 
   CONSTRAINT     u   ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_transaction_hash_key UNIQUE (transaction_hash);
 X   ALTER TABLE ONLY public.transactions DROP CONSTRAINT transactions_transaction_hash_key;
       public            postgres    false    223            �           1259    17750    idx_savings_accounts_user_id    INDEX     \   CREATE INDEX idx_savings_accounts_user_id ON public.savings_accounts USING btree (user_id);
 0   DROP INDEX public.idx_savings_accounts_user_id;
       public            postgres    false    226            �           2606    17297    cards fk_account    FK CONSTRAINT     �   ALTER TABLE ONLY public.cards
    ADD CONSTRAINT fk_account FOREIGN KEY (id_account) REFERENCES public.accounts(id) ON DELETE CASCADE;
 :   ALTER TABLE ONLY public.cards DROP CONSTRAINT fk_account;
       public          postgres    false    217    216    4840            �           2606    17323    notifications fk_account    FK CONSTRAINT     �   ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_account FOREIGN KEY (id_account) REFERENCES public.accounts(id) ON DELETE CASCADE;
 B   ALTER TABLE ONLY public.notifications DROP CONSTRAINT fk_account;
       public          postgres    false    218    4840    216            �           2606    17718    transactions fk_card    FK CONSTRAINT     s   ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT fk_card FOREIGN KEY (card_id) REFERENCES public.cards(id);
 >   ALTER TABLE ONLY public.transactions DROP CONSTRAINT fk_card;
       public          postgres    false    217    223    4846            �           2606    17713    transactions fk_category    FK CONSTRAINT     �   ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT fk_category FOREIGN KEY (category_id) REFERENCES public.categories(id);
 B   ALTER TABLE ONLY public.transactions DROP CONSTRAINT fk_category;
       public          postgres    false    4850    219    223            �           2606    17745 .   savings_accounts savings_accounts_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.savings_accounts
    ADD CONSTRAINT savings_accounts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.accounts(id);
 X   ALTER TABLE ONLY public.savings_accounts DROP CONSTRAINT savings_accounts_user_id_fkey;
       public          postgres    false    4840    226    216            �   O  x�}��N�@���)�`�8����+�Z��

a�4mC�j/�������������H0��	�����|�`��eb��<�r(>_s9(�޷��<5o,cӡz��B�p��p���,f�Q�p&�7/E�d�E�LJ @:gDWD&DX�&a2V��B�a��SSO�DcG��n�c���6�\�V�E��Wy��-���R�v�����馣~�"�3�QeͬO'TQ�`���g�-�.c����4�1�{����N������x�u�o�u�j�8N�#8�
�v	c7�j�,WuP�j6��&Z�4���>UF����=UGX�'��d
%I�h��      �   C  x���K�\1E�ﭢ6P����,]MV������� ЁnB4:���r ��Ɂ�k���Q+٨tZg��� ?�  �ݩ�@/ԋ����K�&���|v
5V՚����#a�_d�%��Z����*��Nt2�<h{,�5l*fn�lI���o5j��ZDfG�/���a�X/�8*�_�w��Ep�Fd
���K�[������� "a� D�c��n#�{o邴Ā˪����姯��"��>�,`���u�������灯����P.�������ʧ&�.C9��!ճQI���a�}$Dϐޘ�e���NsMl50A�_��<� �C�      �     x��ѱN�0��y
OLm�8		�i�L0�X�ZM�*�)�X 	$�X��Yx&x.�va�`K���O>'&KU��DS��:<S_����jt�d`=#/KZ,N�t�db��c�OJ��ôf���A��S��e�x��$�zz�;��uE�;�0� �l��WuD+���9����
s�vz;��*QǶ�~-�ݛx��Z��sn!�cP[�@�^ڿ�`E虧F�ߪ� ��.�"Mp�I�X�W;��5:��ݍ=DQ��k��      �      x������ � �      �      x�36�����       �      x������ � �      �   �   x��α�0�ڞ�=��ﾝ��X 	����"��� ��	�S"�G6�����8=U#Q�H6�!-j-_c�6�M?����v���ѭ������-���y��1�^� ���0V��Q;�.&O�BW��`T��B @�J%E��	|���za%|�Z�eI0     