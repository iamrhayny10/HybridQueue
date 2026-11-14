<?php
error_reporting(0);
@ini_set("display_errors","0");
// settings.php — Control Panel: Base Time per service
// Base Time = the expected service duration for one transaction.
// The ML model uses Base Time as its starting point (hybrid approach).
// When no historical data exists (cold start), Base Time is used directly.
// As data accumulates, ML refines predictions using Base Time + real patterns.
require_once __DIR__.'/../config/db.php';
sendHeaders();
$db=getDB();$method=$_SERVER['REQUEST_METHOD'];
$body=json_decode(file_get_contents('php://input'),true)??[];

if($method==='GET'){
  try{
    $rows=$db->query("SELECT setting_key,setting_value,updated_by,updated_at FROM system_settings WHERE setting_key LIKE 'base_time_%'")->fetchAll();
    $out=[];
    foreach($rows as $r){
      $svc=str_replace('base_time_','',$r['setting_key']);
      $out[$svc]=['minutes'=>$r['setting_value']!==null?(float)$r['setting_value']:null,'updated_at'=>$r['updated_at']];
    }
    // Defaults if not set
    $defaults=['Registrar'=>10,'Cashier'=>5,'OSA'=>8];
    foreach(['Registrar','Cashier','OSA'] as $s){
      if(!isset($out[$s]))$out[$s]=['minutes'=>$defaults[$s],'updated_at'=>null];
    }
    jsonOut(['success'=>true,'base_times'=>$out]);
  }catch(Exception $e){
    jsonOut(['success'=>true,'base_times'=>['Registrar'=>['minutes'=>10,'updated_at'=>null],'Cashier'=>['minutes'=>5,'updated_at'=>null],'OSA'=>['minutes'=>8,'updated_at'=>null]]]);
  }
}

if($method==='PUT'){
  $svc=trim($body['service_type']??'');
  $val=isset($body['base_time_minutes'])&&$body['base_time_minutes']!==''?(float)$body['base_time_minutes']:null;
  $uid=(int)($body['user_id']??1);
  if(!in_array($svc,['Registrar','Cashier','OSA'],true))jsonError('Invalid service type. Must be Registrar, Cashier, or OSA.');
  if($val===null||$val<=0)jsonError('Base time must be a positive number of minutes.');
  $key='base_time_'.$svc;
  try{
    $exists=$db->prepare("SELECT COUNT(*) FROM system_settings WHERE setting_key=?");
    $exists->execute([$key]);
    if($exists->fetchColumn()>0){
      $db->prepare("UPDATE system_settings SET setting_value=?,updated_by=?,updated_at=NOW() WHERE setting_key=?")->execute([$val,$uid,$key]);
    }else{
      $db->prepare("INSERT INTO system_settings(setting_key,setting_value,updated_by)VALUES(?,?,?)")->execute([$key,$val,$uid]);
    }
    logAction($uid,'base_time_update',"Base time for $svc set to {$val} min.");
    jsonOut(['success'=>true,'message'=>"Base time for $svc updated to {$val} minutes."]);
  }catch(Exception $e){
    jsonError('Could not save. Make sure system_settings table exists. Run migration SQL.');
  }
}
jsonError('Method not allowed.',405);
