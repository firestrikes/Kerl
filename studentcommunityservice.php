<?php
session_start(); // Start the session
include("database.php");
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js"></script>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Community Service</title>
    <link rel="stylesheet" href="studentcommunityservice.css">
</head>
<body>
    <!-- Dashboard or another page content -->
    <div id="dashboard">
        <button id="viewDetailsBtn">View Community Service Details</button>
    </div>

    <!-- Community Service Page -->
    <div id="community-service-page" style="background-image: url('liceobg.jpg'); background-size: cover; min-height: 100vh; display: none;">
        <div class="community-service-container">
            <h1>Community Services Documentations</h1>
            <p id="community-service-date"></p>
        </div>
        <div class="cardofadd">
            <div class="card-content">
                <span class="left-label">Documentation</span>
                <span class="right-label">Turn in</span>
            </div>
            <div class="card-buttons">
                <div class="dropdown">
                    <button class="add-button">+ Add or create</button>
                </div>
            </div>
        </div>
        <button class="mark-button">Mark as done</button>
        <div class="backtothedashboard">
            <button id="backToDashboardFromService">Back to Dashboard</button>
        </div>

        <!-- Video Upload Form -->
        <div class="upload-form">
            <h2>Upload Video Documentation</h2>
            <form action="upload_video.php" method="POST" enctype="multipart/form-data">
                <label for="videoFile">Choose a video to upload:</label>
                <input type="file" name="videoFile" id="videoFile" accept="video/*" required>
                <br>
                <input type="submit" value="Upload Video">
            </form>
        </div>

    </div>

    <script>
        // Show community service page when button is clicked
        document.getElementById('viewDetailsBtn').addEventListener('click', function () {
            document.getElementById('dashboard').style.display = 'none';
            document.getElementById('community-service-page').style.display = 'block';
            const dateElement = document.getElementById('community-service-date');
            const currentDate = new Date().toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'long',
                day: 'numeric'
            });
            dateElement.textContent = currentDate;
        });

        // Hide community service page and return to dashboard
        document.getElementById('backToDashboardFromService').addEventListener('click', function () {
            document.getElementById('dashboard').style.display = 'block';
            document.getElementById('community-service-page').style.display = 'none';
        });

        // Automatically display current date on page load
        document.addEventListener('DOMContentLoaded', function () {
            const dateElement = document.getElementById('community-service-date');
            const currentDate = new Date().toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'long',
                day: 'numeric'
            });
            dateElement.textContent = currentDate;
        });
    </script>
</body>
</html>
