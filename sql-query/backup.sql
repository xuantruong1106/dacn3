PGDMP      )                }            dacn3    16.6    16.6 3    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
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
                        false    2                       1255    17446 %   check_account_credentials(text, text)    FUNCTION     �  CREATE FUNCTION public.check_account_credentials(input_phone text, input_password text) RETURNS integer
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
       public          postgres    false            �            1255    17367 2   check_balance_before_transaction(integer, numeric)    FUNCTION     �  CREATE FUNCTION public.check_balance_before_transaction(card_id integer, transactionamount numeric) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
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
$$;
 c   DROP FUNCTION public.check_balance_before_transaction(card_id integer, transactionamount numeric);
       public          postgres    false                       1255    17516 J   create_account_and_card(text, text, text, text, text, text, integer, text)    FUNCTION     X  CREATE FUNCTION public.create_account_and_card(p_username text, p_password text, p_card_number text, p_cvv text, p_phone text, p_address text, p_creator integer DEFAULT 0, p_pin text DEFAULT NULL::text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$ 
DECLARE
    new_account_id INT;
    hashed_password TEXT;
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
    INSERT INTO accounts (username, passwd, phone, address, creator, time_created, time_updated)
    VALUES (p_username, hashed_password, p_phone, p_address, p_creator, NOW(), NOW())
    RETURNING id INTO new_account_id;

    -- Tạo thẻ cho tài khoản mới
    INSERT INTO cards (id_account, card_number, cvv, time_created, time_updated)
    VALUES (new_account_id, p_card_number, p_cvv, NOW(), NOW());

    RETURN TRUE;
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'Duplicate entry detected for username or card number';
        RETURN FALSE;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
        RETURN FALSE;
END;
$$;
 �   DROP FUNCTION public.create_account_and_card(p_username text, p_password text, p_card_number text, p_cvv text, p_phone text, p_address text, p_creator integer, p_pin text);
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
       public          postgres    false                       1255    17381 #   get_basic_transaction_info(integer)    FUNCTION     �  CREATE FUNCTION public.get_basic_transaction_info(account_id integer) RETURNS TABLE(transaction_id integer, type_transaction integer, transaction_amount numeric, category_name text, icon text, message text)
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
       public          postgres    false                       1255    17374    get_transactions(integer)    FUNCTION     7  CREATE FUNCTION public.get_transactions(account_id integer) RETURNS TABLE(transaction_id integer, type_transaction integer, transaction_hash character varying, account_receiver character varying, name_receiver character varying, sender_id character varying, sender_name character varying, amount numeric, messages text, timestamps timestamp with time zone, category_id integer, card_id integer, card_number character varying, card_holder_name character varying, account_owner text)
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
       public          postgres    false                       1255    17580    get_user_and_card_info(integer)    FUNCTION       CREATE FUNCTION public.get_user_and_card_info(account_id integer) RETURNS TABLE(username text, phone text, address text, card_number text, cvv text, expiration_date timestamp without time zone, total_amount numeric)
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
       public          postgres    false            �            1255    17372 �   insert_transaction(integer, character varying, character varying, character varying, character varying, character varying, numeric, text, timestamp without time zone, integer, integer)    FUNCTION     P  CREATE FUNCTION public.insert_transaction(type_transaction integer, transaction_hash character varying, account_receiver character varying, name_receiver character varying, sender_id character varying, sender_name character varying, amount numeric, mess text, time_transtion timestamp without time zone, category_id integer, card_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
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
$$;
 U  DROP FUNCTION public.insert_transaction(type_transaction integer, transaction_hash character varying, account_receiver character varying, name_receiver character varying, sender_id character varying, sender_name character varying, amount numeric, mess text, time_transtion timestamp without time zone, category_id integer, card_id integer);
       public          postgres    false                       1255    17369     send_notification(integer, text)    FUNCTION     �   CREATE FUNCTION public.send_notification(id_account integer, message text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO notifications (id_account, message, sent_at)
    VALUES (id_account, message, NOW());
END;
$$;
 J   DROP FUNCTION public.send_notification(id_account integer, message text);
       public          postgres    false                       1255    17365    show_category(integer)    FUNCTION     �  CREATE FUNCTION public.show_category(id_card integer) RETURNS TABLE(id integer, type_category integer, name_category text, icon text, note text, time_created timestamp without time zone, time_updated timestamp without time zone)
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
          public          postgres    false    222            �            1259    17448    cards_id_seq    SEQUENCE     u   CREATE SEQUENCE public.cards_id_seq
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
    total_amount numeric(15,2) DEFAULT 0.00,
    time_created timestamp without time zone DEFAULT now(),
    time_updated timestamp without time zone DEFAULT now(),
    expiration_date timestamp without time zone DEFAULT (CURRENT_TIMESTAMP + '5 years'::interval)
);
    DROP TABLE public.cards;
       public         heap    postgres    false    223            �            1259    17328 
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
       public         heap    postgres    false    222            �            1259    17315    notifications    TABLE     �   CREATE TABLE public.notifications (
    id integer NOT NULL,
    id_account integer NOT NULL,
    messages text NOT NULL,
    sent_at timestamp without time zone DEFAULT now()
);
 !   DROP TABLE public.notifications;
       public         heap    postgres    false            �            1259    17302    savings    TABLE     �   CREATE TABLE public.savings (
    id integer NOT NULL,
    id_account integer NOT NULL,
    goal_name text NOT NULL,
    goal_amount numeric(15,2) NOT NULL,
    current_amount numeric(15,2) DEFAULT 0.00,
    deadline timestamp without time zone
);
    DROP TABLE public.savings;
       public         heap    postgres    false            �            1259    17343    transactions    TABLE     T  CREATE TABLE public.transactions (
    id integer NOT NULL,
    type_transaction integer NOT NULL,
    transaction_hash character varying(256) NOT NULL,
    account_receiver character varying(255) NOT NULL,
    name_receiver character varying(255) NOT NULL,
    sender_id character varying(255) NOT NULL,
    sender_name character varying(255) NOT NULL,
    amount numeric(10,2) NOT NULL,
    messages text,
    "timestamp" timestamp with time zone DEFAULT now(),
    category_id integer,
    card_id integer NOT NULL,
    CONSTRAINT transactions_amount_check CHECK ((amount >= (0)::numeric))
);
     DROP TABLE public.transactions;
       public         heap    postgres    false            �           2604    17443    accounts id    DEFAULT     j   ALTER TABLE ONLY public.accounts ALTER COLUMN id SET DEFAULT nextval('public.accounts_id_seq'::regclass);
 :   ALTER TABLE public.accounts ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    222    216            }          0    17273    accounts 
   TABLE DATA           v   COPY public.accounts (id, username, passwd, phone, address, time_created, time_updated, creator, updater) FROM stdin;
    public          postgres    false    216   [       ~          0    17285    cards 
   TABLE DATA           |   COPY public.cards (id, id_account, card_number, cvv, total_amount, time_created, time_updated, expiration_date) FROM stdin;
    public          postgres    false    217   �\       �          0    17328 
   categories 
   TABLE DATA           n   COPY public.categories (id, type_category, name_category, icon, note, time_created, time_updated) FROM stdin;
    public          postgres    false    220   c]       �          0    17315    notifications 
   TABLE DATA           J   COPY public.notifications (id, id_account, messages, sent_at) FROM stdin;
    public          postgres    false    219   �^                 0    17302    savings 
   TABLE DATA           c   COPY public.savings (id, id_account, goal_name, goal_amount, current_amount, deadline) FROM stdin;
    public          postgres    false    218   �^       �          0    17343    transactions 
   TABLE DATA           �   COPY public.transactions (id, type_transaction, transaction_hash, account_receiver, name_receiver, sender_id, sender_name, amount, messages, "timestamp", category_id, card_id) FROM stdin;
    public          postgres    false    221   �^       �           0    0    accounts_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.accounts_id_seq', 1248, true);
          public          postgres    false    222            �           0    0    cards_id_seq    SEQUENCE SET     :   SELECT pg_catalog.setval('public.cards_id_seq', 5, true);
          public          postgres    false    223            �           2606    17282    accounts accounts_pkey 
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
       public            postgres    false    220            �           2606    17322     notifications notifications_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.notifications DROP CONSTRAINT notifications_pkey;
       public            postgres    false    219            �           2606    17309    savings savings_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.savings
    ADD CONSTRAINT savings_pkey PRIMARY KEY (id);
 >   ALTER TABLE ONLY public.savings DROP CONSTRAINT savings_pkey;
       public            postgres    false    218            �           2606    17352    transactions transactions_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);
 H   ALTER TABLE ONLY public.transactions DROP CONSTRAINT transactions_pkey;
       public            postgres    false    221            �           2606    17354 .   transactions transactions_transaction_hash_key 
   CONSTRAINT     u   ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_transaction_hash_key UNIQUE (transaction_hash);
 X   ALTER TABLE ONLY public.transactions DROP CONSTRAINT transactions_transaction_hash_key;
       public            postgres    false    221            �           2606    17297    cards fk_account    FK CONSTRAINT     �   ALTER TABLE ONLY public.cards
    ADD CONSTRAINT fk_account FOREIGN KEY (id_account) REFERENCES public.accounts(id) ON DELETE CASCADE;
 :   ALTER TABLE ONLY public.cards DROP CONSTRAINT fk_account;
       public          postgres    false    216    217    4824            �           2606    17310    savings fk_account    FK CONSTRAINT     �   ALTER TABLE ONLY public.savings
    ADD CONSTRAINT fk_account FOREIGN KEY (id_account) REFERENCES public.accounts(id) ON DELETE CASCADE;
 <   ALTER TABLE ONLY public.savings DROP CONSTRAINT fk_account;
       public          postgres    false    218    216    4824            �           2606    17323    notifications fk_account    FK CONSTRAINT     �   ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_account FOREIGN KEY (id_account) REFERENCES public.accounts(id) ON DELETE CASCADE;
 B   ALTER TABLE ONLY public.notifications DROP CONSTRAINT fk_account;
       public          postgres    false    216    4824    219            �           2606    17360    transactions fk_card    FK CONSTRAINT     �   ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT fk_card FOREIGN KEY (card_id) REFERENCES public.cards(id) ON DELETE CASCADE;
 >   ALTER TABLE ONLY public.transactions DROP CONSTRAINT fk_card;
       public          postgres    false    217    4830    221            �           2606    17355    transactions fk_category    FK CONSTRAINT     �   ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT fk_category FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;
 B   ALTER TABLE ONLY public.transactions DROP CONSTRAINT fk_category;
       public          postgres    false    4836    221    220            }   �  x�}�Ko�@ ����+L��ܹ��QԢգ�n�*~}mR����۽�'�0!��*K�#a������27L���8wl	���i6G����;�(��q�Q��2]pFu���]��D�3"���"djQ	6~P0x�:�
�K+��:���5��p���(5�n��4ݍ{	s ?����=�I/Jc�+2�9�S���7�/*ˠ�D�3�tɗ��N�o'[�^�m\o?$��g��<J?��kz�����&�,lB댋G�5�ɪNUwU���VT��-�C�Yꋉ��ӯ�:�l��q
�V��ɡ��ؗ/��)� Q"L�9C�E>�O���1N�NMN���*ŏ��%�.��L���"�����V�r��E�SG˲7�olOGʰ� ��vO%,�-� 5Md�G	}��a���|��      ~   �   x�}���0DϦ�m �?���:G��hW� �C�4�U�Y��u).",R �CpH��O��ѭ��DX�ר��N�S��ݲ���1�r�e:���[:.��>�m���6�����Ѿ�LD_иB�      �     x��ѱN�0��y
OLm�8		�i�L0�X�ZM�*�)�X 	$�X��Yx&x.�va�`K���O>'&KU��DS��:<S_����jt�d`=#/KZ,N�t�db��c�OJ��ôf���A��S��e�x��$�zz�;��uE�;�0� �l��WuD+���9����
s�vz;��*QǶ�~-�ݛx��Z��sn!�cP[�@�^ڿ�`E虧F�ߪ� ��.�"Mp�I�X�W;��5:��ݍ=DQ��k��      �      x������ � �            x������ � �      �   n   x����0��Q���~���1400R��H�V��f�;rBBt4*����D�m��ACO�(��T�jK�Ͻm��q`�oY	�d/6G�%��6%�q���ι�l�     