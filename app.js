const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser');
const path = require('path');
const { message } = require('statuses');
const app = express();

// 设置模板引擎
app.set('view engine', 'ejs');
app.set('views', __dirname + '/views');

// 使用body-parser中间件
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

// 提供静态文件服务
app.use('/figs', express.static(path.join(__dirname, 'views/figs')));

// 创建MySQL连接池
const db = mysql.createPool({
    host: 'localhost',
    user: 'root',
    password: 'zhu998jiaguo@',
    database: 'db2024lab1'
});

// 测试数据库连接
db.getConnection((err, connection) => {
    if (err) {
        console.error('Error connecting to the database:', err);
    } else {
        console.log('Connected to the MySQL database');
        connection.release();

    }
});


// 显示登录页面
app.get('/', (req, res) => {
    res.render('login');
});

// 处理登录请求
app.post('/login', (req, res) => {
    const { userType, id, name } = req.body;

    if (userType === 'student') {
        db.query('SELECT * FROM Students WHERE StudentID = ? AND Name = ?', [id, name], (err, results) => {
            if (err) {
                res.status(500).json({ error: 'Database query error' });
            } else if (results.length > 0) {
                res.status(200).json({ success: true, userType: 'student', id: id });
            } else {
                res.status(401).json({ error: 'Invalid student credentials' });
            }
        });
    } else if (userType === 'librarian') {
        db.query('SELECT * FROM Librarians WHERE LibrarianID = ? AND Name = ?', [id, name], (err, results) => {
            if (err) {
                res.status(500).json({ error: 'Database query error' });
            } else if (results.length > 0) {
                res.status(200).json({ success: true, userType: 'librarian', id: id });
            } else {
                res.status(401).json({ error: 'Invalid librarian credentials' });
            }
        });
    } else {
        res.status(400).json({ error: 'Invalid user type' });
    }
});

// 学生页面
app.get('/student/:id', (req, res) => {
    const studentID = req.params.id;
    db.query('SELECT * FROM Students WHERE StudentID = ?', [studentID], (err, results) => {
        if (err) {
            res.status(500).send('Database query error');
        } else if (results.length > 0) {
            res.render('student', { student: results[0] });
        } else {
            res.status(404).send('Student not found');
        }
    });
});

// 处理查阅书籍请求
app.post('/student/searchBook', (req, res) => {
    const { bookQuery } = req.body;

    // 根据书名或书籍ID查询书籍信息
    db.query('SELECT * FROM Books WHERE Title LIKE ? OR BooKID = ?', [`%${bookQuery}%`, bookQuery], (err, results) => {
        if (err) {
            res.status(500).json({ error: 'Database query error' });
        } else {
            const studentID = req.body.studentID; // Assume you are passing studentID from the form or session
            db.query('SELECT * FROM Students WHERE StudentID = ?', [studentID], (err, studentResults) => {
                if (err || studentResults.length === 0) {
                    res.status(500).send('Database student query error');
                } else {
                    res.render('student', { student: studentResults[0], books: results });
                }
            });
        }
    });
});

// 预约书籍
app.post('/student/reserveBook', (req, res) => {
    const { studentID, bookID, bookTitle, reservationDate } = req.body;

    // 如果提供了书籍ID，则根据书籍ID查询；否则根据书籍名查询
    let query = 'SELECT * FROM Books WHERE ';
    let queryParams = [];
    if (bookID) {
        query += 'BookID = ?';
        queryParams.push(bookID);
    } else if (bookTitle) {
        query += 'Title = ?';
        queryParams.push(bookTitle);
    } else {
        return res.status(400).json({ error: 'Please provide either a book ID or book title.' });
    }

    db.query(query, queryParams, (err, bookResults) => {
        if (err) {
            return res.status(500).json({ error: 'Database1 query error' });
        } else if (bookResults.length === 0) {
            return res.status(404).json({ error: 'Book not found' });
        }

        const bookIDToReserve = bookResults[0].BooKID;

        // 插入预约记录到数据库
        const insertQuery = 'INSERT INTO reservations (StudentID, BookID, ReservationDate) VALUES (?, ?, ?)';
        db.query(insertQuery, [studentID, bookIDToReserve, reservationDate], (err, result) => {
            if (err) {
                console.error('数据库查询错误2:', err);  // 记录实际错误
                return res.status(500).json({ error: '数据库查询错误2', details: err.message });
            }

            // 查询学生的所有预约信息
            db.query('SELECT * FROM Reservations WHERE StudentID = ?', [studentID], (err, reservations) => {
                if (err) {
                    return res.status(500).json({ error: 'Database3 query error' });
                }
                res.status(200).json({ message: 'Book reserved successfully', reservations });
            });
        });
    });
});

// 取消预约
app.post('/student/cancelReservation', (req, res) => {
    const { studentID, reservationID } = req.body;
    const query = 'DELETE FROM Reservations WHERE StudentID = ? AND reservationID = ?';
    db.query(query, [studentID, reservationID], (err, result) => {
        if (err) {
            return res.status(500).json({ error: 'Database query error' });
        } else {
            res.status(200).json({ message: 'Reservation cancelled successfully'});
        }
    });
});

// 查询预约信息
app.post('/student/searchReservations', (req, res) => {
    const { studentID } = req.body;
    const query = 'SELECT * FROM Reservations WHERE StudentID = ?';
    db.query(query, [studentID], (err, reservations) => {
        if (err) {
            return res.status(500).json({ error: 'Database query error' });
        } else {
            res.status(200).json({ message: 'check successfully' , reservations});  // 确保返回的数据格式正确
        }
    });
});

// 借阅书籍
app.post('/student/borrowBook', (req, res) => {
    const { studentID, bookID } = req.body;
    let borrowDate = new Date().toISOString().slice(0, 19).replace('T', ' ');
    let dueDate = new Date();
    dueDate.setDate(dueDate.getDate() + 14);
    dueDate = dueDate.toISOString().slice(0, 19).replace('T', ' ');

    let bquery = 'SELECT * FROM Books WHERE BookID = ?';
    // 检查书籍是否存在
    db.query(bquery, [bookID], (err, results) => {
        if (err) {
            return res.status(500).json({ error: 'Database1 query error' });
        } else if (results.length === 0) {
            return res.status(404).json({ error: 'Book not found' });
        }

        // 检查书籍是否已被借出
        let borrowquery = 'SELECT * FROM Borrowings WHERE BookID = ? AND ReturnDate IS NULL';
        db.query(borrowquery, [bookID], (err, results) => {
            if (err) {
                return res.status(500).json({ error: 'Database2 query error' });
            } else if (results.length > 0) {
                return res.status(400).json({ error: 'Book already borrowed' });
            }

            // 检查书籍是否被其他学生预约且自己没有预约
            let reservationQuery = 'SELECT * FROM Reservations WHERE BookID = ? AND StudentID = ?';
            db.query(reservationQuery, [bookID, studentID], (err, reservations) => {
                if (err) {
                    return res.status(500).json({ error: 'Database3 query error' });
                } else if (reservations.length === 0) {
                    return res.status(400).json({ error: 'You have no reservation about this book' });
                }

                // 插入借阅记录
                const query = 'INSERT INTO Borrowings (StudentID, BookID, BorrowDate, DueDate) VALUES (?, ?, ?, ?)';
                db.query(query, [studentID, bookID, borrowDate, dueDate], (err, result) => {
                    if (err) {
                        return res.status(500).json({ error: 'Database4 query error' });
                    } else {
                        // 删除预约记录
                        const deleteReservationQuery = 'DELETE FROM Reservations WHERE BookID = ? AND StudentID = ?';
                        db.query(deleteReservationQuery, [bookID, studentID], (err, result) => {
                            if (err) {
                                return res.status(500).json({ error: 'Database5 query error' });
                            } else {
                                res.status(200).json({ message: 'Book borrowed successfully'});  
                            } 
                        });                    
                    }
                });

            });
        });
    });
});


// 归还书籍
app.post('/student/returnBook', (req, res) => {
    const { studentID, borrowingID } = req.body;
    const currentDate = new Date().toISOString().split('T')[0]; // 获取当前日期
    
    const query = 'UPDATE Borrowings SET ReturnDate = ?, IsOverdue = CASE WHEN DueDate < ? THEN TRUE ELSE FALSE END WHERE BorrowingID = ? AND ReturnDate IS NULL AND studentID = ?';
    db.query(query, [currentDate, currentDate, borrowingID, studentID], (err, result) => {
        if (err) {
            return res.status(500).json({ error: 'Database query error' });
        }
        res.status(200).json({ message: 'Book returned successfully' });
    });
});

// 查询借阅信息
app.post('/student/checkBorrowings', (req, res) => {
    const { studentID } = req.body;
    const query = 'SELECT * FROM borrowings WHERE StudentID = ? AND ReturnDate IS NULL';
    db.query(query, [studentID], (err, borrowings) => {
        if (err) {
            return res.status(500).json({ error: 'Database query error' });
        } else {
            res.status(200).json({message: 'check successfully' , borrowings});  // 确保返回的数据格式正确
        }
    });
});

// 查询逾期信息
app.post('/student/checkOverdue', (req, res) => {
    const { studentID } = req.body;

    // 调用存储过程以更新逾期信息
    const updateOverdueProcedure = 'CALL CheckAndUpdateOverdueBorrowings()';

    db.query(updateOverdueProcedure, (err, result) => {
        if (err) {
            return res.status(500).json({ error: 'Error updating overdue borrowings' });
        } else {
            // 在调用存储过程后查询逾期信息
            const query = 'SELECT * FROM OverdueBorrowings WHERE StudentID = ?';
            db.query(query, [studentID], (err, overdues) => {
                if (err) {
                    return res.status(500).json({ error: 'Database query error' });
                } else {
                    res.status(200).json({ message: 'Check successfully', overdues });  // 确保返回的数据格式正确
                }
            });
        }
    });
});


// 教师页面
app.get('/librarian/:id', (req, res) => {
    const librarianID = req.params.id;
    db.query('SELECT * FROM Librarians WHERE LibrarianID = ?', [librarianID], (err, results) => {
        if (err) {
            res.status(500).send('Database query error');
        } else if (results.length > 0) {
            res.render('librarian', { librarian: results[0] });
        } else {
            res.status(404).send('Librarian not found');
        }
    });
});

// 处理查阅书籍请求
app.post('/librarian/searchBook', (req, res) => {
    const { bookQuery } = req.body;

    // 根据书名或书籍ID查询书籍信息
    db.query('SELECT * FROM Books WHERE Title LIKE ? OR BooKID = ?', [`%${bookQuery}%`, bookQuery], (err, results) => {
        if (err) {
            return res.status(500).json({ error: 'Database1 query error' });
        } else {
            res.status(200).json({ message: 'Book search successfully', books: results });
        }
    });
});

// 处理查找学生
app.post('/librarian/searchStudent', (req, res) => {
    const { studentID } = req.body;
    const query = 'SELECT * FROM students WHERE StudentID = ?';
    db.query(query, [studentID], (err, results) => {
        if (err) {
            return res.status(500).json({ error: 'Database query error' });
        } else {
            res.status(200).json({ message: 'Student search successfully', students: results });
        }
    });
});
// 增加图书
app.post('/librarian/addBook', (req, res) => {
    const { title, author, publisher, Location } = req.body;
    
    // 检查所有字段是否都有值
    if (!title || !author || !publisher || !Location) {
        return res.status(400).json({ error: 'Please provide all book details' });
    }

    const query = 'INSERT INTO books (Title, Author, Publisher, Location) VALUES (?, ?, ?, ?)';
    db.query(query, [title, author, publisher, Location], (err, result) => {
        if (err) {
            console.error('Database query error:', err);
            return res.status(500).json({ error: 'Database query error' });
        } else {
            res.status(200).json({ message: 'Book added successfully' });
        }
    });
});

// 查询借阅
app.post('/librarian/searchborrowings', (req, res) => {
    const query = 'SELECT * FROM borrowings';
    db.query(query, (err, borrowings) => {
        if (err) {
            console.error('Database query error:', err);
            return res.status(500).json({ error: 'Database query error' });
        } else {
            res.status(200).json({ message: 'Search borrowings successfully', borrowings });
        }
    });
});

// 查询预约
app.post('/librarian/searchReservations', (req, res) => {
    const query = 'SELECT * FROM reservations';
    db.query(query, (err, reservations) => {
        if (err) {
            console.error('Database query error:', err);
            return res.status(500).json({ error: 'Database query error' });
        } else {
            res.status(200).json({ message: 'Search reservations successfully', reservations });
        }
    });
});

// 查询违约信息
app.post('/librarian/searchOverdueBorrowings', (req, res) => {
    const query = 'SELECT * FROM overdueborrowings';
    db.query(query, (err, overdueBorrowings) => {
        if (err) {
            console.error('Database query error:', err);
            return res.status(500).json({ error: 'Database query error' });
        } else {
            res.status(200).json({ message: 'Search overdue borrowings successfully', overdueBorrowings });
        }
    });
});

// 删除图书
app.post('/librarian/deleteBook', (req, res) => {
    const { bookID } = req.body;

    // 查询图书的 bstatus
    const checkStatusQuery = 'SELECT bstatus FROM Books WHERE BookID = ?';
    db.query(checkStatusQuery, [bookID], (err, results) => {
        if (err) {
            return res.status(500).json({ error: 'Database1 query error' });
        }

        if (results.length === 0) {
            return res.status(404).json({ error: 'Book not found' });
        }

        const book = results[0];
        if (book.bstatus !== 0) {
            return res.status(400).json({ error: 'Book cannot be deleted because it is currently borrowed or reserved' });
        }

        // 删除图书
        const deleteQuery = 'DELETE FROM Books WHERE BookID = ?';
        db.query(deleteQuery, [bookID], (err, result) => {
            if (err) {
                console.error('Database query error:', err);
                return res.status(500).json({ error: 'Database2 query error' });
            } else {
                res.status(200).json({ message: 'Book deleted successfully' });
            }
        });
    });
});

// 修改图书信息
app.post('/librarian/updateBook', (req, res) => {
    const { bookID, author, publisher, location } = req.body;

    // 检查至少一个字段不为空
    if (!author && !publisher && !location) {
        return res.status(400).json({ error: 'Please provide at least one field to update.' });
    }

    // 构建动态查询
    let query = 'UPDATE Books SET ';
    let params = [];
    if (author) {
        query += 'Author = ?, ';
        params.push(author);
    }
    if (publisher) {
        query += 'Publisher = ?, ';
        params.push(publisher);
    }
    if (location) {
        query += 'Location = ?, ';
        params.push(location);
    }

    // 移除最后一个逗号和空格
    query = query.slice(0, -2);
    query += ' WHERE BookID = ?';
    params.push(bookID);

    db.query(query, params, (err, result) => {
        if (err) {
            return res.status(500).json({ error: 'Database query error' });
        } else {
            res.status(200).json({ message: 'Book updated successfully' });
        }
    });

});

app.post('/librarian/updatebook', (req, res) => {
    db.Transaction((err, t) => {
        if (err) {
            return res.status(500).json({ error: 'Database transaction error' });
        }

        const { bookID, author, publisher, location } = req.body;

        // 检查至少一个字段不为空
        if (!author && !publisher && !location) {
            return res.status(400).json({ error: 'Please provide at least one field to update.' });
        }

        // 构建动态查询
        let query = 'UPDATE Books SET ';
        let params = [];
        if (author) {
            query += 'Author = ?, ';
            params.push(author);
        }
        if (publisher) {
            query += 'Publisher = ?, ';
            params.push(publisher);
        }
        if (location) {
            query += 'Location = ?, ';
            params.push(location);
        }

        // 移除最后一个逗号和空格
        query = query.slice(0, -2);
        query += ' WHERE BookID = ?';
        params.push(bookID);

        db.query(query, params, (err, result) => {
            if (err) {
                t.rollback();
                return res.status(500).json({ error: 'Database query error' });
            } else {
                t.commit();
                res.status(200).json({ message: 'Book updated successfully' });
            }
        });
    });
});

// 查询图书总数
app.post('/librarian/searchBookCount', (req, res) => {
    const query = 'SELECT GetBookCount() AS bookCount';

    db.query(query, (err, results) => {
        if (err) {
            console.error('Database query error:', err);
            return res.status(500).json({ error: 'Database query error' });
        }

        const bookCount = results[0].bookCount; // Assuming stored procedure returns book_count

        res.status(200).json({ bookCount });
    });
});


// 启动服务器
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
