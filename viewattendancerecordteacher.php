<?php
session_start(); // Start the session
include("database.php");

// Use default values if parameters are not provided
$section_id   = isset($_GET['section_id'])   ? $_GET['section_id']   : 8;
$recordeddate = isset($_GET['recordeddate']) ? $_GET['recordeddate'] : '';

// Build the base SQL query and initialize bind parameters
$sql = "SELECT s.student_id, s.firstname, s.lastname, 
               MAX(a.attendancestatus_id) AS attendancestatus_id 
        FROM student s 
        LEFT JOIN attendance a ON s.student_id = a.student_id 
        WHERE s.section_id = ?";

// If a recorded date is provided, add it as an additional filter.
if (!empty($recordeddate)) {
    $sql .= " AND a.recordeddate = ?";
}

$sql .= " GROUP BY s.student_id, s.firstname, s.lastname";

$types  = "i";
$params = [$section_id];

if (!empty($recordeddate)) {
    $types .= "s";
    $params[] = $recordeddate;
}

$stmt = $conn->prepare($sql);
if (!$stmt) {
    die("Prepare failed: " . $conn->error);
}

// Bind parameters dynamically
$bind_names = [];
$bind_names[] = $types;
for ($i = 0; $i < count($params); $i++) {
    $bind_names[] = &$params[$i];
}
call_user_func_array([$stmt, "bind_param"], $bind_names);

if (!$stmt->execute()) {
    die("Execute failed: " . $stmt->error);
}

// Attempt to get the result set using get_result() if available
if (method_exists($stmt, 'get_result')) {
    $result = $stmt->get_result();
    if (!$result) {
        die("Getting result failed: " . $stmt->error);
    }
} else {
    // Fallback for environments that do not support get_result()
    $stmt->store_result();
    $meta = $stmt->result_metadata();
    if (!$meta) {
        die("Result metadata failed: " . $stmt->error);
    }
    
    $result = [];
    $fields = [];
    $row = [];
    
    while ($field = $meta->fetch_field()) {
        $fields[] = &$row[$field->name];
    }
    
    call_user_func_array([$stmt, 'bind_result'], $fields);
    
    while ($stmt->fetch()) {
        $temp = [];
        foreach ($row as $key => $val) {
            $temp[$key] = $val;
        }
        $result[] = $temp;
    }
    // Indicate that $result is an array
    $resultIsArray = true;
}

// Mapping for attendance status
$statusMap = [
    1 => 'Present',
    2 => 'Absent',
    3 => 'Tardy'
];
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Attendance Record</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <!-- Back to Dashboard Button -->
  <div class="container">
    <a href="teacher_dashboard.php" class="back-button">Back to Dashboard</a>
  
    <h1>Student Attendance Record</h1>
    
    <form method="GET" action="">
      <label for="section_id">Section ID:</label>
      <input type="number" name="section_id" id="section_id" value="<?php echo htmlspecialchars($section_id); ?>" required>
      
      <label for="recordeddate">Recorded Date:</label>
      <input type="date" name="recordeddate" id="recordeddate" value="<?php echo htmlspecialchars($recordeddate); ?>">
      
      <button type="submit">Search</button>
    </form>
  
    <table>
      <tr>
        <th>Student Name</th>
        <th>Attendance Status</th>
      </tr>
      <?php 
      // If $result is an array (fallback), iterate using foreach
      if (isset($resultIsArray) && $resultIsArray === true) {
          foreach ($result as $row):
      ?>
          <tr>
            <td><?php echo htmlspecialchars($row['firstname'] . " " . $row['lastname']); ?></td>
            <td>
              <?php 
                $statusId = $row['attendancestatus_id'];
                echo htmlspecialchars(isset($statusMap[$statusId]) ? $statusMap[$statusId] : 'N/A');
              ?>
            </td>
          </tr>
      <?php 
          endforeach;
      } else {
          while ($row = $result->fetch_assoc()):
      ?>
          <tr>
            <td><?php echo htmlspecialchars($row['firstname'] . " " . $row['lastname']); ?></td>
            <td>
              <?php 
                $statusId = $row['attendancestatus_id'];
                echo htmlspecialchars(isset($statusMap[$statusId]) ? $statusMap[$statusId] : 'N/A');
              ?>
            </td>
          </tr>
      <?php endwhile; 
      }
      ?>
    </table>
  </div>
</body>
</html>
