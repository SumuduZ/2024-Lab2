USE db2024lab1;

-- 删除表需要按照依赖关系从子表到父表逐步删除
DROP TABLE IF EXISTS OverdueBorrowings;
DROP TABLE IF EXISTS Borrowings;
DROP TABLE IF EXISTS Reservations;
DROP TABLE IF EXISTS Librarians;
DROP TABLE IF EXISTS Students;
DROP TABLE IF EXISTS Books;
