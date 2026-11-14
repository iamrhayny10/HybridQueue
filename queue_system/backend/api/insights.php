<?php
error_reporting(0);
@ini_set("display_errors","0");
// insights.php — Data-driven analytics insights
// Works without Claude API key using smart rule-based analysis
require_once __DIR__.'/../config/db.php';
sendHeaders();

// Accept both GET and POST for flexibility
$body=[];
if($_SERVER['REQUEST_METHOD']==='POST'){
  $body=json_decode(file_get_contents('php://input'),true)??[];
}
$date=$body['date']??$_GET['date']??date('Y-m-d');
$db=getDB();

// ── Collect analytics data ────────────────────────────────────
$tickets=[];
$svcStats=['Registrar'=>['total'=>0,'served'=>0,'skipped'=>0,'avg_wait'=>null],
           'Cashier'  =>['total'=>0,'served'=>0,'skipped'=>0,'avg_wait'=>null],
           'OSA'      =>['total'=>0,'served'=>0,'skipped'=>0,'avg_wait'=>null]];
$hourly=[];
$yTotal=0;
$windowsOpen=[];
$avgSvcTimes=['Registrar'=>null,'Cashier'=>null,'OSA'=>null];
$peakHour=null;

try{
  $q=$db->prepare('SELECT qt.*,u.full_name,u.username AS student_id,sw.window_name
    FROM queue_tickets qt
    LEFT JOIN users u ON u.user_id=qt.user_id
    LEFT JOIN service_windows sw ON sw.window_id=qt.window_id
    WHERE DATE(qt.issued_at)=? ORDER BY qt.issued_at ASC');
  $q->execute([$date]);
  $tickets=$q->fetchAll(PDO::FETCH_ASSOC);

  foreach(['Registrar','Cashier','OSA'] as $svc){
    $t=array_values(array_filter($tickets,function($x)use($svc){return $x['service_type']===$svc;}));
    $served=array_values(array_filter($t,function($x){return $x['status']==='Served';}));
    $skipped=array_values(array_filter($t,function($x){return $x['status']==='Skipped';}));
    $waits=[];
    foreach($served as $x){
      if($x['called_at']&&$x['issued_at']){
        $waits[]=round((strtotime($x['called_at'])-strtotime($x['issued_at']))/60,1);
      }
    }
    $avgSvcT=[];
    foreach($t as $x){
      if($x['called_at']&&$x['served_at']){
        $avgSvcT[]=round((strtotime($x['served_at'])-strtotime($x['called_at']))/60,1);
      }
    }
    $svcStats[$svc]=[
      'total'=>count($t),
      'served'=>count($served),
      'skipped'=>count($skipped),
      'avg_wait'=>$waits?round(array_sum($waits)/count($waits),1):null,
    ];
    $avgSvcTimes[$svc]=$avgSvcT?round(array_sum($avgSvcT)/count($avgSvcT),1):null;
  }

  foreach($tickets as $t){
    $h=(int)date('G',strtotime($t['issued_at']));
    $hourly[$h]=($hourly[$h]??0)+1;
  }
  if($hourly){arsort($hourly);$peakHour=array_key_first($hourly);}

  $yQ=$db->prepare('SELECT COUNT(*) FROM queue_tickets WHERE DATE(issued_at)=?');
  $yQ->execute([date('Y-m-d',strtotime($date.' -1 day'))]);
  $yTotal=(int)$yQ->fetchColumn();

  $wQ=$db->prepare('SELECT service_type,COUNT(*) AS cnt FROM service_windows WHERE is_open=1 GROUP BY service_type');
  $wQ->execute();
  foreach($wQ->fetchAll(PDO::FETCH_ASSOC) as $r)$windowsOpen[$r['service_type']]=(int)$r['cnt'];

}catch(Exception $e){
  jsonOut(['success'=>false,'error'=>'DB error: '.$e->getMessage()]);
}

$total=count($tickets);
$served=count(array_filter($tickets,function($x){return $x['status']==='Served';}));
$skipped=count(array_filter($tickets,function($x){return $x['status']==='Skipped';}));
$pct=$total?round($served/$total*100):0;

// ── Build rule-based insights from real data ──────────────────
$insights=[];

if($total===0){
  jsonOut(['success'=>true,'insights'=>[
    ['icon'=>'📊','color'=>'#888','bg'=>'#F9F9F8','border'=>'#E5E5E0',
     'title'=>'No Data for '.$date,
     'body'=>'No tickets were recorded on this date.',
     'rec'=>'Try selecting a date when the system was active.']
  ],'fallback'=>true]);
}

// 1. Volume vs yesterday
$changeStr='';
if($yTotal>0){
  $changePct=round(($total-$yTotal)/$yTotal*100,1);
  $changeStr=' Volume '.($changePct>=0?'up':'down').' '.abs($changePct).'% vs yesterday ('.$yTotal.' tickets).';
}
$insights[]=['icon'=>'📊','color'=>'#1A56DB','bg'=>'#EFF6FF','border'=>'#BFDBFE',
  'title'=>'Queue Volume — '.$date,
  'body'=>$total.' tickets issued. '.$served.' served ('.$pct.'%). '.$skipped.' skipped.'.$changeStr,
  'rec'=>$pct<70?'Completion rate below 70%. Consider opening additional windows or extending service hours.':'Healthy completion rate. Current staffing appears adequate.'];

// 2. Peak hour
if($peakHour!==null){
  $cnt=$hourly[$peakHour];
  $label=$peakHour<12?$peakHour.':00 AM':($peakHour===12?'12:00 PM':($peakHour-12).':00 PM');
  $insights[]=['icon'=>'⏰','color'=>'#D97706','bg'=>'#FFFBEB','border'=>'#FDE68A',
    'title'=>'Peak Hour: '.$label,
    'body'=>$cnt.' ticket'.($cnt!==1?'s':'').' were issued at '.$label.' — the busiest hour of the day.',
    'rec'=>'Ensure maximum staff are on duty from '.$label.' to handle peak demand effectively.'];
}

// 3. Per-service insights
foreach($svcStats as $svc=>$s){
  if($s['total']===0)continue;
  $skipPct=$s['total']?round($s['skipped']/$s['total']*100):0;
  if($skipPct>20){
    $insights[]=['icon'=>'🔄','color'=>'#7C3AED','bg'=>'#F5F3FF','border'=>'#DDD6FE',
      'title'=>'High Skip Rate — '.$svc.' ('.$skipPct.'%)',
      'body'=>$s['skipped'].' of '.$s['total'].' '.$svc.' tickets were skipped today.',
      'rec'=>'Students may not be near the window when called. Consider increasing the grace period or adding an alert notification for '.$svc.'.'];
  }
  if($s['avg_wait']!==null&&$s['avg_wait']>20){
    $insights[]=['icon'=>'⚠️','color'=>'#DC2626','bg'=>'#FEF2F2','border'=>'#FECACA',
      'title'=>'Long Wait — '.$svc.' (avg '.$s['avg_wait'].' min)',
      'body'=>'Average waiting time for '.$svc.' is '.$s['avg_wait'].' minutes.',
      'rec'=>'Consider opening an additional '.$svc.' window to reduce student wait time.'];
  }
  $w=$windowsOpen[$svc]??0;
  if($w===0&&$s['total']>0){
    $insights[]=['icon'=>'⚠️','color'=>'#DC2626','bg'=>'#FEF2F2','border'=>'#FECACA',
      'title'=>'No Open Window — '.$svc,
      'body'=>$svc.' had '.$s['total'].' ticket'.($s['total']!==1?'s':'').' today but no windows are currently open.',
      'rec'=>'Open at least one '.$svc.' window to resume service.'];
  }
}

// 4. Overall skip rate
if($total>0&&$skipped/$total>0.15){
  $insights[]=['icon'=>'📉','color'=>'#059669','bg'=>'#F0FDF4','border'=>'#86EFAC',
    'title'=>'Skip Rate Alert: '.round($skipped/$total*100).'%',
    'body'=>$skipped.' of '.$total.' tickets were skipped today across all services.',
    'rec'=>'Review grace period settings and ensure students are notified via the mobile app when their turn is approaching.'];
}

jsonOut(['success'=>true,'insights'=>array_slice($insights,0,5),'fallback'=>true]);
