<?php
error_reporting(0);
@ini_set("display_errors","0");
// transactions.php — Cashier walk-in transactions
// For students buying uniforms, IDs, grade slips, COMs, etc.
require_once __DIR__.'/../config/db.php';
sendHeaders();
$db=getDB();$method=$_SERVER['REQUEST_METHOD'];
$body=json_decode(file_get_contents('php://input'),true)??[];

if($method==='GET'){
  $date=$_GET['date']??date('Y-m-d');
  $s=$db->prepare("SELECT * FROM cashier_transactions WHERE DATE(transaction_date)=? ORDER BY created_at DESC");
  $s->execute([$date]);
  jsonOut(['success'=>true,'transactions'=>$s->fetchAll()]);
}

if($method==='POST'){
  $name=trim($body['student_name']??'');
  $sid=trim($body['student_id']??'');
  $purpose=trim($body['purpose']??'');
  $amount=isset($body['amount'])&&$body['amount']!==''?(float)$body['amount']:null;
  $notes=trim($body['notes']??'');
  $uid=(int)($body['user_id']??1);
  $txdate=trim($body['transaction_date']??date('Y-m-d'));
  if(!$name||!$purpose)jsonError('Student name and purpose are required.');
  $db->prepare("INSERT INTO cashier_transactions(student_name,student_id,purpose,amount,notes,processed_by,transaction_date)VALUES(?,?,?,?,?,?,?)")
    ->execute([$name,$sid,$purpose,$amount,$notes,$uid,$txdate]);
  $id=(int)$db->lastInsertId();
  logAction($uid,'cashier_transaction',"Transaction for $name: $purpose".($amount?" (₱$amount)":''));
  $f=$db->prepare("SELECT * FROM cashier_transactions WHERE id=?");$f->execute([$id]);
  jsonOut(['success'=>true,'transaction'=>$f->fetch()],201);
}

if($method==='DELETE'){
  $id=(int)($body['id']??0);$uid=(int)($body['user_id']??1);
  if(!$id)jsonError('Transaction ID required.');
  $db->prepare("DELETE FROM cashier_transactions WHERE id=?")->execute([$id]);
  logAction($uid,'cashier_tx_delete',"Deleted cashier transaction #$id");
  jsonOut(['success'=>true,'message'=>'Transaction deleted.']);
}
jsonError('Method not allowed.',405);
