<?php
include("database.php"); // Include the database connection

// Error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Check if a file was uploaded
if (isset($_FILES['video'])) {
    $targetDir = "uploads/"; // Define the upload directory

    // Check if the directory exists, create it if not
    if (!is_dir($targetDir)) {
        mkdir($targetDir, 0755, true); // Create directory if it doesn't exist
    }

    // Full path to the target file
    $targetFile = $targetDir . basename($_FILES["video"]["name"]);
    $uploadOk = 1;
    $videoFileType = strtolower(pathinfo($targetFile, PATHINFO_EXTENSION));

    // Check file size (limit to 50MB)
    if ($_FILES["video"]["size"] > 50000000) {
        echo "🚨 Sorry, your file is too large. Max size is 50MB.";
        $uploadOk = 0;
    }

    // Allow certain file formats
    $allowedTypes = ["mp4", "avi", "mov", "flv", "wmv"];
    if (!in_array($videoFileType, $allowedTypes)) {
        echo "🚨 Sorry, only MP4, AVI, MOV, FLV, and WMV files are allowed.";
        $uploadOk = 0;
    }

    // If $uploadOk is 0, stop further processing
    if ($uploadOk == 0) {
        echo "🚨 Sorry, your file was not uploaded.";
    } else {
        // If everything is OK, try to upload the file
        if (move_uploaded_file($_FILES["video"]["tmp_name"], $targetFile)) {
            echo "✅ The file " . htmlspecialchars(basename($_FILES["video"]["name"])) . " has been uploaded.";

            // Set default values for verification fields
            $verifiedby = null; // Will be updated when verified
            $verifiedDate = null; // Will be updated when verified
            $verification_status_id = 1; // Default status (Pending)

            // Ensure the database connection exists and is valid
            if ($conn === false) {
                die("🚨 Database connection failed: " . mysqli_connect_error());
            }

            // Prepare the database insertion query
            $query = "INSERT INTO communityservicedocumentation (videourl, verifiedby, verifiedDate, verification_status_id) 
                      VALUES (?, ?, ?, ?)";

            if ($stmt = mysqli_prepare($conn, $query)) {
                // Bind parameters to the query
                mysqli_stmt_bind_param($stmt, 'sssi', $targetFile, $verifiedby, $verifiedDate, $verification_status_id);

                // Execute the query and check if it was successful
                if (mysqli_stmt_execute($stmt)) {
                    echo "✅ Video uploaded successfully to the database!";

                    // Redirect back to the student dashboard
                    header("Location: student_dashboard.php");
                    exit(); // Make sure the script stops after the redirect
                } else {
                    echo "🚨 Database error: " . mysqli_stmt_error($stmt); // Output database error if the insert fails
                }
                mysqli_stmt_close($stmt); // Close the prepared statement
            } else {
                echo "🚨 Failed to prepare the database query: " . mysqli_error($conn);
            }

        } else {
            echo "🚨 Sorry, there was an error uploading your file.";
        }
    }
} else {
    echo "🚨 No file uploaded.";
}
?>
