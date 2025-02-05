<?php
session_start(); // Start the session
include("database.php");

$teacher_id = $_SESSION['teacher_id'];
$assigned_sections = $_SESSION['assigned_sections'];

?>
<!DOCTYPE html>
<html lang="en">

<head>
    <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js"></script>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AttendEase Dashboard</title>
    <link rel="stylesheet" href="pdsadashboard.css">
    <script>
        // Function to show logout confirmation
        function confirmLogout(event) {
            event.preventDefault();  // Prevent the default link behavior

            // Show a confirmation dialog
            const isConfirmed = confirm("Are you sure you want to logout?");

            // If the user confirms, redirect to login page
            if (isConfirmed) {
                window.location.href = "loginpage.php";
            }
        }
    </script>
</head>

<body>
    <div id="dashboard">
        <!-- Sidebar -->
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
                            <a href="javascript:void(0);" onclick="confirmLogout(event)" id="logout">Logout</a> <!-- Logout with confirmation -->
                        </div>
                    </li>
                </ul>
            </nav>
        </aside>

        <!-- Header -->
        <header class="header">
            <h1>Dashboard</h1>
            <p>Teacher Dashboard</p>
        </header>

        <!-- Main Content -->
        <main class="main-content">
            <!-- Content Cards (Visible only after login) -->
            <section class="card">
                <br>
                <h3>Community Services Documentations</h3>
                <p>View</p> <br>
                <button id="viewDetailsBtn">View Details</button>
            </section>
            
            <section class="card">
                 <br>
                 <h3>Attendance Record of Student</h3>
                 <p>Record Attendance of Handled Section</p>
                 <a href="attendance_form.php"><br>
                    <button id="viewAttendanceBtn">View Details</button>
                 </a>
            </section>

            <section class="card">
                <br>
                <h3>View Attendance Record</h3>
                <p>View Records</p>
                <a href="viewattendancerecordteacher.php"><br>
                    <button id="viewAttendanceBtn">View Details</button>
                </a>
            </section>
        </main>
    </div>
</body>

</html>
