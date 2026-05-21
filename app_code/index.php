<?php
header('Content-Type: text/plain; charset=utf-8');
echo "=== ОТВЕТ PHP БЭКЕНДА ===\n";
#echo "X-Real-Ip: " . htmlspecialchars($_SERVER['HTTP_X_REAL_IP']) . "\n";
echo "X-Forwarded-For: " . htmlspecialchars($_SERVER['HTTP_X_FORWARDED_FOR']) . "\n";
?>