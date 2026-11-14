<?php
// Suppress PHP warnings/notices so they don't break JSON output
error_reporting(0);
@ini_set('display_errors', '0');
require_once __DIR__.'/../config/db.php';
require_once __DIR__.'/../config/pwd_schema.php';
sendHeaders();
$db = getDB();
ensurePwdColumns($db);
$method = $_SERVER['REQUEST_METHOD'];

function pfx($s){
    if($s==='Registrar')return'R';
    if($s==='Cashier')return'C';
    if($s==='OSA')return'O';
    return'T';
}
function nextNumPriority($db,$s){
    $q=$db->prepare("SELECT COUNT(*) FROM queue_tickets WHERE service_type=? AND is_priority=1 AND DATE(issued_at)=CURDATE()");
    $q->execute(array($s));
    return pfx($s).'P-'.str_pad((int)$q->fetchColumn()+1,3,'0',STR_PAD_LEFT);
}
function nextNum($db,$s){
    $q=$db->prepare("SELECT COUNT(*) FROM queue_tickets WHERE service_type=? AND DATE(issued_at)=CURDATE()");
    $q->execute(array($s));
    return pfx($s).'-'.str_pad((int)$q->fetchColumn()+1,3,'0',STR_PAD_LEFT);
}
function getBaseTime($db,$svc){
    $d=array('Registrar'=>10,'Cashier'=>5,'OSA'=>8);
    try{
        $q=$db->prepare("SELECT setting_value FROM system_settings WHERE setting_key=?");
        $q->execute(array('base_time_'.$svc));
        $v=$q->fetchColumn();
        if($v!==false&&$v!==null&&$v!=='')return(float)$v;
    }catch(Exception $e){}
    return isset($d[$svc])?(float)$d[$svc]:10.0;
}
function mlErt($f){
    $url=defined('ML_URL')?ML_URL:'http://localhost:5001/predict';
    $j=json_encode($f);
    $ctx=stream_context_create(array('http'=>array('method'=>'POST','timeout'=>1,'header'=>"Content-Type: application/json\r\nContent-Length:".strlen($j),'content'=>$j)));
    $r=@file_get_contents($url,false,$ctx);
    if($r){$d=json_decode($r,true);if(isset($d['predicted_ert_minutes']))return round((float)$d['predicted_ert_minutes'],1);}
    return null;
}

// GET
if($method==='GET'){
    try{
        // Auto-skip (respects skip_paused)
        $g=1;$mx=3;
        try{
            $db->prepare("UPDATE queue_tickets SET status='Skipped',skip_count=skip_count+1 WHERE status='Serving' AND called_at IS NOT NULL AND called_at<(NOW()-INTERVAL $g MINUTE) AND skip_count>=$mx AND (window_id IS NULL OR window_id NOT IN(SELECT window_id FROM service_windows WHERE skip_paused=1))")->execute();
            // Re-queue skipped ticket right after the currently next waiting ticket (not at end)
            // Get the issued_at of the NEXT waiting ticket for each service, then set skipped ticket's issued_at to just after it
            $skipRows=$db->prepare("SELECT ticket_id,service_type FROM queue_tickets WHERE status='Serving' AND called_at IS NOT NULL AND called_at<(NOW()-INTERVAL $g MINUTE) AND skip_count<$mx AND (window_id IS NULL OR window_id NOT IN(SELECT window_id FROM service_windows WHERE skip_paused=1))");
            $skipRows->execute();
            foreach($skipRows->fetchAll() as $skipT){
                // Get the issued_at of the next waiting ticket in this service
                $nxt=$db->prepare("SELECT issued_at FROM queue_tickets WHERE service_type=? AND status='Waiting' ORDER BY issued_at ASC LIMIT 1");
                $nxt->execute(array($skipT['service_type']));
                $nxtRow=$nxt->fetch();
                if($nxtRow){
                    // Place skipped ticket right after the next waiting ticket (+1 second)
                    $newTime=date('Y-m-d H:i:s',strtotime($nxtRow['issued_at'])+1);
                }else{
                    // No waiting tickets, place at current time
                    $newTime=date('Y-m-d H:i:s');
                }
                $db->prepare("UPDATE queue_tickets SET status='Waiting',called_at=NULL,window_id=NULL,skip_count=skip_count+1,issued_at=? WHERE ticket_id=?")->execute(array($newTime,$skipT['ticket_id']));
            }
        }catch(Exception $e){
            try{
                $db->prepare("UPDATE queue_tickets SET status='Skipped',skip_count=skip_count+1 WHERE status='Serving' AND called_at IS NOT NULL AND called_at<(NOW()-INTERVAL $g MINUTE) AND skip_count>=$mx")->execute();
                $db->prepare("UPDATE queue_tickets SET status='Waiting',called_at=NULL,window_id=NULL,skip_count=skip_count+1 WHERE status='Serving' AND called_at IS NOT NULL AND called_at<(NOW()-INTERVAL $g MINUTE) AND skip_count<$mx")->execute();
            }catch(Exception $e2){}
        }

        // ERT recalculation  — STATIC and RANK-BASED
        //   ERT = baseTime + position * baseTime / openWindows
        //   position 0 = next to be called.
        //   Order = PWD priority tickets first, then regular tickets (first come, first served),
        //   so when a PWD ticket jumps the line every regular ticket behind it moves one slot
        //   further and gets its OWN, higher ERT (no two waiting tickets share a value).
        //   The value does not count down with time and is never clamped; it changes only when
        //   the ticket's position changes. Counting UP after the overrun point is done on the
        //   phone (ticket_screen.dart), so the server value never oscillates the display.
        try{
            $btCache=array();$owCache=array();$posMap=array();
            $wq=$db->prepare("SELECT ticket_id,service_type,predicted_ert FROM queue_tickets WHERE status='Waiting' AND DATE(issued_at)=CURDATE() ORDER BY is_priority DESC, issued_at ASC LIMIT 500");
            $wq->execute();
            $updErt=$db->prepare('UPDATE queue_tickets SET predicted_ert=? WHERE ticket_id=?');
            foreach($wq->fetchAll() as $wt){
                $svc2=$wt['service_type'];
                if(!isset($posMap[$svc2]))$posMap[$svc2]=0;
                $pos=$posMap[$svc2]++; // 0 = next in line for this service
                if(!isset($btCache[$svc2]))$btCache[$svc2]=getBaseTime($db,$svc2);
                if(!isset($owCache[$svc2])){
                    $owq=$db->prepare("SELECT COUNT(*) FROM service_windows WHERE service_type=? AND is_open=1");$owq->execute(array($svc2));
                    $owCache[$svc2]=max(1,(int)$owq->fetchColumn());
                }
                $calc=round((float)$btCache[$svc2]+($pos*(float)$btCache[$svc2]/$owCache[$svc2]),1);
                if($wt['predicted_ert']===null||abs((float)$wt['predicted_ert']-$calc)>0.04){
                    $updErt->execute(array($calc,$wt['ticket_id']));
                }
            }
        }catch(Exception $e){}

        // Query tickets
        $status=isset($_GET['status'])?$_GET['status']:'';
        $svc=isset($_GET['service_type'])?$_GET['service_type']:'';
        $winId=isset($_GET['window_id'])?$_GET['window_id']:'';
        $date=isset($_GET['date'])?$_GET['date']:date('Y-m-d');
        $dateTo=isset($_GET['date_to'])?$_GET['date_to']:'';
        $role=isset($_GET['role'])?trim($_GET['role']):'';
        $uid=isset($_GET['user_id'])?(int)$_GET['user_id']:0;
        $filterUser=($uid>0&&$role!=='Admin'&&$role!=='Staff');

        if($winId&&!$svc){
            $ws=$db->prepare('SELECT service_type FROM service_windows WHERE window_id=?');
            $ws->execute(array((int)$winId));
            $row=$ws->fetch();
            if($row)$svc=$row['service_type'];
        }

        $sql='SELECT qt.*,u.full_name AS full_name,u.username AS student_id,sw.window_name,sw.skip_paused FROM queue_tickets qt LEFT JOIN users u ON u.user_id=qt.user_id LEFT JOIN service_windows sw ON sw.window_id=qt.window_id WHERE 1=1';
        $p=array();
        if($date&&$dateTo&&$dateTo>=$date){$sql.=' AND DATE(qt.issued_at) BETWEEN ? AND ?';$p[]=$date;$p[]=$dateTo;}
        elseif($date){$sql.=' AND DATE(qt.issued_at)=?';$p[]=$date;}
        if($status){$sql.=' AND qt.status=?';$p[]=$status;}
        if($svc){$sql.=' AND qt.service_type=?';$p[]=$svc;}
        if($winId){$sql.=' AND qt.window_id=?';$p[]=(int)$winId;}
        if($filterUser){$sql.=' AND qt.user_id=?';$p[]=$uid;}
        $sql.=($status==='Waiting')?' ORDER BY qt.is_priority DESC, qt.issued_at ASC':' ORDER BY qt.issued_at ASC';
        $s=$db->prepare($sql);$s->execute($p);
        jsonOut(array('success'=>true,'range'=>true,'tickets'=>$s->fetchAll()));
    }catch(Exception $e){
        jsonOut(array('success'=>false,'error'=>$e->getMessage(),'tickets'=>array()));
    }
}

// POST
if($method==='POST'){
    $body=json_decode(file_get_contents('php://input'),true);
    if(!$body)$body=array();
    $svc=trim(isset($body['service_type'])?$body['service_type']:'');
    $uid=(int)(isset($body['user_id'])?$body['user_id']:0);
    if(!$svc)jsonError('service_type is required.');
    if(!in_array($svc,array('Registrar','Cashier','OSA'),true))jsonError('Invalid service_type.');
    if(!$uid)jsonError('user_id is required.');

    // Check queue paused
    try{
        $pc=$db->prepare("SELECT COUNT(*) FROM service_windows WHERE service_type=? AND is_open=1 AND queue_paused=1");
        $pc->execute(array($svc));$pausedCount=(int)$pc->fetchColumn();
        $ac=$db->prepare("SELECT COUNT(*) FROM service_windows WHERE service_type=? AND is_open=1");
        $ac->execute(array($svc));$openCount=(int)$ac->fetchColumn();
        if($openCount>0&&$pausedCount>=$openCount)jsonError("The {$svc} queue is currently paused. Please wait for staff to resume.",503);
    }catch(Exception $e){}

    // Check window open
    $oc=$db->prepare("SELECT COUNT(*) FROM service_windows WHERE service_type=? AND is_open=1");
    $oc->execute(array($svc));
    if((int)$oc->fetchColumn()===0)jsonError("The {$svc} window is currently closed.",503);

    // Check active ticket
    $chk=$db->prepare("SELECT ticket_id FROM queue_tickets WHERE user_id=? AND status IN('Waiting','Serving') AND DATE(issued_at)=CURDATE() LIMIT 1");
    $chk->execute(array($uid));
    if($chk->fetch())jsonError('You already have an active ticket in the queue.',409);

    // Purpose / year-section must be read BEFORE the ML call (they were previously read after it)
    $ys=trim(isset($body['year_section'])?$body['year_section']:'');
    $pur=trim(isset($body['purpose'])?$body['purpose']:'');

    // PWD Priority Lane: the server decides — only a verified PWD student gets priority
    $priority=!empty($body['priority']);
    if($priority){
        $pq=$db->prepare('SELECT pwd_status FROM users WHERE user_id=?');$pq->execute(array($uid));
        if($pq->fetchColumn()!=='verified')jsonError('Priority Lane is available only to verified PWD students.',403);
    }

    // Issue ticket
    // Regular tickets queue behind everyone waiting; priority tickets queue behind other priority tickets only
    $ql=(int)$db->query("SELECT COUNT(*) FROM queue_tickets WHERE service_type='$svc' AND status='Waiting'".($priority?' AND is_priority=1':''))->fetchColumn();
    $ow=(int)$db->query("SELECT COUNT(*) FROM service_windows WHERE service_type='$svc' AND is_open=1")->fetchColumn();
    $bt=getBaseTime($db,$svc);

    // ERT for the new ticket uses the SAME static rank formula as the GET recalculation above,
    // so the number shown at issue is the number the student keeps seeing on the next refresh.
    //   $ql = tickets this one must wait behind:
    //         regular ticket  -> everyone waiting (PWD + regular)
    //         priority ticket -> only the other waiting PWD tickets (it goes ahead of regular ones)
    $ert=max(1.0,round((float)$bt+($ql*(float)$bt/max(1,$ow)),1));

    // Optional: let the ML service overwrite the number. OFF by default because ML values are not
    // rank-ordered and were the reason several tickets showed the same / wrong ERT.
    $USE_ML_ERT=false;
    if($USE_ML_ERT){
        $mlResult=mlErt(array(
            'queue_length'    =>$ql,
            'service_type'    =>$svc,
            'time_of_day'     =>(int)date('G'),
            'day_of_week'     =>(int)date('N')-1,
            'windows_open'    =>max(1,$ow),
            'base_time'       =>$bt,
            'purpose'         =>$pur,
            'elapsed_minutes' =>0,
        ));
        if($mlResult!==null)$ert=$mlResult;
    }

    $tn=$priority?nextNumPriority($db,$svc):nextNum($db,$svc);
    $db->prepare('INSERT INTO queue_tickets(user_id,ticket_number,service_type,source,year_section,purpose,predicted_ert,status,is_priority)VALUES(?,?,?,"mobile",?,?,?,"Waiting",?)')->execute(array($uid,$tn,$svc,$ys,$pur,$ert,$priority?1:0));
    $id=(int)$db->lastInsertId();
    logAction($uid,'ticket_issued',"Ticket $tn [$svc]".($priority?' PRIORITY(PWD)':'')." ERT:{$ert}min");
    $f=$db->prepare('SELECT * FROM queue_tickets WHERE ticket_id=?');$f->execute(array($id));
    jsonOut(array('success'=>true,'ticket'=>$f->fetch()),201);
}

// PUT
if($method==='PUT'){
    $body=json_decode(file_get_contents('php://input'),true);
    if(!$body)$body=array();
    $tid=(int)(isset($body['ticket_id'])?$body['ticket_id']:0);
    $st=trim(isset($body['status'])?$body['status']:'');
    $wid=isset($body['window_id'])?(int)$body['window_id']:null;
    $sid=(int)(isset($body['staff_id'])?$body['staff_id']:0);
    if(!$tid||!in_array($st,array('Serving','Served','Skipped'),true))jsonError('ticket_id and valid status required.');
    $g=$db->prepare('SELECT * FROM queue_tickets WHERE ticket_id=?');$g->execute(array($tid));$t=$g->fetch();
    if(!$t)jsonError('Ticket not found.',404);
    $now=date('Y-m-d H:i:s');

    if($st==='Serving'){
        $staffRole=trim(isset($body['staff_role'])?$body['staff_role']:'Admin');
        if($wid&&$sid&&$staffRole==='Staff'){
            $oc=$db->prepare('SELECT window_id FROM service_windows WHERE window_id=? AND assigned_staff_id=? LIMIT 1');
            $oc->execute(array($wid,$sid));
            if(!$oc->fetch())jsonError('Access denied. You can only call tickets from your assigned window.',403);
        }
        $db->prepare('UPDATE queue_tickets SET status="Serving",called_at=?,window_id=? WHERE ticket_id=?')->execute(array($now,$wid,$tid));
        logAction($sid?:1,'ticket_called',"Ticket {$t['ticket_number']} [{$t['service_type']}] called to window $wid");
    }

    if($st==='Served'){
        $db->prepare('UPDATE queue_tickets SET status="Served",served_at=? WHERE ticket_id=?')->execute(array($now,$tid));
        $iss=strtotime($t['issued_at']);
        $cal=$t['called_at']?strtotime($t['called_at']):time();
        $wtt=round(($cal-$iss)/60,2);$svt=round((time()-$cal)/60,2);
        try{
            $ql2=(int)$db->query("SELECT COUNT(*) FROM queue_tickets WHERE service_type='{$t['service_type']}'")->fetchColumn();
            $ow2=(int)$db->query("SELECT COUNT(*) FROM service_windows WHERE service_type='{$t['service_type']}' AND is_open=1")->fetchColumn();
            $db->prepare('INSERT INTO historical_data(ticket_id,actual_wait_time,actual_service_time,transaction_type,queue_length_at_issue,time_of_day,day_of_week,windows_open_count)VALUES(?,?,?,?,?,?,?,?)')->execute(array($tid,$wtt,$svt,$t['service_type'],$ql2,(int)date('G',$iss),(int)date('N',$iss)-1,$ow2));
        }catch(Exception $e){}
        logAction($sid?:1,'ticket_served',"Ticket {$t['ticket_number']} served. Wait:{$wtt}min");
    }

    if($st==='Skipped'){
        $mx=3;$nc=(int)(isset($t['skip_count'])?$t['skip_count']:0)+1;
        if($nc>=$mx){
            // 3rd attempt — permanently skipped, goes to LAST position in queue
            $lastRow=$db->prepare("SELECT issued_at FROM queue_tickets WHERE service_type=? AND status='Waiting' ORDER BY issued_at DESC LIMIT 1");
            $lastRow->execute(array($t['service_type']));
            $lastR=$lastRow->fetch();
            if($lastR){
                $lastTime=date('Y-m-d H:i:s',strtotime($lastR['issued_at'])+1);
            }else{
                $lastTime=date('Y-m-d H:i:s');
            }
            $db->prepare('UPDATE queue_tickets SET status="Waiting",called_at=NULL,window_id=NULL,skip_count=?,issued_at=? WHERE ticket_id=?')->execute(array($nc,$lastTime,$tid));
            logAction($sid?:1,'ticket_skipped',"Ticket {$t['ticket_number']} skipped 3 times — moved to last position.");
        }else{
            // Attempt 1 or 2 — goes right after the next waiting ticket
            $nxt=$db->prepare("SELECT issued_at FROM queue_tickets WHERE service_type=? AND status='Waiting' ORDER BY issued_at ASC LIMIT 1");
            $nxt->execute(array($t['service_type']));
            $nxtRow=$nxt->fetch();
            if($nxtRow){
                // Place right after the next waiting ticket (+1 second)
                $newTime=date('Y-m-d H:i:s',strtotime($nxtRow['issued_at'])+1);
            }else{
                $newTime=date('Y-m-d H:i:s');
            }
            $db->prepare('UPDATE queue_tickets SET status="Waiting",called_at=NULL,window_id=NULL,skip_count=?,issued_at=? WHERE ticket_id=?')->execute(array($nc,$newTime,$tid));
            logAction($sid?:1,'ticket_skipped',"Ticket {$t['ticket_number']} skipped attempt $nc/$mx — moved after next ticket.");
        }
    }
    jsonOut(array('success'=>true,'message'=>"Ticket updated to $st."));
}

jsonError('Method not allowed.',405);
