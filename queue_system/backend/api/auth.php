<?php
error_reporting(0);
@ini_set("display_errors","0");
require_once __DIR__.'/../config/db.php';
require_once __DIR__.'/../config/auth_guard.php';
sendHeaders();
$body=json_decode(file_get_contents('php://input'),true)??[];
$action=$body['action']??'';
if($action==='login'){
  $u=trim($body['username']??'');$p=$body['password']??'';
  if(!$u||!$p)jsonError('Username and password are required.');
  $db=getDB();$s=$db->prepare('SELECT * FROM users WHERE username=? AND is_active=1 LIMIT 1');$s->execute([$u]);$user=$s->fetch();
  if(!$user||!password_verify($p,$user['password_hash']))jsonError('Invalid credentials.',401);
  $token=makeAuthToken($user['user_id'],$user['role']);
  logAction($user['user_id'],'login','User logged in');
  $assignedWindow=null;
  if($user['role']==='Staff'){
    $wq=$db->prepare('SELECT window_id,window_name,service_type FROM service_windows WHERE assigned_staff_id=? LIMIT 1');
    $wq->execute([$user['user_id']]);
    $assignedWindow=$wq->fetch()?:null;
  }
  jsonOut(['success'=>true,'token'=>$token,'user'=>['user_id'=>$user['user_id'],'username'=>$user['username'],'full_name'=>$user['full_name'],'email'=>$user['email'],'role'=>$user['role'],'assigned_window'=>$assignedWindow]]);;
}
if($action==='register'){
  $fn=trim($body['full_name']??'');$sid=trim($body['student_id']??'');$em=trim($body['email']??'');$pw=$body['password']??'';
  if(!$fn||!$sid||!$em||!$pw)jsonError('All fields are required.');
  if(!filter_var($em,FILTER_VALIDATE_EMAIL))jsonError('Invalid email address.');
  if(strlen($pw)<8)jsonError('Password must be at least 8 characters.');
  if(!preg_match('/^\d{4}-\d{2}-\d{5,}$/',$sid))jsonError('Invalid Student ID format. Expected: YYYY-MM-NNNNN (e.g. 2017-05-07116).');
  $db=getDB();$c=$db->prepare('SELECT user_id FROM users WHERE username=? OR email=? LIMIT 1');$c->execute([$sid,$em]);
  if($c->fetch())jsonError('Student ID or email is already registered.',409);
  $hash=password_hash($pw,PASSWORD_BCRYPT);
  $db->prepare('INSERT INTO users(username,password_hash,full_name,email,role)VALUES(?,?,?,?,"Student")')->execute([$sid,$hash,$fn,$em]);
  $nid=(int)$db->lastInsertId();
  logAction($nid,'register',"Student registered ID:{$sid} Name:{$fn}");
  jsonOut(['success'=>true,'message'=>'Account created. Log in with your Student ID.'],201);
}
// ── Forgot password (Student accounts only) ─────────────────────
// Step 1 (verify_reset): confirm Student ID + registered email, return a short-lived one-time token.
// Step 2 (reset_password): validate the token and save the new password.
function resetThrottleFile($sid){return sys_get_temp_dir().'/grc_reset_'.md5(strtolower($sid)).'.json';}
function resetBlocked($sid){
  $f=resetThrottleFile($sid);if(!is_file($f))return false;
  $d=json_decode(@file_get_contents($f),true);if(!$d)return false;
  if(time()-($d['t']??0)>900){@unlink($f);return false;}
  return ($d['n']??0)>=5;
}
function resetFail($sid){
  $f=resetThrottleFile($sid);$d=is_file($f)?json_decode(@file_get_contents($f),true):null;
  if(!$d||time()-($d['t']??0)>900)$d=['n'=>0,'t'=>time()];
  $d['n']++;@file_put_contents($f,json_encode($d));
}
function resetSig($uid,$exp,$hash){return hash_hmac('sha256',$uid.'|'.$exp,$hash.'|grc-reset');}
if($action==='verify_reset'){
  $sid=trim($body['student_id']??'');$em=strtolower(trim($body['email']??''));
  if(!$sid||!$em)jsonError('Student ID and registered email are required.');
  if(resetBlocked($sid))jsonError('Too many attempts. Please try again in 15 minutes.',429);
  $db=getDB();
  $s=$db->prepare("SELECT user_id,password_hash FROM users WHERE username=? AND LOWER(email)=? AND role='Student' AND is_active=1 LIMIT 1");
  $s->execute([$sid,$em]);$u=$s->fetch();
  if(!$u){resetFail($sid);jsonError('Student ID and registered email do not match our records.',404);}
  @unlink(resetThrottleFile($sid));
  $exp=time()+600;
  jsonOut(['success'=>true,'reset_token'=>$u['user_id'].'.'.$exp.'.'.resetSig($u['user_id'],$exp,$u['password_hash']),'expires_in'=>600]);
}
if($action==='reset_password'){
  $sid=trim($body['student_id']??'');$tok=$body['reset_token']??'';$pw=$body['new_password']??'';
  if(!$sid||!$tok||!$pw)jsonError('All fields are required.');
  if(strlen($pw)<8)jsonError('Password must be at least 8 characters.');
  $parts=explode('.',$tok);
  if(count($parts)!==3)jsonError('Reset request is invalid or has expired. Please verify again.',400);
  $uid=(int)$parts[0];$exp=(int)$parts[1];$sig=$parts[2];
  $db=getDB();
  $s=$db->prepare("SELECT user_id,password_hash FROM users WHERE user_id=? AND username=? AND role='Student' AND is_active=1 LIMIT 1");
  $s->execute([$uid,$sid]);$u=$s->fetch();
  if(!$u||$exp<time()||!hash_equals(resetSig($u['user_id'],$exp,$u['password_hash']),$sig))
    jsonError('Reset request is invalid or has expired. Please verify again.',400);
  $db->prepare('UPDATE users SET password_hash=? WHERE user_id=?')->execute([password_hash($pw,PASSWORD_BCRYPT),$u['user_id']]);
  logAction($u['user_id'],'password_reset',"Student reset password via Forgot Password. ID:{$sid}");
  jsonOut(['success'=>true,'message'=>'Password reset successful. You can now log in.']);
}
jsonError('Invalid action.',404);
