<?php  
include 'database.php';
session_start(); // Start the session

$recordeddate = date('Y-m-d'); 

// Check if attendance data was received
if (isset($_POST['attendance'])) {
    // Debugging output
    echo "Attendance data received: ";
    print_r($_POST['attendance']);  
    echo "<br>";

    $attendance = $_POST['attendance']; 

    // Start a transaction to handle all updates at once
    $conn->begin_transaction();

    try {
        foreach ($attendance as $student_id => $new_status) {
            // Fetch the student's section from the database (only for reference)
            $query = "SELECT section_id FROM student WHERE student_id = ?";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("i", $student_id);
            $stmt->execute();
            $result = $stmt->get_result();
            $student = $result->fetch_assoc();

            // Validate if the student's section is available
            if (!$student || !isset($student['section_id'])) {
                throw new Exception("Error: Student section not found for student ID: $student_id.");
            }

            // Fetch the old attendancestatus_id
            $oldStatusQuery = "SELECT attendancestatus_id FROM attendance WHERE student_id = ? AND recordeddate = ?";
            $oldStatusStmt = $conn->prepare($oldStatusQuery);
            $oldStatusStmt->bind_param("is", $student_id, $recordeddate);
            $oldStatusStmt->execute();
            $oldStatusResult = $oldStatusStmt->get_result();
            $old_status = $oldStatusResult->num_rows > 0 ? $oldStatusResult->fetch_assoc()['attendancestatus_id'] : null;
            $oldStatusStmt->close();

            // Insert or update attendance
            $stmt = $conn->prepare("INSERT INTO attendance (student_id, recordeddate, attendancestatus_id) 
                                    VALUES (?, ?, ?)
                                    ON DUPLICATE KEY UPDATE attendancestatus_id = VALUES(attendancestatus_id)");

            if ($stmt === false) {
                throw new Exception('Prepare failed: ' . $conn->error);
            }

            // Bind parameters and execute
            $stmt->bind_param("isi", $student_id, $recordeddate, $new_status);
            if (!$stmt->execute()) {
                throw new Exception("Error updating attendance for student ID: $student_id. Error: " . $stmt->error);
            }
            echo "Attendance recorded/updated for student ID: $student_id.<br>";

            // Handle absence update if the status is 'absent' (assuming absent status is represented by 2)
            if ($new_status == 2) {
                // Check if the absence already exists
                $absenceQuery = "SELECT * FROM absence WHERE student_id = ? AND absence_date = ?";
                $absenceStmt = $conn->prepare($absenceQuery);
                $absenceStmt->bind_param("is", $student_id, $recordeddate);
                $absenceStmt->execute();
                $absenceResult = $absenceStmt->get_result();

                if ($absenceResult->num_rows > 0) {
                    // If absence record exists, update the total absences
                    $absenceUpdateQuery = "UPDATE absence SET totalabsences = totalabsences + 1 
                                           WHERE student_id = ? AND absence_date = ?";
                    $absenceUpdateStmt = $conn->prepare($absenceUpdateQuery);
                    $absenceUpdateStmt->bind_param("is", $student_id, $recordeddate);
                    if (!$absenceUpdateStmt->execute()) {
                        throw new Exception("Error updating absence for student ID: $student_id.");
                    }
                    $absenceUpdateStmt->close();
                    echo "Absence record updated for student ID: $student_id.<br>";
                } else {
                    // Insert a new absence record
                    $absenceInsertQuery = "INSERT INTO absence (student_id, totalabsences, semesteryear, absence_date) 
                                           VALUES (?, 1, '2025-2026', ?)";
                    $absenceInsertStmt = $conn->prepare($absenceInsertQuery);
                    $absenceInsertStmt->bind_param("is", $student_id, $recordeddate);
                    if (!$absenceInsertStmt->execute()) {
                        throw new Exception("Error inserting absence for student ID: $student_id.");
                    }
                    $absenceInsertStmt->close();
                    echo "New absence record inserted for student ID: $student_id.<br>";
                }
            }

            // Log the status change in the attendancelog table
            $logQuery = "INSERT INTO attendancelog (student_id, old_status, new_status, change_timestamp) 
                         VALUES (?, ?, ?, NOW())"; // Log the change timestamp
            $logStmt = $conn->prepare($logQuery);
            $logStmt->bind_param("iii", $student_id, $old_status, $new_status);
            if (!$logStmt->execute()) {
                throw new Exception("Error logging status change for student ID: $student_id.");
            }
            echo "Status change logged for student ID: $student_id.<br>";
            $logStmt->close();
        }

        // Commit the transaction if everything was successful
        $conn->commit();
        echo "All updates were successful.";

    } catch (Exception $e) {
        // If an error occurs, roll back the transaction
        $conn->rollback();
        echo "Error: " . $e->getMessage() . "<br>";
    }
} else {
    echo "No attendance data received!";
}

// Redirect (optional)
header("Location: pdsa_attendancerecord.php");
exit;
?>
