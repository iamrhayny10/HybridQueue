<?php
error_reporting(0);
@ini_set("display_errors","0");
require_once __DIR__.'/../config/db.php';
sendHeaders();
$db=getDB();$method=$_SERVER['REQUEST_METHOD'];$body=json_decode(file_get_contents('php://input'),true)??[];
if($method==='GET'){$role=$_GET['role']??'';$sql='SELECT user_id,username,full_name,email,role,is_active,created_at FROM users WHERE 1=1';$p=[];if($role){$sql.=' AND role=?';$p[]=$role;}$sql.=' ORDER BY created_at DESC';$s=$db->prepare($sql);$s->execute($p);jsonOut(['success'=>true,'users'=>$s->fetchAll()]);}
if($method==='POST'){
  $un=trim($body['username']??'');$pw=$body['password']??'';$fn=trim($body['full_name']??'');$em=trim($body['email']??'');$role=$body['role']??'';$aid=(int)($body['admin_id']??1);
  if(!$un||!$pw||!$fn||!$em||!in_array($role,['Admin','Staff','Student'],true))jsonError('All fields required. Role must be Admin, Staff, or Student.');
  if(!filter_var($em,FILTER_VALIDATE_EMAIL))jsonError('Invalid email.');
  $c=$db->prepare('SELECT user_id FROM users WHERE username=? OR email=? LIMIT 1');$c->execute([$un,$em]);if($c->fetch())jsonError('Username or email already exists.',409);
  $db->prepare('INSERT INTO users(username,password_hash,full_name,email,role)VALUES(?,?,?,?,?)')->execute([$un,password_hash($pw,PASSWORD_BCRYPT),$fn,$em,$role]);
  $nid=(int)$db->lastInsertId();logAction($aid,'user_created',"Account '$un' ($role) created.");
  jsonOut(['success'=>true,'message'=>'User created.','user_id'=>$nid],201);
}
if($method==='PUT'){
  $uid=(int)($body['user_id']??0);$ia=isset($body['is_active'])?(int)(bool)$body['is_active']:null;$aid=(int)($body['admin_id']??1);
  if(!$uid)jsonError('user_id required.');
  if($ia!==null){$db->prepare('UPDATE users SET is_active=? WHERE user_id=?')->execute([$ia,$uid]);logAction($aid,'user_toggle',"User ID:$uid ".($ia?'activated':'deactivated').'.');}
  jsonOut(['success'=>true,'message'=>'User updated.']);
}
jsonError('Method not allowed.',405);
