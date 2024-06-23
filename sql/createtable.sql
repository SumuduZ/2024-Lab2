use db2024lab1;

CREATE TABLE Books (
    BooKID INT AUTO_INCREMENT PRIMARY KEY,
    Title VARCHAR(255) NOT NULL,
    Author VARCHAR(255) NOT NULL,
    Publisher VARCHAR(255) NOT NULL,
    Location VARCHAR(255) NOT NULL,
    bstatus INT DEFAULT 0 CHECK (bstatus IN (0, 1, 2)),
    borrow_Times int DEFAULT 0, 
    reserve_Times int DEFAULT 0
);

CREATE TABLE Librarians (
    LibrarianID INT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    ContactInfo VARCHAR(255) NOT NULL
);

CREATE TABLE Students (
    StudentID INT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    ContactInfo VARCHAR(255) NOT NULL,
    AvatarPath VARCHAR(255)
);

CREATE TABLE Reservations (
    ReservationID INT AUTO_INCREMENT PRIMARY KEY,
    StudentID INT NOT NULL,
    BookID INT NOT NULL,
    ReservationDate DATE NOT NULL,
    FOREIGN KEY (StudentID) REFERENCES Students(StudentID),
    FOREIGN KEY (BookID) REFERENCES Books(BookID)
);

CREATE TABLE Borrowings (
    BorrowingID INT AUTO_INCREMENT PRIMARY KEY,
    StudentID INT NOT NULL,
    BookID INT NOT NULL,
    BorrowDate DATE NOT NULL,
    DueDate DATE NOT NULL,
    ReturnDate DATE,
    IsOverdue BOOLEAN NOT NULL default false,
    FOREIGN KEY (StudentID) REFERENCES Students(StudentID),
    FOREIGN KEY (BookID) REFERENCES Books(BookID)
);

CREATE TABLE OverdueBorrowings (
    OverdueID INT AUTO_INCREMENT PRIMARY KEY,
    StudentID INT NOT NULL,
    BookID INT NOT NULL,
    DueDate DATE NOT NULL,
    OverdueDays INT NOT NULL Default 1,
    FOREIGN KEY (StudentID) REFERENCES Students(StudentID),
    FOREIGN KEY (BookID) REFERENCES Books(BookID)
);
