<?php
error_reporting(0);
@ini_set("display_errors","0");
require_once __DIR__.'/../config/db.php';
sendHeaders();
$db=getDB();$method=$_SERVER['REQUEST_METHOD'];$action=$_GET['action']??'logs';
if($method==='GET'&&$action==='logs'){
  $type=$_GET['type']??'';
  $filterUid=$_GET['filter_user_id']??''; // use dedicated param, not user_id (which is the requester)
  $date=$_GET['date']??date('Y-m-d');
  $sql='SELECT al.*,u.username,u.full_name,u.role AS user_role FROM activity_logs al JOIN users u ON u.user_id=al.user_id WHERE DATE(al.logged_at)=?';$p=[$date];
  if($type){$sql.=' AND al.action_type=?';$p[]=$type;}
  if($filterUid){$sql.=' AND al.user_id=?';$p[]=(int)$filterUid;}
  $sql.=' ORDER BY al.logged_at DESC LIMIT 300';$s=$db->prepare($sql);$s->execute($p);jsonOut(['success'=>true,'logs'=>$s->fetchAll()]);
}
if($method==='GET'&&$action==='analytics'){
  $date=$_GET['date']??date('Y-m-d');$TYPES=['Registrar','Cashier','OSA'];
  $total=(int)$db->query("SELECT COUNT(*) FROM queue_tickets WHERE DATE(issued_at)='$date'")->fetchColumn();
  $served=(int)$db->query("SELECT COUNT(*) FROM queue_tickets WHERE DATE(issued_at)='$date' AND status='Served'")->fetchColumn();
  $waiting=(int)$db->query("SELECT COUNT(*) FROM queue_tickets WHERE status='Waiting'")->fetchColumn();
  $skip=(int)$db->query("SELECT COUNT(*) FROM queue_tickets WHERE DATE(issued_at)='$date' AND status='Skipped'")->fetchColumn();
  $by=[];foreach($TYPES as $s){$t=(int)$db->query("SELECT COUNT(*) FROM queue_tickets WHERE DATE(issued_at)='$date' AND service_type='$s'")->fetchColumn();$sv=(int)$db->query("SELECT COUNT(*) FROM queue_tickets WHERE DATE(issued_at)='$date' AND service_type='$s' AND status='Served'")->fetchColumn();$by[]=['service_type'=>$s,'total'=>$t,'served'=>$sv];}
  jsonOut(['success'=>true,'date'=>$date,'total'=>$total,'served'=>$served,'waiting'=>$waiting,'skipped'=>$skip,'completion_pct'=>$total?round($served/$total*100,1):0,'by_type'=>$by]);
}
jsonError('Method not allowed.',405);
