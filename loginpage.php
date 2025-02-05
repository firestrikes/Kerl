<?php
session_start(); // Start the session
include("database.php");

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $email = mysqli_real_escape_string($conn, $_POST['email']);
    $password = mysqli_real_escape_string($conn, $_POST['password']);  // Escape the password to prevent SQL injection

    // Debugging: print the email and password to verify if they are being passed correctly
    echo "Email: " . $email . "<br>";
    echo "Password: " . $password . "<br>";

    // Fetch user info from the 'user' table
    $query = "SELECT * FROM user WHERE email='$email' LIMIT 1";
    $result = mysqli_query($conn, $query);

    if ($result && mysqli_num_rows($result) == 1) {
        $user = mysqli_fetch_assoc($result);

        // Debugging: print user data to verify if it's being fetched correctly
        echo "<pre>";
        print_r($user);
        echo "</pre>";

        // Directly compare the password
        if ($password == $user['password']) {
            $_SESSION['user_id'] = $user['id'];  // Ensure the 'id' field is correctly fetched
            $_SESSION['email'] = $user['email'];
            $_SESSION['role_id'] = $user['role_id'];

            if ($user['role_id'] == 2) { // Teacher login
                // Fetch teacher_id from the database
                $teacher_query = "SELECT teacher_id FROM teacher WHERE user_id = ? LIMIT 1";
                $stmt = $conn->prepare($teacher_query);
                $stmt->bind_param("i", $user['id']);
                $stmt->execute();
                $stmt->bind_result($teacher_id);
                $stmt->fetch();
                $_SESSION['teacher_id'] = $teacher_id; // Store teacher_id in session
            
                // Optionally, set cookies for persistent login (if needed)
                setcookie('teacher_id', $teacher_id, time() + (30 * 24 * 60 * 60), "/");
            
                $stmt->close();
            
            
                // Fetch assigned sections for the teacher
                $sections_query = "SELECT section_id FROM teacher_sections WHERE teacher_id = ?";  // Assuming teacher_sections table exists
                $stmt = $conn->prepare($sections_query);
                $stmt->bind_param("i", $teacher_id);
                $stmt->execute();
                $stmt->bind_result($section_id);
                $assigned_sections = [];
                while ($stmt->fetch()) {
                    $assigned_sections[] = $section_id;
                }
                $_SESSION['assigned_sections'] = $assigned_sections;  // Store assigned sections in the session
                $stmt->close();
            }

            // For students, you need to store the student_id
            if ($user['role_id'] == 1) { // Assuming role_id 1 is for students
                // Fetch the student_id from the database (if it's not already stored)
                $student_query = "SELECT student_id FROM student WHERE user_id = ? LIMIT 1";  // Assuming students table exists
                $stmt = $conn->prepare($student_query);
                $stmt->bind_param("i", $user['id']);
                $stmt->execute();
                $stmt->bind_result($student_id);
                $stmt->fetch();
                $_SESSION['student_id'] = $student_id;  // Store the student_id in the session
                $stmt->close();
            }

            // For PDSA, you need to store the pdsa_id
            if ($user['role_id'] == 3) { // Assuming role_id 3 is for PDSA
                // Fetch the pdsa_id from the database (if it's not already stored)
                $pdsa_query = "SELECT staff_id FROM pdsastaff WHERE user_id = ? LIMIT 1";  // Assuming pdsa table exists
                $stmt = $conn->prepare($pdsa_query);
                $stmt->bind_param("i", $user['id']);
                $stmt->execute();
                $stmt->bind_result($staff_id);
                $stmt->fetch();
                $_SESSION['pdsa_id'] = $staff_id;  // Store the pdsa_id in the session
                $stmt->close();
            }

            // Redirect based on role_id
            if ($user['role_id'] == 1) {
                header("Location: student_dashboard.php");
            } elseif ($user['role_id'] == 2) {
                header("Location: teacher_dashboard.php");
            } elseif ($user['role_id'] == 3) {
                header("Location: pdsa_dashboard.php");
            }
            exit(); // Ensure no further code runs after the redirect
        } else {
            echo "<script>alert('Invalid email or password');</script>";
        }
    } else {
        echo "<script>alert('User not found');</script>";
    }
}
?>

<!DOCTYPE html>
<html lang="en">

<head>
    <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js"></script>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AttendEase Dashboard</title>
    <link rel="stylesheet" href="loginpage.css">
</head>

<body>
    <section id="login-page">
        <div class="login-box">
            <form id="login-form" method="POST">
                <h2>Login</h2>
                <div class="input-box">
                    <span class="icon"><ion-icon name="mail"></ion-icon></span>
                    <input type="email" id="email" name="email" required>
                    <label for="email">Email</label>
                </div>
                <div class="input-box">
                    <span class="icon"><ion-icon name="lock-closed"></ion-icon></span>
                    <input type="password" id="password" name="password" required>
                    <label for="password">Password</label>
                </div>
                <div class="remember-forgot">
                    <label><input type="checkbox" name="remember"> Remember me</label>
                </div>
                <button type="submit">Login</button>
            </form>
        </div>
    </section>
</body>

</html>
