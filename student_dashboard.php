<?php
include("database.php"); // Ensure you have the database connection

// Fetch the student data (You may need to adjust this query depending on your actual table structure)
$query = "SELECT student_id FROM student LIMIT 1"; // Assuming the student table has a field 'student_id'
$stmt = $conn->prepare($query);

if ($stmt === false) {
    die("Error preparing statement: " . $conn->error);
}

$stmt->execute();
$result = $stmt->get_result();

if ($result === false) {
    die("Error executing query: " . $stmt->error);
}

$row = $result->fetch_assoc();

// Assuming you have only one student or fetching the first student record
$student_id = $row['student_id'];

$stmt->close();

// Database query to get the total absences for the student
$query = "
    SELECT COUNT(a.attendance_id) AS total_absences
    FROM attendance a
    LEFT JOIN excusestatus es ON a.excuse_status_id = es.excuse_status_id
    WHERE a.student_id = ?
    GROUP BY a.student_id
";
$stmt = $conn->prepare($query);

if ($stmt === false) {
    die("Error preparing statement: " . $conn->error);
}

$stmt->bind_param("i", $student_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result === false) {
    die("Error executing query: " . $stmt->error);
}

$row = $result->fetch_assoc();
$total_absences = $row ? $row['total_absences'] : 0;

$stmt->close();
?>

<!DOCTYPE html>
<html lang="en">

<head>
    <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js"></script>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AttendEase Dashboard</title>
    <link rel="stylesheet" href="student_dashboard.css">

    <script>
        // Function to show logout confirmation
        function confirmLogout(event) {
            event.preventDefault();  // Prevent the default link behavior

            // Show a confirmation dialog
            const isConfirmed = confirm("Are you sure you want to logout?");

            // If the user confirms, redirect to login page
            if (isConfirmed) {
                window.location.href = "loginpage.php"; // Redirect to your login page
            }
        }
    </script>
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
                            <!-- Logout link with confirmation -->
                            <a href="javascript:void(0);" onclick="confirmLogout(event)" id="logout">Logout</a> 
                        </div>
                    </li>
                </ul>
            </nav>
        </aside>

        <header class="header">
            <h1>Dashboard</h1>
        </header>

        <main class="main-content">
            <!-- Check Community Services Section -->
            <section class="card">
                <br>
                <h3>Check Community Services Documentations</h3>
                <p>Documentations</p><br>
                <a href= "studentcommunityservicesdocumentation.php"> <!-- Corrected path -->
                    <button id="viewDetailsBtn">View Details</button>
                </a>
            </section>

            <script>
                document.getElementById('viewDetailsBtn').addEventListener('click', function() {
                    window.location.href = "studentcommunityservice.php";  // Corrected path
                });
            </script>

            <!-- Attendance Record Section -->
            <section class="card">
                <br><br>
                <h3>Attendance Record</h3>
                <p>Absences: <strong><?php echo $total_absences; ?></strong></p>
            </section>

            <script>
                document.getElementById('viewAttendanceBtn').addEventListener('click', function() {
                    window.location.href = "studentattendancerecord.php";  // Corrected path
                });
            </script>
        </main>
    </div>

    <script>
        document.getElementById('logout').addEventListener('click', function (event) {
            confirmLogout(event);  // Ensure logout confirmation is triggered
        });

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

        document.getElementById('viewAttendanceBtn').addEventListener('click', function () {
            document.getElementById('dashboard').style.display = 'none';
            document.getElementById('attendance-record-page').style.display = 'block';
        });

        document.getElementById('backToDashboardFromService').addEventListener('click', function () {
            document.getElementById('dashboard').style.display = 'block';
            document.getElementById('community-service-page').style.display = 'none';
        });
    </script>
</body>

</html>
