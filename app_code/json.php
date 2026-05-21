<?php
header('Content-Type: application/json; charset=utf-8');
#$result_ip = $_SERVER['HTTP_X_REAL_IP'] ?? null;
$result_ff = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? null;
echo json_encode(['x_forwarded_for' => $result_ff]); # 'x_real_ip' => $result_ip, 'x_forwarded_for' => $result_ff
?>