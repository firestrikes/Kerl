<?php
session_start(); // Start the session to access session variables
include("database.php"); // Include the database connection
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Upload Video</title>
    <link rel="stylesheet" href="studentcommunityservicesdocumentation.css">
</head>
<body>
    <h1 class="header">Upload Video</h1>

    <!-- Form that submits to upload.php for processing -->
    <form action="upload.php" method="post" enctype="multipart/form-data">
        <input type="file" name="video" accept="video/*" required>
        <button type="submit">Upload</button>
    </form>

    <div class="container">
        <a href="student_dashboard.php" class="back-button">Back to Dashboard</a>
    </div>
</body>
</html>
