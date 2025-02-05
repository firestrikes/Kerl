<?php
session_start();  // Start the session

// Destroy the session to log the user out
session_destroy();

// Redirect to the login page
header("Location: loginpage.php");
exit();
?>
