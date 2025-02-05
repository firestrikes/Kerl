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
    <title>AttendEase Dashboard</title>
    <link rel="stylesheet" href="pdsadashboard.css">
</head>

<body>
    <div id="dashboard">
        <aside class="sidebar">
            <div class="brand">
                <h2>AttendEase</h2>
            </div>
            <nav>
                <ul>
                    <li><a href="#dashboard" class="active"><ion-icon name="home"></ion-icon> Dashboard</a></li>
                    <li class="more">
                        <a href="#more"><ion-icon name="menu"></ion-icon> More</a>
                        <div class="dropdown-menu">
                            <a href="#">Profile</a>
                            <a href="#">Settings</a>
                            <a href="#" id="logout" class="logout-button" onclick="return confirmLogout()">Logout</a>
                        </div>
                    </li>
                </ul>
            </nav>
        </aside>

        <header class="header">
            <h1>Dashboard</h1>
            <p>Administrator Dashboard</p>
        </header>

        <main class="main-content">
            <section class="card">
                <h3>Confirm Community Services Documentations</h3>
                <p>Documentations</p><br>
                <a href="confirmcommunityservice.php"> <!-- Link to the community services page -->
                    <button id="viewDetailsBtn">View Details</button>
                </a>
            </section>

            <section class="card">
                <h3>Manage Attendance</h3>
                <p>View</p>
                <a href="pdsa_attendancerecord.php"><br><!-- Link to the attendance page -->
                    <button id="viewAttendanceBtn">View Details</button>
                </a>
            </section>

        </main>
    </div>

    <script>
        // Function to confirm logout
        function confirmLogout() {
            // Show a confirmation prompt
            var confirmAction = confirm("Are you sure you want to log out?");
            if (confirmAction) {
                // If user confirms, log them out by redirecting to logout.php
                window.location.href = 'logout.php'; // Redirect to a logout script or login page
                return true;
            } else {
                // If user cancels, do nothing (stay on the current page)
                return false;
            }
        }
    </script>
</body>

</html>
