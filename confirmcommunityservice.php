<?php
include("database.php"); // Database connection

// Fetch all video records from the database
$query = "SELECT * FROM communityservicedocumentation";
$result = mysqli_query($conn, $query);
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin - Community Service Video Review</title>
    
    <!-- Include your CSS for styling -->
    <link rel="stylesheet" href="style.css"> 
</head>
<body>

    <h1>Community Service Video Documentation - Admin Review</h1>

    <!-- Back to Dashboard Button -->
    <div>
        <a href="pdsa_dashboard.php"><button>Back to Dashboard</button></a>
    </div>
    
    <table class="video-table">
        <thead>
            <tr>
                <th>Student ID</th>
                <th>Community Service ID</th>
                <th>Video</th>
                <th>Verification Status</th>
                <th>Verified By</th>
                <th>Verification Date</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            <?php
            if ($result) {
                while ($row = mysqli_fetch_assoc($result)) {
                    // Fetch video details
                    $csdoc_id = $row['csdoc_id'];
                    $student_id = $row['student_id'];
                    $cs_id = $row['cs_id'];
                    $videourl = $row['videourl'];
                    $verification_status_id = $row['verification_status_id'];
                    $verifiedby = $row['verifiedby'];
                    $verifiedDate = $row['verifiedDate'];

                    // Map verification status
                    $verification_status = $verification_status_id == 1 ? "Pending" : "Verified";

                    echo "
                    <tr>
                        <td>$student_id</td>
                        <td>$cs_id</td>
                        <td><a href='$videourl' target='_blank'>View Video</a></td>
                        <td>$verification_status</td>
                        <td>$verifiedby</td>
                        <td>$verifiedDate</td>
                        <td>
                            <form action='verify_video.php' method='POST'>
                                <input type='hidden' name='csdoc_id' value='$csdoc_id'>
                                <input type='submit' value='Verify' " . ($verification_status_id == 2 ? "disabled" : "") . ">
                            </form>
                        </td>
                    </tr>
                    ";
                }
            } else {
                echo "<tr><td colspan='7'>No videos found.</td></tr>";
            }
            ?>
        </tbody>
    </table>

</body>
</html>
