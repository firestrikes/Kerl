<?php
include("database.php"); // Database connection

// Get filter parameters from GET (if set)
$section_id   = isset($_GET['section_id']) ? $_GET['section_id'] : "";
$date_filter  = isset($_GET['date'])       ? $_GET['date']       : "";
$strand_id    = isset($_GET['strand_id'])  ? $_GET['strand_id']  : "";

// Build the base SQL query
$query = "SELECT s.student_id, CONCAT(s.firstname, ' ', s.lastname) AS student_name, 
                 COUNT(a.attendance_id) AS total_absences,
                 es.excuse_status_id
          FROM student s
          LEFT JOIN attendance a ON s.student_id = a.student_id
          LEFT JOIN excusestatus es ON a.excuse_status_id = es.excuse_status_id";

// Build conditions array for filtering
$conditions = [];
$params = [];
$types = "";

// If a section filter is provided, add it
if (!empty($section_id)) {
    $conditions[] = "s.section_id = ?";
    $params[] = $section_id;
    $types .= "i";
}

// If a date filter is provided, add it
if (!empty($date_filter)) {
    $conditions[] = "a.recordeddate = ?";
    $params[] = $date_filter;
    $types .= "s";
}

// If a strand filter is provided, add it
if (!empty($strand_id)) {
    $conditions[] = "s.strand_id = ?";
    $params[] = $strand_id;
    $types .= "i";
}

// If we have conditions, append them to the query
if (count($conditions) > 0) {
    $query .= " WHERE " . implode(" AND ", $conditions);
}

// Group by student to ensure unique results
$query .= " GROUP BY s.student_id";

$stmt = $conn->prepare($query);
if ($stmt === false) {
    die("Prepare failed: " . $conn->error);
}

// Bind parameters dynamically if any
if (!empty($params)) {
    $bind_names = [];
    $bind_names[] = $types;
    for ($i = 0; $i < count($params); $i++) {
        $bind_names[] = &$params[$i];
    }
    call_user_func_array([$stmt, "bind_param"], $bind_names);
}

$stmt->execute();
$result = $stmt->get_result();
?>

<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PDSA - Modify Attendance</title>
  <link rel="stylesheet" href="pdsa_attendance.css">
</head>

<body>
  <div id="dashboard">
    <h1>Attendance Records</h1>

    <!-- Filter Form -->
    <form method="GET" action="">
      <label for="section_id">Section ID:</label>
      <input type="number" name="section_id" id="section_id" value="<?php echo htmlspecialchars($section_id); ?>">

      <label for="date">Recorded Date:</label>
      <input type="date" name="date" id="date" value="<?php echo htmlspecialchars($date_filter); ?>">

      <label for="strand_id">Strand:</label>
      <select name="strand_id" id="strand_id">
        <option value="">--Select Strand--</option>
        <?php
        // Fetch strand options from the database
        $strandQuery = "SELECT strand_id, strand_name FROM strand";
        $strandResult = $conn->query($strandQuery);
        if ($strandResult) {
            while ($strandRow = $strandResult->fetch_assoc()) {
                // If the strand_id matches the current filter, mark as selected.
                $selected = ($strand_id == $strandRow['strand_id']) ? "selected" : "";
                echo '<option value="' . $strandRow['strand_id'] . '" ' . $selected . '>' . htmlspecialchars($strandRow['strand_name']) . '</option>';
            }
        }
        ?>
      </select>
      
      <button type="submit">Filter</button>
    </form>

    <!-- Back to Dashboard Button -->
    <a href="pdsa_dashboard.php" class="back-button">Back to Dashboard</a>

    <!-- Attendance Table -->
    <form method="POST" action="update_attendance_status.php">
      <table>
        <thead>
          <tr>
            <th>Student Name</th>
            <th>Total Absences</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <?php while ($row = $result->fetch_assoc()) { ?>
            <tr>
              <td><?php echo htmlspecialchars($row['student_name']); ?></td>
              <td>
                <?php
                  // If the absence is excused (excuse_status_id == 2), display 0 absences; otherwise, display the count.
                  echo ($row['excuse_status_id'] == 2) ? 0 : $row['total_absences'];
                ?>
              </td>
              <td>
                <!-- Dropdown to select Excused or Unexcused -->
                <select name="excuse_status[<?php echo $row['student_id']; ?>]">
                  <option value="1" <?php echo ($row['excuse_status_id'] == 1) ? "selected" : ""; ?>>Unexcused</option>
                  <option value="2" <?php echo ($row['excuse_status_id'] == 2) ? "selected" : ""; ?>>Excused</option>
                </select>
              </td>
            </tr>
          <?php } ?>
        </tbody>
      </table>
      <!-- Submit the form to update all changes -->
      <button type="submit">Update Attendance</button>
    </form>
  </div>
</body>
</html>

<?php
$stmt->close();
$conn->close();
?>
