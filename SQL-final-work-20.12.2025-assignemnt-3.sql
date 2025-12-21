USE final_work_assignemnt_3_db;

--Задание:
--1. Восстановить базу данных с помощью скрипта (скрипт прилагается)
--1.1 Структура и данные базы данных изменению не подлежат (исключение - задание 2.3)

	CREATE TABLE users (
	id int PRIMARY KEY IDENTITY(1,1),
	name varchar(32) NOT NULL
);
    
CREATE TABLE user_accounts (
	id int PRIMARY KEY IDENTITY(1,1),
	user_id int NOT NULL,

	CONSTRAINT FK_user_accounts_user FOREIGN KEY (user_id) REFERENCES users(id)
);
    
CREATE TABLE transactions (
	id int PRIMARY KEY IDENTITY(1,1),
	account_from int NOT NULL,
	account_to int NOT NULL,
	amount real NOT NULL,
	trdate datetime NOT NULL,

	CONSTRAINT FK_transactions_user_account_from FOREIGN KEY (account_from) REFERENCES user_accounts(id),
	CONSTRAINT FK_transactions_user_account_to FOREIGN KEY (account_to) REFERENCES user_accounts(id),
);

GO

SET IDENTITY_INSERT users ON;
INSERT INTO users (id,name)
VALUES
	(10, 'Alice'),
	(11, 'Bob'),
	(12, 'Tom'),
	(13, 'Mike'),
	(14, 'Kate'),
	(15, 'Jerry');
SET IDENTITY_INSERT users OFF;

SET IDENTITY_INSERT user_accounts ON;
INSERT INTO user_accounts (id, user_id)
    VALUES
    (10, 10),
    (11, 10),
    (12, 11),
    (13, 11),
    (14, 12),
    (15, 12),
    (16, 13),
    (17, 14),
    (18, 15);
SET IDENTITY_INSERT user_accounts OFF;

SET IDENTITY_INSERT transactions ON;
INSERT INTO transactions (id, account_from, account_to, amount, trdate)
VALUES
    (1, 10, 11, 100.00, '2024-01-01 12:00:00'),
    (2, 11, 10, 50.00, '2024-01-05 12:00:00'),
    (3, 12, 10, 100.00, '2024-01-10 12:00:00'),
    (4, 13, 10, 100.00, '2024-01-15 12:00:00'),
    (5, 14, 10, 100.00, '2024-01-20 12:00:00'),
    (6, 15, 12, 100.00, '2024-01-25 12:00:00'),
    (7, 13, 12, 100.00, '2024-01-30 12:00:00'),
    (8, 11, 15, 50.00, '2024-02-05 12:00:00'),
    (9, 12, 10, 100.00, '2024-02-10 12:00:00'),
    (10, 13, 10, 200.00, '2024-02-15 12:00:00'),
    (11, 14, 11, 50.00, '2024-02-20 12:00:00'),
    (12, 11, 10, 100.00, '2024-02-25 12:00:00'),
    (13, 14, 11, 100.00, '2024-03-05 12:00:00'),
    (14, 12, 10, 100.00, '2024-03-10 12:00:00'),
    (15, 12, 10, 100.00, '2024-03-15 12:00:00'),
    (16, 11, 10, 100.00, '2024-03-20 12:00:00'),
    (17, 10, 11, 50.00, '2024-03-25 12:00:00');
SET IDENTITY_INSERT transactions OFF;



--2. Написать следующие запросы:

--2.1 Вывести пользователей, которые участвовали в транзакциях 
--    (Будьте внимательны! Транзакция может быть как входящей, так и исходящей)

SELECT *
FROM users u
WHERE EXISTS (
    SELECT *
    FROM user_accounts u_a
    JOIN transactions t 
        ON u_a.id = t.account_from
        OR u_a.id = t.account_to
    WHERE u.id = u_a.user_id
);

--2.2 По определённому счёту (id счёта можно определить в переменную) за каждый месяц вывести информацию 
--    о сумме входных и выходных транзакций, а также количество дней, в которые проходили транзакции
--Пример результирующей таблицы:
--| month    | incoming_amount | outgoing_amount | days_count |
---------------------------------------------------------------
--| January  | 400             | 250             | 4          |
--| February | 200             | 350             | 6          |

-- ####################################################################################
-- Тестирование результата суммы при сущестововании одинаковых дней транзакций в месяце
--DECLARE @ins_id int;

--INSERT INTO transactions (account_from, account_to, amount, trdate)
--VALUES (10, 11, 50.00, '2024-03-25 12:00:00');

--SET @ins_id = SCOPE_IDENTITY();

--SELECT
--    MONTH(t.trdate) AS [_month],
--    COUNT( DISTINCT DAY(t.trdate)) AS [_day]
--FROM transactions t
--GROUP BY MONTH(t.trdate)  -- Отлично работает, не считает последнюю строку в суму дней 
--                          --  месяца, так как день один и тот же


--DELETE FROM transactions
--WHERE id = @ins_id;
-- ####################################################################################


-- В таблицах все значения NOT NULL, проверка на NULL не нужна
DECLARE @some_id_of_user int = 11;

WITH 
    -- Месяц - количество дней(без повторений)
    months_days_cte AS (
        SELECT
            MONTH(t.trdate)                 AS [month_number],
            COUNT( DISTINCT DAY(t.trdate))  AS [counted_days]
        FROM transactions t
        GROUP BY MONTH(t.trdate)
    ), 

    -- Данные для отправителя (outcoming)
    accounts_from_data_cte AS (
        SELECT 
            MONTH(t.trdate)     AS [month_number],
            SUM(t.amount)       AS [counted_amount]
        FROM user_accounts u_a
        JOIN transactions t 
            ON u_a.id = t.account_from
        WHERE @some_id_of_user = u_a.user_id
        GROUP BY MONTH(t.trdate)
    ),

    -- Данные для получателя (incoming)
    accounts_to_data_cte AS (
        SELECT 
            MONTH(t.trdate)     AS [month_number],
            SUM(t.amount)       AS [counted_amount]
        FROM user_accounts u_a
        JOIN transactions t 
            ON u_a.id = t.account_to
        WHERE @some_id_of_user = u_a.user_id
        GROUP BY MONTH(t.trdate)
    )

SELECT 
    mdc.month_number                   AS [month],
    ISNULL(atdc.counted_amount, 0)     AS [incoming_amount],
    ISNULL(afdc.counted_amount, 0)     AS [outcoming_amount],
    mdc.counted_days                   AS [days_count]
FROM months_days_cte mdc
LEFT JOIN accounts_to_data_cte   atdc ON mdc.month_number = atdc.month_number
LEFT JOIN accounts_from_data_cte afdc ON mdc.month_number = afdc.month_number;



