-- 1. Tạo cấu trúc bảng giả định
CREATE TABLE appointments (
    appointment_id INT PRIMARY KEY AUTO_INCREMENT,
    doctor_id INT NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    status ENUM('Pending', 'Completed', 'Cancelled') DEFAULT 'Pending',
    CHECK (end_time > start_time)
);

-- 2. Tạo Trigger chống trùng lịch
DELIMITER //

CREATE TRIGGER tg_prevent_double_booking
BEFORE INSERT ON appointments
FOR EACH ROW
BEGIN
    DECLARE overlap_count INT;

    -- Kiểm tra xem có ca khám nào trùng lặp không
    SELECT COUNT(*) INTO overlap_count
    FROM appointments
    WHERE doctor_id = NEW.doctor_id
      AND status != 'Cancelled'
      -- Công thức kiểm tra chồng lấn thời gian
      AND NEW.start_time < end_time 
      AND NEW.end_time > start_time;

    IF overlap_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Bác sĩ đã có lịch hẹn vào khung giờ này';
    END IF;
END //

CREATE TRIGGER tg_prevent_double_booking_update
BEFORE UPDATE ON appointments
FOR EACH ROW
BEGIN
    DECLARE overlap_count INT;

    SELECT COUNT(*) INTO overlap_count
    FROM appointments
    WHERE doctor_id = NEW.doctor_id
      AND status != 'Cancelled'
      -- Ngoại lệ 2: Loại trừ chính ca khám đang được cập nhật
      AND appointment_id != NEW.appointment_id
      -- Công thức kiểm tra chồng lấn thời gian
      AND NEW.start_time < end_time 
      AND NEW.end_time > start_time;

    IF overlap_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Bác sĩ đã có lịch hẹn vào khung giờ này';
    END IF;
END //

DELIMITER ;

-- Kịch bản 0: Tạo dữ liệu gốc (Bác sĩ 1 khám từ 8:00 - 9:00)
INSERT INTO appointments (doctor_id, start_time, end_time, status) 
VALUES (1, '2026-05-20 08:00:00', '2026-05-20 09:00:00', 'Pending');

-- 1. Lịch mới đưa vào khung giờ hoàn toàn trống (9:00 - 10:00) -> THÀNH CÔNG
INSERT INTO appointments (doctor_id, start_time, end_time, status) 
VALUES (1, '2026-05-20 09:00:00', '2026-05-20 10:00:00', 'Pending');

-- 2. Lịch mới đưa vào khung giờ đang có ca 'Pending' (trùng vào lúc 8:30) -> BỊ CHẶN
-- Lệnh này sẽ văng lỗi "Lỗi: Bác sĩ đã có lịch hẹn vào khung giờ này"
INSERT INTO appointments (doctor_id, start_time, end_time, status) 
VALUES (1, '2026-05-20 08:30:00', '2026-05-20 09:30:00', 'Pending');

-- 3. Lịch mới đưa vào khung giờ đang có ca 'Cancelled' -> THÀNH CÔNG
-- Bước A: Hủy ca khám lúc 8:00
UPDATE appointments SET status = 'Cancelled' WHERE appointment_id = 1;
-- Bước B: Thêm lịch mới đè vào khung giờ vừa hủy (8:15 - 8:45)
INSERT INTO appointments (doctor_id, start_time, end_time, status) 
VALUES (1, '2026-05-20 08:15:00', '2026-05-20 08:45:00', 'Pending');

-- 4. Cập nhật trạng thái một ca từ 'Pending' sang 'Completed' -> THÀNH CÔNG
-- Giả sử ID của ca vừa tạo ở bước 3 là id=3. Việc đổi status không làm thay đổi thời gian.
UPDATE appointments SET status = 'Completed' WHERE appointment_id = 3;