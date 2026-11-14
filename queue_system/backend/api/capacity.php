<?php
require_once __DIR__.'/../config/db.php';
sendHeaders();
$db=getDB();

// Get DB credentials from config to pass to ML service
$body=json_encode([
  'host'    =>DB_HOST,
  'user'    =>DB_USER,
  'password'=>DB_PASS,
  'database'=>DB_NAME,
  'date'    =>$_GET['date']??date('Y-m-d'),
]);

$ctx=stream_context_create(['http'=>[
  'method' =>'POST',
  'timeout'=>8,
  'header' =>"Content-Type: application/json\r\nContent-Length:".strlen($body),
  'content'=>$body,
]]);

$r=@file_get_contents(ML_URL_BASE.'/capacity',false,$ctx);
if(!$r){
  // ML not running — return basic fallback
  jsonOut(['success'=>true,'fallback'=>true,'message'=>'ML service not running. Start python model.py for capacity insights.']);
}
$data=json_decode($r,true);
jsonOut($data??['success'=>false,'error'=>'Invalid ML response']);
