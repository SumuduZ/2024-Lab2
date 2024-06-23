use db2024lab1;
-- 计算应还日期
DROp TRIGGER IF exists calculate_due_date;
DELIMITER $$

CREATE TRIGGER calculate_due_date
BEFORE INSERT ON Borrowings
FOR EACH ROW
BEGIN
    -- 计算应还日期为借阅日期后14天
    SET NEW.DueDate = DATE_ADD(NEW.BorrowDate, INTERVAL 14 DAY);
END$$

DELIMITER ;
-- 计算学生头像路径
DROp TRIGGER IF exists SetDefaultAvatarPath;
DELIMITER //

CREATE TRIGGER SetDefaultAvatarPath
BEFORE INSERT ON Students
FOR EACH ROW
BEGIN
    SET NEW.AvatarPath = CONCAT('figs/', NEW.StudentID, '.jpg');
END //

DELIMITER ;

-- 修改预约状态
DROp TRIGGER IF exists after_insert_reservation;
DELIMITER //
CREATE TRIGGER after_insert_reservation
AFTER INSERT ON Reservations
FOR EACH ROW
BEGIN
    UPDATE Books
    SET 
        bstatus = CASE 
                    WHEN bstatus = 1 THEN bstatus 
                    ELSE 2 
                  END, 
        reserve_Times = reserve_Times + 1
    WHERE BookID = NEW.BookID;
END; //
DELIMITER ;


-- 当某本预约的书被借出时或者读者取消预约时，自动减少reserve_Times
DROp TRIGGER IF exists after_delete_reservation;
DELIMITER //
CREATE TRIGGER after_delete_reservation
AFTER DELETE ON Reservations
FOR EACH ROW
BEGIN
    UPDATE Books
    SET reserve_Times = reserve_Times - 1
    WHERE BookID = OLD.BookID;
END; //
DELIMITER ;

DROP TRIGGER IF EXISTS after_insert_borrowing;
DELIMITER //
CREATE TRIGGER after_insert_borrowing
AFTER INSERT ON Borrowings
FOR EACH ROW
BEGIN
    UPDATE Books
    SET 
        reserve_Times = CASE 
                          WHEN EXISTS (SELECT 1 FROM Reservations WHERE BookID = NEW.BookID) 
                          THEN reserve_Times - 1 
                          ELSE reserve_Times 
                        END,
        bstatus = 1
    WHERE BookID = NEW.BookID;
END; //
DELIMITER ;


DROp TRIGGER IF exists book_last_reservation_canceled;
DELIMITER //
-- 创建触发器C：当某本书的最后一位预约者取消预约且该书未被借出时，将bstatus改为0
CREATE TRIGGER book_last_reservation_canceled
AFTER DELETE ON reservations
FOR EACH ROW
BEGIN
    DECLARE remaining_reservations INT;
    DECLARE book_status INT;
    
    -- 计算剩余预约数
    SELECT COUNT(*) INTO remaining_reservations
    FROM Reservations
    WHERE bookID = OLD.bookID;
    
    -- 获取图书状态
    SELECT bstatus INTO book_status
    FROM Books
    WHERE bookid = OLD.bookID;
    
    -- 如果剩余预约数为0且图书状态为2，则将图书状态改为0
    IF remaining_reservations = 0 AND book_status = 2 THEN
        UPDATE Books
        SET bstatus = 0
        WHERE bookid = OLD.bookID;
    END IF;
END//
DELIMITER ;

-- 还书逻辑
DELIMITER //

CREATE TRIGGER after_update_returnDate
AFTER UPDATE ON Borrowings
FOR EACH ROW
BEGIN
    -- 检查 ReturnDate 是否被更新
    IF NEW.ReturnDate IS NOT NULL AND OLD.ReturnDate IS NULL THEN
        -- 检查书籍是否有预约
        IF (SELECT COUNT(*) FROM Reservations WHERE BookID = NEW.BookID) = 0 THEN
            -- 没有预约，设置 bstatus 为 0
            UPDATE Books
            SET bstatus = 0
            WHERE BookID = NEW.BookID;
        ELSE
            -- 有预约，设置 bstatus 为 2
            UPDATE Books
            SET bstatus = 2
            WHERE BookID = NEW.BookID;
        END IF;
    END IF;
END //

DELIMITER ;
