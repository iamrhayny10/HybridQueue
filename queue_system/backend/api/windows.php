<?php
error_reporting(0);
@ini_set("display_errors","0");
require_once __DIR__.'/../config/db.php';
sendHeaders();
$db=getDB();$method=$_SERVER['REQUEST_METHOD'];$body=json_decode(file_get_contents('php://input'),true)??[];$TYPES=['Registrar','Cashier','OSA'];
if($method==='GET'){
  // Staff can only see their assigned window; Admin sees all
  $requesterId=(int)($_GET['user_id']??0);
  $requesterRole=trim($_GET['role']??'');
  if($requesterId&&$requesterRole==='Staff'){
    // Return only the window(s) assigned to this staff member
    $s=$db->prepare('SELECT sw.*,u.full_name AS staff_name FROM service_windows sw LEFT JOIN users u ON u.user_id=sw.assigned_staff_id WHERE sw.assigned_staff_id=? ORDER BY sw.service_type,sw.window_id ASC');
    $s->execute([$requesterId]);
  }else{
    $s=$db->query('SELECT sw.*,u.full_name AS staff_name FROM service_windows sw LEFT JOIN users u ON u.user_id=sw.assigned_staff_id ORDER BY sw.service_type,sw.window_id ASC');
  }
  jsonOut(['success'=>true,'windows'=>$s->fetchAll()]);
}
if($method==='POST'){
  $name=trim($body['window_name']??'');$svc=trim($body['service_type']??'');$staffId=isset($body['assigned_staff_id'])?(int)$body['assigned_staff_id']:null;$adminId=(int)($body['admin_id']??1);
  if(!$name||!$svc)jsonError('window_name and service_type required.');
  if(!in_array($svc,$TYPES,true))jsonError('service_type must be Registrar, Cashier, or OSA.');
  $db->prepare('INSERT INTO service_windows(window_name,service_type,assigned_staff_id,is_open,mod_by)VALUES(?,?,?,0,?)')->execute([$name,$svc,$staffId,$adminId]);
  logAction($adminId,'window_created',"Window '$name' [$svc] created.");
  jsonOut(['success'=>true,'message'=>'Window created.'],201);
}
if($method==='PUT'){
  $wid=(int)($body['window_id']??0);$isOpen=isset($body['is_open'])?(int)(bool)$body['is_open']:null;$adminId=(int)($body['admin_id']??1);$skipPaused=isset($body['skip_paused'])?(int)(bool)$body['skip_paused']:null;$queuePaused=isset($body['queue_paused'])?(int)(bool)$body['queue_paused']:null;
  $requesterRole=trim($body['requester_role']??'Admin');
  if(!$wid)jsonError('window_id required.');
  // Staff can only modify their own assigned window
  if($requesterRole==='Staff'){
    $ownCheck=$db->prepare('SELECT window_id FROM service_windows WHERE window_id=? AND assigned_staff_id=? LIMIT 1');
    $ownCheck->execute([$wid,$adminId]);
    if(!$ownCheck->fetch())jsonError('Access denied. You can only manage your assigned window.',403);
  }
  if($isOpen!==null){$db->prepare('UPDATE service_windows SET is_open=?,mod_by=? WHERE window_id=?')->execute([$isOpen,$adminId,$wid]);$wn=$db->prepare('SELECT window_name FROM service_windows WHERE window_id=?');$wn->execute([$wid]);$n=$wn->fetchColumn();logAction($adminId,'window_toggle',"Window '$n' ".($isOpen?'opened':'closed').'.');}
  if($skipPaused!==null){$db->prepare('UPDATE service_windows SET skip_paused=? WHERE window_id=?')->execute([$skipPaused,$wid]);$wn=$db->prepare('SELECT window_name FROM service_windows WHERE window_id=?');$wn->execute([$wid]);$n=$wn->fetchColumn();logAction($adminId,'window_pause',"Auto-skip ".($skipPaused?'PAUSED':'RESUMED')." for window '$n'.");}
  if($queuePaused!==null){
    // Queue pause applies to ALL windows of this service type
    $wn=$db->prepare('SELECT window_name,service_type FROM service_windows WHERE window_id=?');$wn->execute([$wid]);$win=$wn->fetch();
    if($win){
      $db->prepare('UPDATE service_windows SET queue_paused=? WHERE service_type=?')->execute([$queuePaused,$win['service_type']]);
      logAction($adminId,'queue_pause',"Queue ".($queuePaused?'PAUSED':'RESUMED')." for {$win['service_type']} service.");
    }
  }
  jsonOut(['success'=>true,'message'=>'Window updated.']);
}
if($method==='DELETE'){
  $wid=(int)($body['window_id']??0);$adminId=(int)($body['admin_id']??1);if(!$wid)jsonError('window_id required.');
  $db->prepare('DELETE FROM service_windows WHERE window_id=?')->execute([$wid]);
  logAction($adminId,'window_deleted',"Window ID:$wid deleted.");
  jsonOut(['success'=>true,'message'=>'Window deleted.']);
}
jsonError('Method not allowed.',405);
