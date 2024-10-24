-- Запросы на основе многотабличной базы данных фитнес-клуба

-- Создание таблиц

CREATE TABLE instructors (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    section_id INT
);

CREATE TABLE sections (
    id SERIAL PRIMARY KEY,
    section_name VARCHAR(100),
    schedule TIME
);

CREATE TABLE visitors (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    mobile_operator VARCHAR(100)
);

CREATE TABLE visits (
    id SERIAL PRIMARY KEY,
    visitor_id INT,
    section_id INT,
    visit_date DATE,
    FOREIGN KEY (visitor_id) REFERENCES visitors(id),
    FOREIGN KEY (section_id) REFERENCES sections(id)
);

-- Запросы

-- 1. Запрос с ANY: Показать всех посетителей, которые посещали секции, начавшиеся раньше любой секции, в которую ходил хотя бы один инструктор
-- Этот запрос выбирает посетителей, которые посещали секции с более ранним расписанием, чем секции, в которые ходил хотя бы один инструктор.
SELECT v.first_name, v.last_name
FROM visitors v
WHERE v.id = ANY (
    SELECT vi.visitor_id
    FROM visits vi
    JOIN sections s ON vi.section_id = s.id
    WHERE s.schedule < ANY (
        SELECT s2.schedule
        FROM instructors i
        JOIN sections s2 ON i.section_id = s2.id
    )
);

-- 2. Запрос с SOME: Показать всех инструкторов, которые ведут секции, время занятий которых совпадает хотя бы с одной секцией, в которую ходили посетители с определённым мобильным оператором
-- Этот запрос выбирает инструкторов, которые ведут хотя бы одну секцию с таким же расписанием, как у секций, посещаемых посетителями с конкретным мобильным оператором.
SELECT i.first_name, i.last_name
FROM instructors i
WHERE i.section_id = SOME (
    SELECT s.id
    FROM sections s
    JOIN visits vi ON s.id = vi.section_id
    JOIN visitors v ON vi.visitor_id = v.id
    WHERE v.mobile_operator = 'Билайн' -- Замените на нужного оператора
);

-- 3. Запрос с EXISTS: Показать всех инструкторов, у которых есть секции
-- Этот запрос возвращает инструкторов, которые ведут секции.
SELECT i.first_name, i.last_name
FROM instructors i
WHERE EXISTS (
    SELECT 1
    FROM sections s
    WHERE s.id = i.section_id
);

-- 4. Запрос с EXISTS: Показать все секции, в которых были посещения
-- Этот запрос возвращает секции, в которых хотя бы один раз были посещения.
SELECT s.section_name
FROM sections s
WHERE EXISTS (
    SELECT 1
    FROM visits v
    WHERE v.section_id = s.id
);

-- 5. Запрос с ALL: Показать всех посетителей, которые посещали все секции, имеющие занятия до 12:00
-- Этот запрос выбирает посетителей, которые посещали все секции, занятия которых начинаются до 12:00.
SELECT v.first_name, v.last_name
FROM visitors v
WHERE v.id = ALL (
    SELECT vi.visitor_id
    FROM visits vi
    JOIN sections s ON vi.section_id = s.id
    WHERE s.schedule < '12:00:00'
);

-- 6. Запрос на сочетание ANY и ALL: Показать инструкторов, которые ведут все секции до 12:00 и хотя бы одну секцию в другое время
-- Этот запрос выбирает инструкторов, которые ведут все секции, начинающиеся до 12:00, и хотя бы одну секцию с другим временем.
SELECT i.first_name, i.last_name
FROM instructors i
WHERE i.section_id = ALL (
    SELECT s.id
    FROM sections s
    WHERE s.schedule < '12:00:00'
)
AND i.section_id = SOME (
    SELECT s.id
    FROM sections s
    WHERE s.schedule >= '12:00:00'
);

-- 7. Запрос с UNION: Получить имена всех инструкторов и посетителей (различные)
-- Этот запрос объединяет уникальные имена инструкторов и посетителей.
SELECT first_name, last_name
FROM instructors
UNION
SELECT first_name, last_name
FROM visitors;

-- 8. Запрос с UNION ALL: Получить имена всех инструкторов и посетителей (с повторениями)
-- Этот запрос объединяет имена инструкторов и посетителей, включая повторяющиеся значения.
SELECT first_name, last_name
FROM instructors
UNION ALL
SELECT first_name, last_name
FROM visitors;

-- 9. INNER JOIN: Показать всех посетителей и секции, которые они посещали
-- Этот запрос выбирает посетителей и секции, которые они посещали, используя внутреннее соединение.
SELECT v.first_name, v.last_name, s.section_name
FROM visitors v
INNER JOIN visits vi ON v.id = vi.visitor_id
INNER JOIN sections s ON vi.section_id = s.id;

-- 10. LEFT JOIN: Показать всех посетителей и секции, которые они посещали, включая тех, кто еще не посещал секции
-- Этот запрос выбирает всех посетителей и присоединяет к ним секции, даже если они еще не посещали секции.
SELECT v.first_name, v.last_name, s.section_name
FROM visitors v
LEFT JOIN visits vi ON v.id = vi.visitor_id
LEFT JOIN sections s ON vi.section_id = s.id;

-- 11. RIGHT JOIN: Показать всех посетителей и секции, включая секции без посетителей
-- Этот запрос выбирает секции и посетителей, даже если некоторые секции не были посещены.
SELECT v.first_name, v.last_name, s.section_name
FROM visitors v
RIGHT JOIN visits vi ON v.id = vi.visitor_id
RIGHT JOIN sections s ON vi.section_id = s.id;

-- 12. FULL JOIN: Показать всех посетителей и секции, включая тех, кто не посещал секции, и секции без посетителей
-- Этот запрос возвращает всех посетителей и секции, даже если они не совпадают.
SELECT v.first_name, v.last_name, s.section_name
FROM visitors v
FULL JOIN visits vi ON v.id = vi.visitor_id
FULL JOIN sections s ON vi.section_id = s.id;
