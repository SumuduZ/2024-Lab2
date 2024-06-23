use db2024lab1;
-- 关闭外键约束检查（某些数据库支持，例如MySQL）
SET FOREIGN_KEY_CHECKS = 0;

-- 按照依赖关系删除数据
TRUNCATE TABLE OverdueBorrowings;
TRUNCATE TABLE Borrowings;
TRUNCATE TABLE Reservations;
TRUNCATE TABLE Librarians;
TRUNCATE TABLE Students;
TRUNCATE TABLE Books;

-- 重新开启外键约束检查
SET FOREIGN_KEY_CHECKS = 1;

use db2024lab1;
DELETE FROM books WHERE BookID = '4';
DELETE FROM reservations WHERE BookID = '2';