<?php
header('Content-Type: text/plain; charset=utf-8');
echo "=== ОТВЕТ PHP БЭКЕНДА ===\n\n";

echo "Ваш IP, как его видит PHP (REMOTE_ADDR): " . $_SERVER['REMOTE_ADDR'] . "\n\n";
echo "Ваш реальный IP, как его видит PHP (REAL_IP): " . $_SERVER['HTTP_X_REAL_IP'] . "\n\n";

echo "Полученные HTTP-заголовки:\n";
$headers = [];
foreach ($_SERVER as $key => $value) {
    if (strpos($key, 'HTTP_') === 0) {
        $headerName = str_replace(' ', '-', ucwords(str_replace('_', ' ', strtolower(substr($key, 5)))));
        echo "- $headerName: $_SERVER[$key]\n";
    }
}
?>