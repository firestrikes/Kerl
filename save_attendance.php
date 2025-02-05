<?php 
include 'database.php';
session_start(); // Start the session

$recordeddate = date('Y-m-d'); 

// Check if attendance data was received
if (isset($_POST['attendance'])) {
    $attendance = $_POST['attendance']; 

    foreach ($attendance as $student_id => $status_id) {
        // Fetch the student's section from the database (only for reference)
        $query = "SELECT section_id FROM student WHERE student_id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $student_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $student = $result->fetch_assoc();

        // Validate if the student's section is available (This is just for reference, no need to check assigned section)
        if (!$student || !isset($student['section_id'])) {
            die("Error: Student section not found.");
        }

        // Insert or update attendance (no section check)
        $stmt = $conn->prepare("INSERT INTO attendance (student_id, recordeddate, attendancestatus_id) 
                                VALUES (?, ?, ?)
                                ON DUPLICATE KEY UPDATE attendancestatus_id = VALUES(attendancestatus_id)");

        if ($stmt === false) {
            die('Prepare failed: ' . $conn->error);
        }

        // Bind parameters and execute
        $stmt->bind_param("isi", $student_id, $recordeddate, $status_id);

        if ($stmt->execute()) {
            echo "Attendance recorded/updated for student ID: $student_id.<br>";

            // If the status is 'absent' (assuming absent status is represented by 2, adjust as needed)
            if ($status_id == 2) {
                // Check if the student already has an absence record for today
                $absenceQuery = "SELECT * FROM absence WHERE student_id = ? AND absence_date = ?";
                $absenceStmt = $conn->prepare($absenceQuery);
                $absenceStmt->bind_param("is", $student_id, $recordeddate);
                $absenceStmt->execute();
                $absenceResult = $absenceStmt->get_result();

                // Debugging output
                if ($absenceResult->num_rows > 0) {
                    echo "Absence record exists for student ID: $student_id.<br>";
                    // If absence record exists, update the total absences
                    $absenceUpdateQuery = "UPDATE absence SET totalabsences = totalabsences + 1 
                                           WHERE student_id = ? AND absence_date = ?";
                    $absenceUpdateStmt = $conn->prepare($absenceUpdateQuery);
                    $absenceUpdateStmt->bind_param("is", $student_id, $recordeddate);
                    if ($absenceUpdateStmt->execute()) {
                        echo "Absence updated for student ID: $student_id.<br>";
                    } else {
                        echo "Error updating absence: " . $absenceUpdateStmt->error . "<br>";
                    }
                    $absenceUpdateStmt->close();
                } else {
                    // If no record exists, insert a new absence record
                    $absenceInsertQuery = "INSERT INTO absence (student_id, totalabsences, semesteryear, absence_date) 
                                           VALUES (?, 1, '2025-2026', ?)";
                    $absenceInsertStmt = $conn->prepare($absenceInsertQuery);
                    $absenceInsertStmt->bind_param("is", $student_id, $recordeddate);
                    if ($absenceInsertStmt->execute()) {
                        echo "New absence record inserted for student ID: $student_id.<br>";
                    } else {
                        echo "Error inserting absence: " . $absenceInsertStmt->error . "<br>";
                    }
                    $absenceInsertStmt->close();
                }
            }

        } else {
            echo "Error updating attendance for student ID: $student_id. Error: " . $stmt->error . "<br>";
        }

        $stmt->close();
    }
} else {
    echo "No attendance data received!";
}

// Redirect (optional)
header("Location: teacher_dashboard.php");
exit;
?>
