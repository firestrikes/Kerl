-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3307
-- Generation Time: Feb 02, 2025 at 01:28 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `attendease`
--
CREATE DATABASE IF NOT EXISTS `attendease` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `attendease`;

DELIMITER $$
--
-- Procedures
--
DROP PROCEDURE IF EXISTS `GetStudentsByTeacher`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetStudentsByTeacher` (IN `teacherID` INT)   BEGIN
    SELECT s.student_id, s.firstname, s.lastname
    FROM Student s
    JOIN Teacher t ON s.section_id = t.section_id
    WHERE t.teacher_id = teacherID;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `absence`
--

DROP TABLE IF EXISTS `absence`;
CREATE TABLE `absence` (
  `absence_id` int(11) NOT NULL,
  `student_id` int(11) DEFAULT NULL,
  `totalabsences` int(11) DEFAULT 0,
  `semesteryear` char(9) DEFAULT NULL,
  `absence_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `absence`
--

TRUNCATE TABLE `absence`;
--
-- Dumping data for table `absence`
--

INSERT INTO `absence` (`absence_id`, `student_id`, `totalabsences`, `semesteryear`, `absence_date`) VALUES
(8, 2, 1, '2025-2026', '2025-02-01'),
(9, 3, 1, '2025-2026', '2025-02-01'),
(38, 1, 2, NULL, '2025-02-02'),
(39, 2, 2, NULL, '2025-02-02'),
(40, 3, 2, NULL, '2025-02-02');

-- --------------------------------------------------------

--
-- Table structure for table `attendance`
--

DROP TABLE IF EXISTS `attendance`;
CREATE TABLE `attendance` (
  `attendance_id` int(11) NOT NULL,
  `student_id` int(11) DEFAULT NULL,
  `attendancestatus_id` int(11) DEFAULT NULL,
  `recordedby` int(11) DEFAULT NULL,
  `recordeddate` datetime DEFAULT current_timestamp(),
  `section_id` int(11) DEFAULT NULL,
  `excuse_status_id` int(11) DEFAULT 1,
  `semester_year` char(9) DEFAULT '2025-2026'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `attendance`
--

TRUNCATE TABLE `attendance`;
--
-- Dumping data for table `attendance`
--

INSERT INTO `attendance` (`attendance_id`, `student_id`, `attendancestatus_id`, `recordedby`, `recordeddate`, `section_id`, `excuse_status_id`, `semester_year`) VALUES
(1, 1, 2, 1, '2025-01-30 00:00:00', 8, 1, '2025-2026'),
(2, 1, 2, NULL, '2025-02-01 00:00:00', NULL, 1, '2025-2026'),
(3, 2, 1, NULL, '2025-02-01 00:00:00', NULL, 1, '2025-2026'),
(4, 3, 1, NULL, '2025-02-01 00:00:00', NULL, 1, '2025-2026'),
(5, 1, 2, NULL, '2025-02-01 00:00:00', NULL, 1, '2025-2026'),
(6, 2, 2, NULL, '2025-02-01 00:00:00', NULL, 1, '2025-2026'),
(7, 3, 2, NULL, '2025-02-01 00:00:00', NULL, 1, '2025-2026'),
(8, 1, 2, NULL, '2025-02-02 00:00:00', NULL, 1, '2025-2026'),
(9, 2, 2, NULL, '2025-02-02 00:00:00', NULL, 1, '2025-2026'),
(10, 3, 2, NULL, '2025-02-02 00:00:00', NULL, 1, '2025-2026');

--
-- Triggers `attendance`
--
DROP TRIGGER IF EXISTS `UpdateCommunityServiceOnAbsenceOrTardy`;
DELIMITER $$
CREATE TRIGGER `UpdateCommunityServiceOnAbsenceOrTardy` AFTER INSERT ON `attendance` FOR EACH ROW BEGIN
    DECLARE serviceHours INT;
    IF NEW.attendancestatus_id IN (2, 3) THEN
        SET serviceHours = 1;
    ELSE
        SET serviceHours = 0;
    END IF;
    IF serviceHours > 0 THEN
        INSERT INTO CommunityService (student_id, absence_id, hours, assigneddate)
        VALUES (NEW.student_id, 
                (SELECT absence_id FROM Absence WHERE student_id = NEW.student_id ORDER BY absence_id DESC LIMIT 1),
                serviceHours, CURDATE())
        ON DUPLICATE KEY UPDATE hours = hours + serviceHours;
    END IF;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `log_attendance_changes`;
DELIMITER $$
CREATE TRIGGER `log_attendance_changes` AFTER UPDATE ON `attendance` FOR EACH ROW BEGIN
    INSERT INTO AttendanceLog (attendance_id, student_id, old_status, new_status, action, changed_by, section_id, change_time)
    VALUES (
        NEW.attendance_id, 
        NEW.student_id, 
        OLD.attendancestatus_id, 
        NEW.attendancestatus_id, 
        'UPDATE', 
        NEW.recordedby,  -- Now linked to PDSA_Staff.StaffID
        NEW.section_id, 
        NOW()
    );
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `log_attendance_delete`;
DELIMITER $$
CREATE TRIGGER `log_attendance_delete` BEFORE DELETE ON `attendance` FOR EACH ROW BEGIN
    INSERT INTO AttendanceLog (attendance_id, student_id, old_status, changed_by, change_type)
    VALUES (OLD.attendance_id, OLD.student_id, OLD.attendancestatus_id, OLD.recordedby, 'DELETE');
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `log_attendance_insert`;
DELIMITER $$
CREATE TRIGGER `log_attendance_insert` AFTER INSERT ON `attendance` FOR EACH ROW BEGIN
    INSERT INTO AttendanceLog (attendance_id, student_id, new_status, changed_by, change_type)
    VALUES (NEW.attendance_id, NEW.student_id, NEW.attendancestatus_id, NEW.recordedby, 'INSERT');
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `log_attendance_status_change`;
DELIMITER $$
CREATE TRIGGER `log_attendance_status_change` AFTER UPDATE ON `attendance` FOR EACH ROW BEGIN
    IF OLD.attendancestatus_id != NEW.attendancestatus_id THEN
        INSERT INTO AttendanceLog (attendance_id, old_status, new_status, change_date)
        VALUES (NEW.attendance_id, OLD.attendancestatus_id, NEW.attendancestatus_id, NOW());
    END IF;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `log_attendance_update`;
DELIMITER $$
CREATE TRIGGER `log_attendance_update` AFTER UPDATE ON `attendance` FOR EACH ROW BEGIN
    -- Log attendance status and excuse status updates
    INSERT INTO AttendanceLog (
        attendance_id,
        student_id,
        old_status,
        new_status,
        old_excuse_status_id,  -- Now using FK
        new_excuse_status_id,  -- Now using FK
        action,
        changed_by,
        section_id,
        change_time
    )
    VALUES (
        NEW.attendance_id,
        NEW.student_id,
        OLD.attendancestatus_id,
        NEW.attendancestatus_id,
        OLD.excuse_status_id,  -- Fixed name
        NEW.excuse_status_id,  -- Fixed name
        'UPDATE',
        NEW.recordedby,
        NEW.section_id,
        NOW()
    );
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `update_absence_after_attendance_update`;
DELIMITER $$
CREATE TRIGGER `update_absence_after_attendance_update` AFTER UPDATE ON `attendance` FOR EACH ROW BEGIN
    -- Declare a variable to hold the count of existing absence records
    DECLARE existing_absence INT;

    -- Check if the status has been updated to absent (assuming 2 means absent)
    IF NEW.attendancestatus_id = 2 THEN
        -- Check if there's an existing record in the absence table for that student and recorded date
        SELECT COUNT(*) INTO existing_absence
        FROM absence
        WHERE student_id = NEW.student_id AND absence_date = NEW.recordeddate;
        
        -- If an absence record exists, update total absences
        IF existing_absence > 0 THEN
            UPDATE absence 
            SET totalabsences = totalabsences + 1
            WHERE student_id = NEW.student_id AND absence_date = NEW.recordeddate;
        ELSE
            -- If no record exists, insert a new absence record
            INSERT INTO absence (student_id, totalabsences, semesteryear, absence_date)
            VALUES (NEW.student_id, 1, '2025-2026', NEW.recordeddate);
        END IF;
    END IF;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `update_absence_on_absent`;
DELIMITER $$
CREATE TRIGGER `update_absence_on_absent` AFTER UPDATE ON `attendance` FOR EACH ROW BEGIN
    -- Check if the attendancestatus_id has changed to 2 (absent)
    IF NEW.attendancestatus_id = 2 AND OLD.attendancestatus_id != 2 THEN
        -- Insert into the absence table to record the absence with the current date
        INSERT INTO absence (student_id, absence_date)
        VALUES (NEW.student_id, CURRENT_DATE);

        -- Update the totalabsences field in the students table
        UPDATE students
        SET totalabsence = totalabsence + 1
        WHERE student_id = NEW.student_id;
    END IF;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `update_absence_on_attendance`;
DELIMITER $$
CREATE TRIGGER `update_absence_on_attendance` AFTER UPDATE ON `attendance` FOR EACH ROW BEGIN

    IF NEW.attendancestatus_id = 2 AND OLD.attendancestatus_id != 2 THEN
        -- Check if the student already has an Absence record
        IF EXISTS (
            SELECT 1 FROM Absence 
            WHERE student_id = NEW.student_id 
            AND semester_year = '2025-2026'
        ) THEN
            -- If record exists, increment total_absences
            UPDATE Absence
            SET total_absences = total_absences + 1
            WHERE student_id = NEW.student_id 
            AND semester_year = '2025-2026';
        ELSE
            -- If no record exists, insert a new Absence record
            INSERT INTO Absence (student_id, total_absences, semester_year)
            VALUES (NEW.student_id, 1, '2025-2026');
        END IF;
    END IF;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `update_absence_on_attendance_change`;
DELIMITER $$
CREATE TRIGGER `update_absence_on_attendance_change` AFTER UPDATE ON `attendance` FOR EACH ROW BEGIN
    IF NEW.attendancestatus_id = 2 THEN
        IF EXISTS (SELECT 1 FROM Absence WHERE student_id = NEW.student_id AND SemesterYear = DATE_FORMAT(NOW(), '%Y-%Y')) THEN
            UPDATE Absence
            SET totalabsences = totalabsences + 1
            WHERE student_id = NEW.student_id AND semesteryear = DATE_FORMAT(NOW(), '%Y-%Y');
        ELSE
            INSERT INTO Absence (student_id, totalabsences, semesteryear)
            VALUES (NEW.student_id, 1, DATE_FORMAT(NOW(), '%Y-%Y'));
        END IF;
    END IF;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `update_absence_on_status_change`;
DELIMITER $$
CREATE TRIGGER `update_absence_on_status_change` AFTER UPDATE ON `attendance` FOR EACH ROW BEGIN
    SET @currentSemester = '2025-2026';

    INSERT INTO AttendanceLog (student_id, old_status_id, new_status_id, semester_year)
    VALUES (OLD.student_id, OLD.attendancestatus_id, NEW.attendancestatus_id, @currentSemester);

    IF NEW.attendancestatus_id = 2 AND OLD.attendancestatus_id != 2 THEN
        INSERT INTO Absence (student_id, total_absences, semester_year)
        VALUES (NEW.student_id, 1, @currentSemester)
        ON DUPLICATE KEY UPDATE total_absences = total_absences + 1;

    ELSEIF OLD.attendancestatus_id = 2 AND NEW.attendancestatus_id != 2 THEN
        UPDATE Absence
        SET total_absences = GREATEST(total_absences - 1, 0)
        WHERE student_id = NEW.student_id
        AND semester_year = @currentSemester;
    END IF;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `update_attendance_log`;
DELIMITER $$
CREATE TRIGGER `update_attendance_log` AFTER UPDATE ON `attendance` FOR EACH ROW BEGIN
    INSERT INTO AttendanceLog (
        attendance_id, student_id, old_status, new_status, action, changed_by, section_id, excuse_status_id, change_time
    )  
    VALUES (
        NEW.attendance_id, NEW.student_id, OLD.attendancestatus_id, NEW.attendancestatus_id, 
        'UPDATE', NEW.recordedby, NEW.section_id, NEW.excuse_status_id, NOW()
    );
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `update_community_service_hours`;
DELIMITER $$
CREATE TRIGGER `update_community_service_hours` AFTER UPDATE ON `attendance` FOR EACH ROW BEGIN
    IF NEW.attendancestatus_id = 2 THEN  -- Assuming 2 is for "Absent"
        UPDATE CommunityService
        SET hours = hours + 1
        WHERE student_id = NEW.student_id;
    END IF;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `update_cs_hours_on_absence`;
DELIMITER $$
CREATE TRIGGER `update_cs_hours_on_absence` AFTER UPDATE ON `attendance` FOR EACH ROW BEGIN
    -- Ensure it only adds hours when status changes to "Absent" and was not previously "Absent"
    IF NEW.attendancestatus_id = 2 AND OLD.attendancestatus_id != 2 THEN
        -- Check if the student has already been marked as absent today, and avoid duplicating community service hours
        IF NOT EXISTS (SELECT 1 FROM CommunityService WHERE student_id = NEW.student_id) THEN
            -- If no community service record exists, add the first hour
            INSERT INTO CommunityService (student_id, hours) VALUES (NEW.student_id, 1);
        ELSE
            -- If record exists, increment by 1 hour for each absence
            UPDATE CommunityService
            SET hours = hours + 1
            WHERE student_id = NEW.student_id;
        END IF;
    END IF;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `update_total_absences`;
DELIMITER $$
CREATE TRIGGER `update_total_absences` AFTER INSERT ON `attendance` FOR EACH ROW BEGIN
    -- Declare the variable to check if absence record exists
    DECLARE existing_absence INT;

    -- Check if the status is absent (2) and update the totalabsences
    IF NEW.attendancestatus_id = 2 THEN
        -- Check if the student already has an absence record
        SELECT COUNT(*) INTO existing_absence 
        FROM absence 
        WHERE student_id = NEW.student_id AND absence_date = NEW.recordeddate;

        -- If the absence record already exists, update totalabsences
        IF existing_absence > 0 THEN
            UPDATE absence 
            SET totalabsences = totalabsences + 1 
            WHERE student_id = NEW.student_id AND absence_date = NEW.recordeddate;
        ELSE
            -- If no absence record exists, create a new record with totalabsences = 1
            INSERT INTO absence (student_id, totalabsences, absence_date) 
            VALUES (NEW.student_id, 1, NEW.recordeddate);
        END IF;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `attendancelog`
--

DROP TABLE IF EXISTS `attendancelog`;
CREATE TABLE `attendancelog` (
  `log_id` int(11) NOT NULL,
  `attendance_id` int(11) DEFAULT NULL,
  `student_id` int(11) DEFAULT NULL,
  `old_status` int(11) DEFAULT NULL,
  `new_status` int(11) DEFAULT NULL,
  `changed_by` int(11) DEFAULT NULL,
  `change_type` enum('INSERT','UPDATE','DELETE') DEFAULT NULL,
  `section_id` int(11) DEFAULT NULL,
  `action` varchar(50) DEFAULT NULL,
  `old_excused_status` int(11) DEFAULT NULL,
  `new_excused_status` int(11) DEFAULT NULL,
  `change_time` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `attendancelog`
--

TRUNCATE TABLE `attendancelog`;
--
-- Dumping data for table `attendancelog`
--

INSERT INTO `attendancelog` (`log_id`, `attendance_id`, `student_id`, `old_status`, `new_status`, `changed_by`, `change_type`, `section_id`, `action`, `old_excused_status`, `new_excused_status`, `change_time`) VALUES
(1, 2, 1, NULL, 2, NULL, 'INSERT', NULL, NULL, NULL, NULL, '2025-02-01 22:54:19'),
(2, 3, 2, NULL, 1, NULL, 'INSERT', NULL, NULL, NULL, NULL, '2025-02-01 22:54:19'),
(3, 4, 3, NULL, 1, NULL, 'INSERT', NULL, NULL, NULL, NULL, '2025-02-01 22:54:19'),
(5, 5, 1, NULL, 2, NULL, 'INSERT', NULL, NULL, NULL, NULL, '2025-02-01 22:54:19'),
(6, 6, 2, NULL, 2, NULL, 'INSERT', NULL, NULL, NULL, NULL, '2025-02-01 22:54:19'),
(7, 7, 3, NULL, 2, NULL, 'INSERT', NULL, NULL, NULL, NULL, '2025-02-01 22:54:19'),
(11, 8, 1, NULL, 2, NULL, 'INSERT', NULL, NULL, NULL, NULL, '2025-02-01 23:39:41'),
(12, 9, 2, NULL, 2, NULL, 'INSERT', NULL, NULL, NULL, NULL, '2025-02-01 23:39:41'),
(13, 10, 3, NULL, 2, NULL, 'INSERT', NULL, NULL, NULL, NULL, '2025-02-01 23:39:41');

-- --------------------------------------------------------

--
-- Table structure for table `attendancestatus`
--

DROP TABLE IF EXISTS `attendancestatus`;
CREATE TABLE `attendancestatus` (
  `attendancestatus_id` int(11) NOT NULL,
  `statusname` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `attendancestatus`
--

TRUNCATE TABLE `attendancestatus`;
--
-- Dumping data for table `attendancestatus`
--

INSERT INTO `attendancestatus` (`attendancestatus_id`, `statusname`) VALUES
(1, 'Present'),
(2, 'Absent'),
(3, 'Tardy');

-- --------------------------------------------------------

--
-- Table structure for table `communityservice`
--

DROP TABLE IF EXISTS `communityservice`;
CREATE TABLE `communityservice` (
  `cs_id` int(11) NOT NULL,
  `student_id` int(11) DEFAULT NULL,
  `absence_id` int(11) DEFAULT NULL,
  `hours` int(11) DEFAULT NULL,
  `assigneddate` date DEFAULT NULL,
  `completeddate` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `communityservice`
--

TRUNCATE TABLE `communityservice`;
--
-- Dumping data for table `communityservice`
--

INSERT INTO `communityservice` (`cs_id`, `student_id`, `absence_id`, `hours`, `assigneddate`, `completeddate`) VALUES
(1, 1, NULL, 1, '2025-02-01', NULL),
(2, 1, NULL, 1, '2025-02-01', NULL),
(3, 2, NULL, 1, '2025-02-01', NULL),
(4, 3, NULL, 1, '2025-02-01', NULL),
(5, 1, NULL, 1, '2025-02-02', NULL),
(6, 2, 8, 1, '2025-02-02', NULL),
(7, 3, 9, 1, '2025-02-02', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `communityservicedocumentation`
--

DROP TABLE IF EXISTS `communityservicedocumentation`;
CREATE TABLE `communityservicedocumentation` (
  `csdoc_id` int(11) NOT NULL,
  `student_id` int(11) DEFAULT NULL,
  `cs_id` int(11) DEFAULT NULL,
  `videourl` char(50) DEFAULT NULL,
  `verifiedby` int(11) DEFAULT NULL,
  `verifiedDate` date DEFAULT NULL,
  `verification_status_id` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `communityservicedocumentation`
--

TRUNCATE TABLE `communityservicedocumentation`;
--
-- Triggers `communityservicedocumentation`
--
DROP TRIGGER IF EXISTS `reset_cs_hours_after_verification`;
DELIMITER $$
CREATE TRIGGER `reset_cs_hours_after_verification` AFTER UPDATE ON `communityservicedocumentation` FOR EACH ROW BEGIN
    IF NEW.verification_status_id = 1 THEN  
        UPDATE CommunityService
        SET hours = 0 
        WHERE cs_id = NEW.cs_id;
    END IF;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `update_cs_duration`;
DELIMITER $$
CREATE TRIGGER `update_cs_duration` AFTER UPDATE ON `communityservicedocumentation` FOR EACH ROW BEGIN
    IF NEW.verification_status_id = 2 THEN
        UPDATE CommunityService
        SET hours = 0
        WHERE cs_id = NEW.cs_id;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `excusestatus`
--

DROP TABLE IF EXISTS `excusestatus`;
CREATE TABLE `excusestatus` (
  `excuse_status_id` int(11) NOT NULL,
  `status_name` enum('Unexcused','Excused') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `excusestatus`
--

TRUNCATE TABLE `excusestatus`;
--
-- Dumping data for table `excusestatus`
--

INSERT INTO `excusestatus` (`excuse_status_id`, `status_name`) VALUES
(1, 'Unexcused'),
(2, 'Excused');

-- --------------------------------------------------------

--
-- Table structure for table `pdsastaff`
--

DROP TABLE IF EXISTS `pdsastaff`;
CREATE TABLE `pdsastaff` (
  `staff_id` int(11) NOT NULL,
  `firstName` varchar(50) NOT NULL,
  `lastName` varchar(50) NOT NULL,
  `user_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `pdsastaff`
--

TRUNCATE TABLE `pdsastaff`;
--
-- Dumping data for table `pdsastaff`
--

INSERT INTO `pdsastaff` (`staff_id`, `firstName`, `lastName`, `user_id`) VALUES
(1, 'JhonRhey', 'Maturan', 5),
(2, 'Kerl', 'Batistis', 6);

-- --------------------------------------------------------

--
-- Table structure for table `role`
--

DROP TABLE IF EXISTS `role`;
CREATE TABLE `role` (
  `role_id` int(11) NOT NULL,
  `role_name` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `role`
--

TRUNCATE TABLE `role`;
--
-- Dumping data for table `role`
--

INSERT INTO `role` (`role_id`, `role_name`) VALUES
(1, 'Student'),
(2, 'Teacher'),
(3, 'PDSA');

-- --------------------------------------------------------

--
-- Table structure for table `section`
--

DROP TABLE IF EXISTS `section`;
CREATE TABLE `section` (
  `section_id` int(11) NOT NULL,
  `gradelevel` int(11) NOT NULL,
  `sectionname` varchar(50) NOT NULL,
  `strand_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `section`
--

TRUNCATE TABLE `section`;
--
-- Dumping data for table `section`
--

INSERT INTO `section` (`section_id`, `gradelevel`, `sectionname`, `strand_id`) VALUES
(1, 11, 'ICT 1', 4),
(2, 11, 'ICT 2', 4),
(3, 11, 'ICT 3', 4),
(4, 11, 'ICT 4', 4),
(5, 11, 'ICT 5', 4),
(6, 12, 'ICT 1', 4),
(7, 12, 'ICT 2', 4),
(8, 12, 'ICT 3', 4),
(9, 12, 'ICT 4', 4),
(10, 12, 'ICT 5', 4);

-- --------------------------------------------------------

--
-- Table structure for table `strand`
--

DROP TABLE IF EXISTS `strand`;
CREATE TABLE `strand` (
  `strand_id` int(11) NOT NULL,
  `strand_name` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `strand`
--

TRUNCATE TABLE `strand`;
--
-- Dumping data for table `strand`
--

INSERT INTO `strand` (`strand_id`, `strand_name`) VALUES
(1, 'Stem'),
(2, 'Abm'),
(3, 'Humms'),
(4, 'Ict'),
(5, 'He'),
(6, 'Ad');

-- --------------------------------------------------------

--
-- Table structure for table `student`
--

DROP TABLE IF EXISTS `student`;
CREATE TABLE `student` (
  `student_id` int(11) NOT NULL,
  `firstname` varchar(50) NOT NULL,
  `lastname` varchar(50) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `section_id` int(11) DEFAULT NULL,
  `strand_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `student`
--

TRUNCATE TABLE `student`;
--
-- Dumping data for table `student`
--

INSERT INTO `student` (`student_id`, `firstname`, `lastname`, `user_id`, `section_id`, `strand_id`) VALUES
(1, 'Hanz', 'Tahuran', 1, 8, 4),
(2, 'Jernald', 'Equipaje', 2, 8, 4),
(3, 'John', 'Luna', 3, 8, 4);

-- --------------------------------------------------------

--
-- Table structure for table `teacher`
--

DROP TABLE IF EXISTS `teacher`;
CREATE TABLE `teacher` (
  `teacher_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `section_id` int(11) DEFAULT NULL,
  `firstname` varchar(50) DEFAULT NULL,
  `lastname` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `teacher`
--

TRUNCATE TABLE `teacher`;
--
-- Dumping data for table `teacher`
--

INSERT INTO `teacher` (`teacher_id`, `user_id`, `section_id`, `firstname`, `lastname`) VALUES
(1, 4, 8, 'Yna', 'Baybay');

-- --------------------------------------------------------

--
-- Stand-in structure for view `teacherstudents`
-- (See below for the actual view)
--
DROP VIEW IF EXISTS `teacherstudents`;
CREATE TABLE `teacherstudents` (
`student_id` int(11)
,`firstname` varchar(50)
,`lastname` varchar(50)
,`section_id` int(11)
,`teacher_id` int(11)
);

-- --------------------------------------------------------

--
-- Table structure for table `teacher_sections`
--

DROP TABLE IF EXISTS `teacher_sections`;
CREATE TABLE `teacher_sections` (
  `teacher_id` int(11) NOT NULL,
  `section_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `teacher_sections`
--

TRUNCATE TABLE `teacher_sections`;
--
-- Dumping data for table `teacher_sections`
--

INSERT INTO `teacher_sections` (`teacher_id`, `section_id`) VALUES
(1, 8);

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `user_id` int(11) NOT NULL,
  `role_id` int(11) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `user`
--

TRUNCATE TABLE `user`;
--
-- Dumping data for table `user`
--

INSERT INTO `user` (`user_id`, `role_id`, `email`, `password`) VALUES
(1, 1, 'hjtahuran22776@liceo.edu.ph', 'liceo123'),
(2, 1, 'jequipaje90289@liceo.edu.ph', 'liceo123'),
(3, 1, 'jaluna37995@liceo.edu.ph', 'liceo123'),
(4, 2, 'yjbaybay63466@liceo.edu.ph', 'liceo123'),
(5, 3, 'jrmaturan23972@liceo.edu.ph', 'liceo123'),
(6, 3, 'kpbatistis39397@liceo.edu.ph', 'liceo123');

-- --------------------------------------------------------

--
-- Table structure for table `verificationstatus`
--

DROP TABLE IF EXISTS `verificationstatus`;
CREATE TABLE `verificationstatus` (
  `status_id` int(11) NOT NULL,
  `statusname` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Truncate table before insert `verificationstatus`
--

TRUNCATE TABLE `verificationstatus`;
--
-- Dumping data for table `verificationstatus`
--

INSERT INTO `verificationstatus` (`status_id`, `statusname`) VALUES
(1, 'Pending'),
(3, 'Rejected'),
(2, 'Verified');

-- --------------------------------------------------------

--
-- Structure for view `teacherstudents`
--
DROP TABLE IF EXISTS `teacherstudents`;

DROP VIEW IF EXISTS `teacherstudents`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `teacherstudents`  AS SELECT `s`.`student_id` AS `student_id`, `s`.`firstname` AS `firstname`, `s`.`lastname` AS `lastname`, `s`.`section_id` AS `section_id`, `t`.`teacher_id` AS `teacher_id` FROM (`student` `s` join `teacher` `t` on(`s`.`section_id` = `t`.`section_id`)) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `absence`
--
ALTER TABLE `absence`
  ADD PRIMARY KEY (`absence_id`),
  ADD KEY `FK_Student_ID` (`student_id`);

--
-- Indexes for table `attendance`
--
ALTER TABLE `attendance`
  ADD PRIMARY KEY (`attendance_id`),
  ADD KEY `FK_StudentID` (`student_id`),
  ADD KEY `FK_AttendanceStatusID` (`attendancestatus_id`),
  ADD KEY `FK_RecordedBy` (`recordedby`),
  ADD KEY `FKSection_ID` (`section_id`),
  ADD KEY `FK_excuse_status` (`excuse_status_id`);

--
-- Indexes for table `attendancelog`
--
ALTER TABLE `attendancelog`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `FKSectionid` (`section_id`),
  ADD KEY `FKSTUDENTidentification` (`student_id`),
  ADD KEY `FK_changed_by` (`changed_by`),
  ADD KEY `FK_old_excuse_status` (`old_excused_status`),
  ADD KEY `FK_new_excuse_status` (`new_excused_status`),
  ADD KEY `attendancelog_ibfk_1` (`attendance_id`);

--
-- Indexes for table `attendancestatus`
--
ALTER TABLE `attendancestatus`
  ADD PRIMARY KEY (`attendancestatus_id`);

--
-- Indexes for table `communityservice`
--
ALTER TABLE `communityservice`
  ADD PRIMARY KEY (`cs_id`),
  ADD KEY `FKstudent_id` (`student_id`),
  ADD KEY `FKabsence_id` (`absence_id`);

--
-- Indexes for table `communityservicedocumentation`
--
ALTER TABLE `communityservicedocumentation`
  ADD PRIMARY KEY (`csdoc_id`),
  ADD KEY `FKstudentid` (`student_id`),
  ADD KEY `FK_csid` (`cs_id`),
  ADD KEY `FK_verifiedby` (`verifiedby`),
  ADD KEY `FK_verification_status` (`verification_status_id`);

--
-- Indexes for table `excusestatus`
--
ALTER TABLE `excusestatus`
  ADD PRIMARY KEY (`excuse_status_id`);

--
-- Indexes for table `pdsastaff`
--
ALTER TABLE `pdsastaff`
  ADD PRIMARY KEY (`staff_id`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- Indexes for table `role`
--
ALTER TABLE `role`
  ADD PRIMARY KEY (`role_id`);

--
-- Indexes for table `section`
--
ALTER TABLE `section`
  ADD PRIMARY KEY (`section_id`),
  ADD KEY `FK_StrandID` (`strand_id`);

--
-- Indexes for table `strand`
--
ALTER TABLE `strand`
  ADD PRIMARY KEY (`strand_id`);

--
-- Indexes for table `student`
--
ALTER TABLE `student`
  ADD PRIMARY KEY (`student_id`),
  ADD KEY `FK_UserID` (`user_id`),
  ADD KEY `FK_SectionID` (`section_id`),
  ADD KEY `fk_student_strand` (`strand_id`);

--
-- Indexes for table `teacher`
--
ALTER TABLE `teacher`
  ADD PRIMARY KEY (`teacher_id`),
  ADD UNIQUE KEY `user_id` (`user_id`),
  ADD KEY `FK_section_id` (`section_id`);

--
-- Indexes for table `teacher_sections`
--
ALTER TABLE `teacher_sections`
  ADD PRIMARY KEY (`teacher_id`,`section_id`),
  ADD KEY `section_id` (`section_id`);

--
-- Indexes for table `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `role_id` (`role_id`);

--
-- Indexes for table `verificationstatus`
--
ALTER TABLE `verificationstatus`
  ADD PRIMARY KEY (`status_id`),
  ADD UNIQUE KEY `statusname` (`statusname`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `absence`
--
ALTER TABLE `absence`
  MODIFY `absence_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;

--
-- AUTO_INCREMENT for table `attendance`
--
ALTER TABLE `attendance`
  MODIFY `attendance_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `attendancelog`
--
ALTER TABLE `attendancelog`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `communityservice`
--
ALTER TABLE `communityservice`
  MODIFY `cs_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `communityservicedocumentation`
--
ALTER TABLE `communityservicedocumentation`
  MODIFY `csdoc_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `excusestatus`
--
ALTER TABLE `excusestatus`
  MODIFY `excuse_status_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `pdsastaff`
--
ALTER TABLE `pdsastaff`
  MODIFY `staff_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `section`
--
ALTER TABLE `section`
  MODIFY `section_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `student`
--
ALTER TABLE `student`
  MODIFY `student_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `teacher`
--
ALTER TABLE `teacher`
  MODIFY `teacher_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `user`
--
ALTER TABLE `user`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `absence`
--
ALTER TABLE `absence`
  ADD CONSTRAINT `FK_Student_ID` FOREIGN KEY (`student_id`) REFERENCES `student` (`student_id`) ON DELETE CASCADE;

--
-- Constraints for table `attendance`
--
ALTER TABLE `attendance`
  ADD CONSTRAINT `FKSection_ID` FOREIGN KEY (`section_id`) REFERENCES `section` (`section_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `FK_AttendanceStatusID` FOREIGN KEY (`attendancestatus_id`) REFERENCES `attendancestatus` (`attendancestatus_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `FK_RecordedBy` FOREIGN KEY (`recordedby`) REFERENCES `teacher` (`teacher_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `FK_StudentID` FOREIGN KEY (`student_id`) REFERENCES `student` (`student_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `FK_excuse_status` FOREIGN KEY (`excuse_status_id`) REFERENCES `excusestatus` (`excuse_status_id`) ON DELETE SET NULL;

--
-- Constraints for table `attendancelog`
--
ALTER TABLE `attendancelog`
  ADD CONSTRAINT `FKSTUDENTidentification` FOREIGN KEY (`student_id`) REFERENCES `student` (`student_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `FKSectionid` FOREIGN KEY (`section_id`) REFERENCES `section` (`section_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `FK_changed_by` FOREIGN KEY (`changed_by`) REFERENCES `pdsastaff` (`staff_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `FK_new_excuse_status` FOREIGN KEY (`new_excused_status`) REFERENCES `excusestatus` (`excuse_status_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `FK_old_excuse_status` FOREIGN KEY (`old_excused_status`) REFERENCES `excusestatus` (`excuse_status_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `attendancelog_ibfk_1` FOREIGN KEY (`attendance_id`) REFERENCES `attendance` (`attendance_id`);

--
-- Constraints for table `communityservice`
--
ALTER TABLE `communityservice`
  ADD CONSTRAINT `FKabsence_id` FOREIGN KEY (`absence_id`) REFERENCES `absence` (`absence_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `FKstudent_id` FOREIGN KEY (`student_id`) REFERENCES `student` (`student_id`) ON DELETE CASCADE;

--
-- Constraints for table `communityservicedocumentation`
--
ALTER TABLE `communityservicedocumentation`
  ADD CONSTRAINT `FK_csid` FOREIGN KEY (`cs_id`) REFERENCES `communityservice` (`cs_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `FK_verification_status` FOREIGN KEY (`verification_status_id`) REFERENCES `verificationstatus` (`status_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `FK_verifiedby` FOREIGN KEY (`verifiedby`) REFERENCES `pdsastaff` (`staff_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `FKstudentid` FOREIGN KEY (`student_id`) REFERENCES `student` (`student_id`) ON DELETE CASCADE;

--
-- Constraints for table `pdsastaff`
--
ALTER TABLE `pdsastaff`
  ADD CONSTRAINT `FK_PDSA_UserID` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `section`
--
ALTER TABLE `section`
  ADD CONSTRAINT `FK_StrandID` FOREIGN KEY (`strand_id`) REFERENCES `strand` (`strand_id`);

--
-- Constraints for table `student`
--
ALTER TABLE `student`
  ADD CONSTRAINT `FK_SectionID` FOREIGN KEY (`section_id`) REFERENCES `section` (`section_id`),
  ADD CONSTRAINT `FK_UserID` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`),
  ADD CONSTRAINT `fk_student_strand` FOREIGN KEY (`strand_id`) REFERENCES `strand` (`strand_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `teacher`
--
ALTER TABLE `teacher`
  ADD CONSTRAINT `FK_section_id` FOREIGN KEY (`section_id`) REFERENCES `section` (`section_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `FK_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `teacher_sections`
--
ALTER TABLE `teacher_sections`
  ADD CONSTRAINT `teacher_sections_ibfk_1` FOREIGN KEY (`teacher_id`) REFERENCES `teacher` (`teacher_id`),
  ADD CONSTRAINT `teacher_sections_ibfk_2` FOREIGN KEY (`section_id`) REFERENCES `section` (`section_id`);

--
-- Constraints for table `user`
--
ALTER TABLE `user`
  ADD CONSTRAINT `user_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `role` (`role_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
