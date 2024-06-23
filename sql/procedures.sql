use db2024lab1;
DROP PROCEDURE IF EXISTS GetBooksCount;
DELIMITER //

CREATE FUNCTION GetBookCount()
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE book_count INT;
    
    SELECT COUNT(*) INTO book_count FROM Books;
    
    RETURN book_count;
END //

DELIMITER ;


DROP PROCEDURE IF EXISTS CheckAndUpdateOverdueBorrowings;
-- 检查借阅表中是否有逾期
DELIMITER //

CREATE PROCEDURE CheckAndUpdateOverdueBorrowings()
BEGIN
    -- Declare variables
    DECLARE done INT DEFAULT 0;
    DECLARE v_BorrowingID INT;
    DECLARE v_StudentID INT;
    DECLARE v_BookID INT;
    DECLARE v_DueDate DATE;
    DECLARE v_OverdueDays INT;
    
    -- Declare a cursor to iterate through overdue borrowings
    DECLARE cur CURSOR FOR
        SELECT BorrowingID, StudentID, BookID, DueDate
        FROM Borrowings
        WHERE DueDate < CURDATE() AND IsOverdue = FALSE;
    
    -- Declare a handler to close the cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    -- Open the cursor
    OPEN cur;
    
    -- Loop through the results
    read_loop: LOOP
        FETCH cur INTO v_BorrowingID, v_StudentID, v_BookID, v_DueDate;
        
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Calculate overdue days
        SET v_OverdueDays = DATEDIFF(CURDATE(), v_DueDate);
        
        -- Update the Borrowings table
        UPDATE Borrowings
        SET IsOverdue = TRUE
        WHERE BorrowingID = v_BorrowingID;
        
        -- Insert the overdue record into OverdueBorrowings table
        INSERT INTO OverdueBorrowings (StudentID, BookID, DueDate, OverdueDays)
        VALUES (v_StudentID, v_BookID, v_DueDate, v_OverdueDays);
    END LOOP;
    
    -- Close the cursor
    CLOSE cur;
    
    -- Remove returned books from OverdueBorrowings
    DELETE FROM OverdueBorrowings
    WHERE BookID IN (
        SELECT BookID
        FROM Borrowings
        WHERE ReturnDate IS NOT NULL
    );
END //

DELIMITER ;

CALL CheckAndUpdateOverdueBorrowings();

DROP PROCEDURE IF EXISTS ReserveBook;
DELIMITER //
-- 预约书籍
CREATE PROCEDURE ReserveBook (
    IN p_StudentID INT,
    IN p_BookID INT,
    IN p_ReservationDate DATE,
    OUT result INT
)
BEGIN
    DECLARE book_reserved_count INT;
    DECLARE total_reservations INT;

    -- 检查学生是否已经预约过这本书
    SELECT COUNT(*) INTO book_reserved_count
    FROM Reservations
    WHERE StudentID = p_StudentID AND BookID = p_BookID;

    -- 检查学生当前的预约数量
    SELECT COUNT(*) INTO total_reservations
    FROM Reservations
    WHERE StudentID = p_StudentID;

    -- 检查预约条件
    IF book_reserved_count > 0 THEN
        SET result = 0; -- 学生已经预约过这本书
    ELSEIF total_reservations >= 3 THEN
        SET result = 0; -- 学生已经预约超过三本书
    ELSE
        -- 插入预约信息
        INSERT INTO Reservations (StudentID, BookID, ReservationDate)
        VALUES (p_StudentID, p_BookID, p_ReservationDate);

        -- 更新图书状态
        UPDATE Books
        SET bstatus = 2, reserve_Times = reserve_Times + 1
        WHERE BookID = p_BookID;

        SET result = 1; -- 预约成功
    END IF;
END //

DELIMITER ;

CALL ReserveBook(2, 1002, '2024-06-16', @result);
SELECT @result;
DROP PROCEDURE IF EXISTS BorrowBook;
-- 学生借书
DELIMITER //

CREATE PROCEDURE BorrowBook (
    IN p_StudentID INT,
    IN p_BookID INT,
    IN p_BorrowDate DATE,
    IN p_DueDate DATE,
    OUT result INT
)
BEGIN
    DECLARE reservation_count INT;
    DECLARE overdue_count INT;
    DECLARE borrow_count INT;
    DECLARE same_day_borrow_count INT;

    -- 默认设置结果为0
    SET result = 0;

    -- 检查学生是否预约了这本书
    SELECT COUNT(*) INTO reservation_count
    FROM Reservations
    WHERE StudentID = p_StudentID AND BookID = p_BookID;

    IF reservation_count = 0 THEN
        SET result = 0; -- 学生没有预约这本书
    ELSE
        -- 检查学生是否有逾期信息
        SELECT COUNT(*) INTO overdue_count
        FROM OverdueBorrowings
        WHERE StudentID = p_StudentID;

        IF overdue_count > 0 THEN
            SET result = 0; -- 学生有逾期信息
        ELSE
            -- 检查学生当前借阅的图书数量
            SELECT COUNT(*) INTO borrow_count
            FROM Borrowings
            WHERE StudentID = p_StudentID AND ReturnDate IS NULL;

            IF borrow_count >= 3 THEN
                SET result = 0; -- 学生已经借阅了3本图书并且未归还
            ELSE
                -- 检查学生当天是否已经借阅过同一本书
                SELECT COUNT(*) INTO same_day_borrow_count
                FROM Borrowings
                WHERE StudentID = p_StudentID AND BookID = p_BookID AND BorrowDate = p_BorrowDate;

                IF same_day_borrow_count > 0 THEN
                    SET result = 0; -- 同一天不允许同一个读者重复借阅同一本书
                ELSE
                    -- 插入借阅信息
                    INSERT INTO Borrowings (StudentID, BookID, BorrowDate, DueDate, ReturnDate, IsOverdue)
                    VALUES (p_StudentID, p_BookID, p_BorrowDate, p_DueDate, NULL, FALSE);

                    -- 删除预约记录
                    DELETE FROM Reservations
                    WHERE StudentID = p_StudentID AND BookID = p_BookID;

                    -- 更新图书状态
                    UPDATE Books
                    SET bstatus = 1, borrow_Times = borrow_Times + 1, reserve_Times = reserve_Times - 1
                    WHERE BookID = p_BookID;

                    SET result = 1; -- 借书成功
                END IF;
            END IF;
        END IF;
    END IF;
END //

DELIMITER ;

DROP PROCEDURE IF EXISTS ReturnBook;
-- 还书
DELIMITER //

CREATE PROCEDURE ReturnBook (
    IN p_StudentID INT,
    IN p_BookID INT,
    IN p_ReturnDate DATE,
    OUT result INT
)
BEGIN
    DECLARE is_overdue BOOLEAN;
    DECLARE reservation_count INT;

    -- 默认设置结果为0（失败）
    SET result = 0;

    -- 更新借阅表中的还书日期
    UPDATE Borrowings
    SET ReturnDate = p_ReturnDate
    WHERE StudentID = p_StudentID AND BookID = p_BookID AND ReturnDate IS NULL;

    -- 检查借阅记录是否存在且更新成功
    IF ROW_COUNT() = 0 THEN
        SET result = 0; -- 没有找到未归还的借阅记录
    ELSE
        -- 检查该书是否逾期
        SELECT IsOverdue INTO is_overdue
        FROM Borrowings
        WHERE StudentID = p_StudentID AND BookID = p_BookID AND ReturnDate = p_ReturnDate;

        IF is_overdue THEN
            -- 如果逾期，从逾期表中删除记录
            DELETE FROM OverdueBorrowings
            WHERE StudentID = p_StudentID AND BookID = p_BookID;
        END IF;

        -- 检查该书是否再被预约
        SELECT COUNT(*) INTO reservation_count
        FROM Reservations
        WHERE BookID = p_BookID;

        IF reservation_count = 0 THEN
            -- 该书没有再被预约，将状态设为0
            UPDATE Books
            SET bstatus = 0
            WHERE BookID = p_BookID;
        ELSE
            -- 该书被预约，将状态设为2
            UPDATE Books
            SET bstatus = 2
            WHERE BookID = p_BookID;
        END IF;

        SET result = 1; -- 还书成功
    END IF;
END //

DELIMITER ;

CALL ReturnBook(1001, 1, '2024-06-15', @result);
SELECT @result;
