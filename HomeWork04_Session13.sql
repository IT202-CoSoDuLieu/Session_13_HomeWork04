-- PHẦN A: PHÂN TÍCH KỸ THUẬT
-- 1. Số lượng, sự kiện và thời điểm kích hoạt Trigger
-- Số lượng: Cần tạo 2 Trigger riêng biệt để phủ cả 2 thao tác dữ liệu.

-- Sự kiện: Một Trigger cho sự kiện INSERT và một Trigger cho sự kiện UPDATE.

-- Thời điểm: BEFORE (BEFORE INSERT và BEFORE UPDATE) trên bảng Appointments.

-- Lý do: Hệ thống cần quét và kiểm tra xem có xung đột lịch hay không trước khi ghi dữ liệu vào đĩa cứng. Nếu phát hiện trùng, lệnh sẽ bị hủy ngay lập tức để bảo vệ tính toàn vẹn dữ liệu.

-- 2. Mệnh đề truy vấn (WHERE) giải quyết các ngoại lệ
-- Để tìm ra lịch trùng, ta đếm số lượng ca khám của cùng một bác sĩ (doctor_id) tại cùng một thời điểm (appointment_date).

-- Để xử lý các ngoại lệ, mệnh đề WHERE được cấu trúc như sau:

-- Xử lý trùng lịch cơ bản: doctor_id = NEW.doctor_id AND appointment_date = NEW.appointment_date

-- Giải quyết Ngoại lệ 1 (Bỏ qua lịch đã hủy): Chỉ quét các ca khám có trạng thái còn hiệu lực, tức là status <> 'Cancelled'.

-- Giải quyết Ngoại lệ 2 (Không tự trùng với chính mình khi UPDATE): Khi cập nhật một ca khám hiện tại, ta phải loại trừ chính bản ghi đó ra bằng cách thêm điều kiện: appointment_id <> NEW.appointment_id.

DROP DATABASE IF EXISTS RikkeiClinicDB;
CREATE DATABASE RikkeiClinicDB;
USE RikkeiClinicDB;

-- PHẦN 1: KHỞI TẠO CẤU TRÚC BẢNG 

-- 1. Bảng Bệnh nhân (Patients)
CREATE TABLE Patients (
    patient_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    date_of_birth DATE
);

-- 2. Bảng Nhân sự / Bác sĩ (Employees)
CREATE TABLE Employees (
    employee_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    position VARCHAR(50) NOT NULL,
    salary DECIMAL(18,2) NOT NULL
);

-- 3. Bảng Khoa (Departments)
CREATE TABLE Departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL
);

-- 4. Bảng Giường bệnh (Beds)
CREATE TABLE Beds (
    bed_id INT PRIMARY KEY,
    dept_id INT NOT NULL,
    patient_id INT DEFAULT NULL, -- NULL nghĩa là giường trống
    FOREIGN KEY (dept_id) REFERENCES Departments(dept_id),
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
);

-- 5. Bảng Lịch khám (Appointments)
CREATE TABLE Appointments (
    appointment_id INT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATETIME NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Pending', -- 'Pending', 'Completed', 'Cancelled'
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES Employees(employee_id)
);

-- 6. Bảng Kho Vật tư Y tế (Inventory)
CREATE TABLE Inventory (
    item_id INT PRIMARY KEY,
    item_name VARCHAR(100) NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0
);

-- 7. Bảng Kho Thuốc (Medicines)
CREATE TABLE Medicines (
    medicine_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(18,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0
);

-- 8. Bảng Công nợ Bệnh nhân (Patient_Invoices)
CREATE TABLE Patient_Invoices (
    patient_id INT PRIMARY KEY,
    total_due DECIMAL(18,2) NOT NULL DEFAULT 0,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
);

-- 9. Bảng Sản phẩm (Products)
CREATE TABLE Products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    price DECIMAL(18,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0
);

-- 10. Bảng Dịch vụ khám (Services) 
CREATE TABLE Services (
    service_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(18,2) NOT NULL
);

-- 11. Bảng Ví điện tử (Wallets) 
CREATE TABLE Wallets (
    patient_id INT PRIMARY KEY,
    balance DECIMAL(18,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'Active', -- 'Active', 'Inactive'
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
);

-- 12. Bảng Lịch sử sử dụng dịch vụ (Service_Usages) 
CREATE TABLE Service_Usages (
    usage_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    service_id INT NOT NULL,
    actual_price DECIMAL(18,2) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (service_id) REFERENCES Services(service_id)
);

-- PHẦN 2: CHÈN DỮ LIỆU MẪU (TEST CASES)
-- Chèn Bệnh nhân
INSERT INTO Patients (patient_id, full_name, phone, date_of_birth) VALUES
(1, 'Nguyen Van An', '0901111222', '1990-05-15'),
(2, 'Tran Thi Binh', '0912222333', '1985-08-20'),
(3, 'Le Hoang Cuong', '0923333444', '2000-12-01');

-- Chèn Nhân sự 
INSERT INTO Employees (employee_id, full_name, position, salary) VALUES
(101, 'Dr. Hoang Minh', 'Doctor', 20000.00),
(102, 'Dr. Lan Anh', 'Doctor', 25000.00),
(103, 'Nurse Thu Ha', 'Nurse', 12000.00);

-- Chèn Khoa
INSERT INTO Departments (dept_id, dept_name) VALUES
(1, 'Khoa Ngoai'),
(2, 'Khoa Noi'),
(3, 'Khoa ICU');

-- Chèn Giường bệnh
INSERT INTO Beds (bed_id, dept_id, patient_id) VALUES
(101, 1, 1),    -- Bệnh nhân 1 đang nằm giường 101 Khoa Ngoại
(201, 2, NULL), -- Giường 201 Khoa Nội đang trống
(301, 3, 2);    -- Bệnh nhân 2 đang nằm ICU

-- Chèn Lịch khám 
INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status) VALUES
(104, 1, 101, '2026-06-10 08:30:00', 'Pending'),
(105, 2, 102, '2026-05-01 09:00:00', 'Completed'),
(106, 3, 101, '2026-05-02 10:00:00', 'Cancelled');

-- Chèn Vật tư 
INSERT INTO Inventory (item_id, item_name, stock_quantity) VALUES
(10, 'Khau trang y te N95', 1000),
(11, 'Gang tay vo trung', 500),
(12, 'Dung dich sat khuan', 200);

-- Chèn Thuốc
INSERT INTO Medicines (medicine_id, name, price, stock) VALUES
(1, 'Amoxicillin 500mg', 15000, 100),  -- Tồn kho nhiều
(2, 'Panadol Extra', 5000, 5);         -- Tồn kho ít

-- Chèn Công nợ Bệnh nhân
INSERT INTO Patient_Invoices (patient_id, total_due) VALUES
(1, 1500000.00), -- Đã sửa: Nợ 1.5tr để test bài Giải phóng giường bệnh
(2, 0),
(3, 0);

-- Chèn Sản phẩm E-commerce 
INSERT INTO Products (name, price, stock) VALUES
('May do huyet ap Omron', 850000.00, 20),
('May do duong huyet', 450000.00, 15);

-- Chèn Dịch vụ
INSERT INTO Services (service_id, name, price) VALUES
(1, 'Sieu am o bung', 200000.00),
(2, 'Xet nghiem mau', 150000.00),
(3, 'Chup X-Quang', 250000.00);

-- Chèn Ví điện tử
INSERT INTO Wallets (patient_id, balance, status) VALUES
(1, 500000.00, 'Active'),    -- Test Case 1: Đủ tiền thanh toán
(2, 50000.00, 'Active'),     -- Test Case 3: Cháy ví (Chỉ có 50k, không đủ khám 200k)
(3, 1000000.00, 'Inactive'); -- Test Case 2: Nhiều tiền nhưng thẻ bị khóa


-- 1. TRIGGER 1: KIỂM TRA TRÙNG LỊCH KHI THÊM MỚI (BEFORE INSERT)
DROP TRIGGER IF EXISTS Trg_Check_Appointment_Duplicate_Insert;
DELIMITER //

CREATE TRIGGER Trg_Check_Appointment_Duplicate_Insert
BEFORE INSERT ON Appointments
FOR EACH ROW
BEGIN
    DECLARE v_count INT DEFAULT 0;

    -- Đếm số ca khám trùng lịch của cùng bác sĩ (Bỏ qua các ca đã hủy)
    SELECT COUNT(*) INTO v_count
    FROM Appointments
    WHERE doctor_id = NEW.doctor_id
      AND appointment_date = NEW.appointment_date
      AND status <> 'Cancelled';

    -- Nếu tìm thấy lịch trùng, tung lỗi chặn giao dịch
    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Bác sĩ đã có lịch hẹn vào khung giờ này';
    END IF;
END //
DELIMITER ;


-- 2. TRIGGER 2: KIỂM TRA TRÙNG LỊCH KHI DỜI/SỬA LỊCH (BEFORE UPDATE)
DROP TRIGGER IF EXISTS Trg_Check_Appointment_Duplicate_Update;
DELIMITER //

CREATE TRIGGER Trg_Check_Appointment_Duplicate_Update
BEFORE UPDATE ON Appointments
FOR EACH ROW
BEGIN
    DECLARE v_count INT DEFAULT 0;

    -- Nếu người dùng không đổi giờ khám và không đổi bác sĩ thì không cần check trùng
    IF NEW.appointment_date <> OLD.appointment_date OR NEW.doctor_id <> OLD.doctor_id THEN
        
        -- Đếm số ca trùng nhưng phải loại trừ chính ID ca khám đang cập nhật (Ngoại lệ 2)
        SELECT COUNT(*) INTO v_count
        FROM Appointments
        WHERE doctor_id = NEW.doctor_id
          AND appointment_date = NEW.appointment_date
          AND status <> 'Cancelled'
          AND appointment_id <> NEW.appointment_id;

        IF v_count > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Bác sĩ đã có lịch hẹn vào khung giờ này';
        END IF;
        
    END IF;
END //
DELIMITER ;


-- Thêm lịch mới cho Bác sĩ 101 vào ngày 15/06 (Giờ này chưa ai đăng ký)
INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status) VALUES
(107, 3, 101, '2026-06-15 14:00:00', 'Pending');

-- Kiểm tra kết quả: Bản ghi được thêm thành công vào bảng
SELECT * FROM Appointments WHERE appointment_id = 107;

-- Cố tình thêm lịch mới cho Bác sĩ 101 trùng khít vào giờ của ca số 104 đang chờ (08:30:00 ngày 10/06)
INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status) VALUES
(108, 2, 101, '2026-06-10 08:30:00', 'Pending');

-- KẾT QUẢ: Hệ thống báo lỗi đỏ và chặn đứng hành vi Double-booking:
-- Error Code: 1644. Lỗi: Bác sĩ đã có lịch hẹn vào khung giờ này

-- Ca số 106 vào lúc 10:00 ngày 02/05 đã bị Hủy (Cancelled). Giờ này được coi là trống.
-- Thêm ca mới mã số 109 nhảy vào đúng khung giờ đó:
INSERT INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status) VALUES
(109, 1, 101, '2026-05-02 10:00:00', 'Pending');

-- Kiểm tra kết quả: Đăng ký thành công lịch khám mới thay thế lịch cũ đã hủy
SELECT * FROM Appointments WHERE appointment_id = 109;

-- Tiến hành cập nhật trạng thái của ca khám số 104 từ 'Pending' sang 'Completed' khi bác sĩ khám xong
UPDATE Appointments 
SET status = 'Completed' 
WHERE appointment_id = 104;

-- KẾT QUẢ: Thành công! Hệ thống không nhận diện nhầm ca khám này trùng lịch với chính nó.
SELECT * FROM Appointments WHERE appointment_id = 104;