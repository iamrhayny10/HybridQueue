<?php
date_default_timezone_set('Asia/Manila');

// ── ML Service URL ─────────────────────────────────────────────
define('ML_URL',      'http://localhost:5001/predict');
define('ML_URL_BASE', 'http://localhost:5001');

// ── Claude AI API Key (optional — for Analytics Insights) ──────
// Get key at https://console.anthropic.com/
// Leave empty to use data-driven rule-based insights (free)
define('CLAUDE_API_KEY', '');

// ── Database config ────────────────────────────────────────────
define('DB_HOST',    'localhost');
define('DB_PORT',    '3306');
define('DB_NAME',    'queue_tracking_db');
define('DB_USER',    'root');
define('DB_PASS',    '');
define('DB_CHARSET', 'utf8mb4');

// ── Helpers ────────────────────────────────────────────────────
function getDB() {
    static $pdo = null;
    if ($pdo) return $pdo;
    $dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=%s', DB_HOST, DB_PORT, DB_NAME, DB_CHARSET);
    $pdo = new PDO($dsn, DB_USER, DB_PASS, array(
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ));
    return $pdo;
}

function sendHeaders() {
    header('Content-Type: application/json; charset=utf-8');
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Auth-Token, bypass-tunnel-reminder, ngrok-skip-browser-warning, User-Agent');
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
}

// PHP 7 compatible — no 'mixed' type hint
function jsonOut($d, $c = 200) {
    http_response_code($c);
    echo json_encode($d, JSON_UNESCAPED_UNICODE);
    exit;
}

function jsonError($m, $c = 400) {
    jsonOut(array('success'=>false,'error'=>$m), $c);
}

function logAction($uid, $t, $d) {
    try {
        getDB()->prepare('INSERT INTO activity_logs(user_id,action_type,action_detail)VALUES(?,?,?)')->execute(array($uid,$t,$d));
    } catch (Exception $e) {}
}
