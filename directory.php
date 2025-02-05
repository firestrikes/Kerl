<?php
// Define the upload directory
$uploadDir = "uploads/";

// Check if the directory exists, and create it if not
if (!is_dir($uploadDir)) {
    if (mkdir($uploadDir, 0777, true)) {
        echo "Directory created successfully!";
    } else {
        die("Error creating directory.");
    }
}
?>
