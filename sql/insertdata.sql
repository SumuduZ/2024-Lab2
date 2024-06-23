use db2024lab1;
-- 插入图书信息
INSERT INTO Books (Title, Author, Publisher, Location) 
VALUES
('Introduction to Algorithms', 'Thomas H. Cormen', 'MIT Press', 'A1'),
('Clean Code', 'Robert C. Martin', 'Prentice Hall', 'B2'),
('The Pragmatic Programmer', 'Andrew Hunt', 'Addison-Wesley', 'C3'),
('Design Patterns', 'Erich Gamma', 'Addison-Wesley', 'D4'),
('Artificial Intelligence: A Modern Approach', 'Stuart Russell', 'Pearson', 'E5');

-- 插入图书管理员
INSERT INTO Librarians (LibrarianID, Name, ContactInfo)
VALUES
(1, 'Alice Smith', 'alice@example.com'),
(2, 'Bob Johnson', 'bob@example.com');

-- 插入学生
INSERT INTO Students (StudentID, Name, ContactInfo)
VALUES
(1001, 'John Doe', 'john.doe@example.com'),
(1002, 'Jane Roe', 'jane.roe@example.com');

-- 插入预约信息
INSERT INTO Reservations (StudentID, BookID, ReservationDate)
VALUES
(1001, 1, '2024-06-18'),
(1002, 3, '2024-06-18'),
(1001, 2, '2024-06-19');

-- 插入借阅信息
INSERT INTO Borrowings (StudentID, BookID, BorrowDate, ReturnDate)
VALUES
(1001, 1, '2024-05-30', '2024-06-14'),
(1001, 4, '2024-06-02', NULL);

-- 插入违规借阅信息//不需要插入
INSERT INTO OverdueBorrowings (StudentID, BookID, DueDate)
VALUES
(1001, 4, '2024-06-14');
