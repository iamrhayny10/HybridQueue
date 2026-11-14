<?php
// Comparison Report — ERT vs Actual with call process and skip tracking
// Access: http://localhost/queue_system/frontend/admin/comparison_report.php
require_once __DIR__.'/../../backend/config/db.php';
$db = getDB();

$date = $_GET['date'] ?? date('Y-m-d');
$svc  = $_GET['service'] ?? '';

// Fetch tickets with student info and timing data
$sql = "
  SELECT
    qt.ticket_id,
    qt.ticket_number,
    qt.service_type,
    qt.purpose,
    u.full_name,
    u.username AS student_id,
    qt.issued_at,
    qt.called_at,
    qt.served_at,
    qt.predicted_ert,
    qt.status,
    qt.skip_count,
    sw.window_name,
    -- Actual wait time: issued → called
    CASE WHEN qt.called_at IS NOT NULL
      THEN ROUND(TIMESTAMPDIFF(SECOND, qt.issued_at, qt.called_at)/60, 1)
      ELSE NULL END AS actual_wait_min,
    -- Actual service time: called → served
    CASE WHEN qt.called_at IS NOT NULL AND qt.served_at IS NOT NULL
      THEN ROUND(TIMESTAMPDIFF(SECOND, qt.called_at, qt.served_at)/60, 1)
      ELSE NULL END AS actual_service_min,
    -- Call process time (same as actual_service_time)
    CASE WHEN qt.called_at IS NOT NULL AND qt.served_at IS NOT NULL
      THEN ROUND(TIMESTAMPDIFF(SECOND, qt.called_at, qt.served_at)/60, 1)
      ELSE NULL END AS call_process_min,
    -- Difference: actual wait vs predicted ERT
    CASE WHEN qt.called_at IS NOT NULL AND qt.predicted_ert IS NOT NULL
      THEN ROUND(TIMESTAMPDIFF(SECOND, qt.issued_at, qt.called_at)/60 - qt.predicted_ert, 1)
      ELSE NULL END AS ert_diff_min
  FROM queue_tickets qt
  LEFT JOIN users u ON u.user_id = qt.user_id
  LEFT JOIN service_windows sw ON sw.window_id = qt.window_id
  WHERE DATE(qt.issued_at) = ?
  ".($svc ? "AND qt.service_type = ?" : "")."
  ORDER BY qt.issued_at ASC
";
$params = [$date];
if($svc) $params[] = $svc;
$stmt = $db->prepare($sql);
$stmt->execute($params);
$tickets = $stmt->fetchAll();
// Totals per service for the selected date (not affected by the service filter)
$tq = $db->prepare("SELECT service_type, COUNT(*) AS c FROM queue_tickets WHERE DATE(issued_at) = ? GROUP BY service_type");
$tq->execute([$date]);
$tot = ['Registrar'=>0,'Cashier'=>0,'OSA'=>0];
foreach($tq->fetchAll() as $r){ $tot[$r['service_type']] = (int)$r['c']; }
$totAll = array_sum($tot);
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Comparison Report — GRC Queue</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:system-ui,sans-serif;background:#f5f5f0;color:#111;padding:24px}
.header{background:#fff;border-radius:12px;padding:20px 24px;margin-bottom:20px;border:1px solid #e5e5e0;display:flex;justify-content:space-between;align-items:center}
.header h1{font-size:20px;font-weight:700;color:#8B0000}
.header p{font-size:13px;color:#666;margin-top:3px}
.filters{background:#fff;border-radius:12px;padding:16px 20px;margin-bottom:20px;border:1px solid #e5e5e0;display:flex;gap:12px;align-items:center;flex-wrap:wrap}
.filters label{font-size:13px;font-weight:600;color:#555}
.filters input,.filters select{padding:7px 10px;border:1px solid #ddd;border-radius:8px;font-size:13px}
.filters button{padding:7px 16px;background:#8B0000;color:#fff;border:none;border-radius:8px;font-size:13px;cursor:pointer;font-weight:600}
.filters button:hover{background:#6B0000}
.btn-print{padding:7px 16px;background:#1A56DB;color:#fff;border:none;border-radius:8px;font-size:13px;cursor:pointer;font-weight:600}
.table-wrap{background:#fff;border-radius:12px;padding:20px;border:1px solid #e5e5e0;overflow-x:auto}
table{width:100%;border-collapse:collapse;font-size:13px}
th{text-align:left;font-weight:700;color:#111;padding:10px 12px;border-bottom:2px solid #111;white-space:nowrap;background:#f9f9f8}
td{padding:9px 12px;border-bottom:1px solid #e5e5e0;color:#333;vertical-align:middle}
tr:last-child td{border-bottom:none}
tr:hover td{background:#fafaf8}
.ticket-num{font-family:monospace;font-weight:700;color:#8B0000;font-size:14px}
.status-done{background:#D1FAE5;color:#065F46;padding:3px 8px;border-radius:10px;font-size:11px;font-weight:600}
.status-skip{background:#FEE2E2;color:#991B1B;padding:3px 8px;border-radius:10px;font-size:11px;font-weight:600}
.status-wait{background:#FEF3C7;color:#92400E;padding:3px 8px;border-radius:10px;font-size:11px;font-weight:600}
.status-srv{background:#DBEAFE;color:#1E40AF;padding:3px 8px;border-radius:10px;font-size:11px;font-weight:600}
.diff-pos{color:#DC2626;font-weight:600}
.diff-neg{color:#059669;font-weight:600}
.diff-zero{color:#6B7280}
.summary{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:12px;margin-bottom:20px}
.sum-card{background:#fff;border-radius:10px;padding:14px 16px;border:1px solid #e5e5e0}
.sum-lbl{font-size:11px;color:#888;margin-bottom:4px}
.sum-val{font-size:22px;font-weight:700;color:#111}
.sum-sub{font-size:11px;color:#888;margin-top:2px}
.empty{text-align:center;padding:40px;color:#aaa;font-size:14px}
@media print{
  body{background:#fff;padding:12px}
  .filters,.btn-print,#colbar{display:none}
  .header{border:none;padding:8px 0;margin-bottom:12px}
  .table-wrap{border:none;padding:0}
}
.sig-section{margin-top:70px;padding-top:10px}
.sig-single{border-top:1px solid #000;width:260px;padding-top:8px;font-size:14px;font-weight:700}
.sig-sub{font-size:12px;color:#555;margin-top:3px}
.sig-all{display:flex;justify-content:space-between;margin-top:70px}
.sig-box{text-align:center;min-width:180px}
.sig-box-line{border-top:1px solid #000;padding-top:8px;font-size:13px;font-weight:700}
</style>
</head>
<body>

<div class="header">
  <div>
    <h1>📊 Queue Comparison Report</h1>
    <p>Global Reciprocal Colleges — ERT vs Actual Wait Time Analysis</p>
    <p>454 GRC Bldg. Rizal Avenue Ext. Cor. 9th Avenue Grace Park, Caloocan City</p>
  </div>
  <button class="btn-print" onclick="window.print()">🖨️ Print / Export PDF</button>
</div>

<form method="GET" class="filters">
  <div>
    <label>Date</label><br>
    <input type="date" name="date" value="<?= htmlspecialchars($date) ?>">
  </div>
  <div>
    <label>Service</label><br>
    <select name="service">
      <option value="">All Services</option>
      <option value="Registrar" <?= $svc==='Registrar'?'selected':'' ?>>Registrar</option>
      <option value="Cashier"   <?= $svc==='Cashier'  ?'selected':'' ?>>Cashier</option>
      <option value="OSA"       <?= $svc==='OSA'      ?'selected':'' ?>>OSA</option>
    </select>
  </div>
  <div style="align-self:flex-end">
    <button type="submit">Generate</button>
  </div>
</form>

<?php if(count($tickets)): ?>
<?php
  $total    = count($tickets);
  $served   = count(array_filter($tickets, fn($t)=>$t['status']==='Served'));
  $skipped  = count(array_filter($tickets, fn($t)=>$t['status']==='Skipped'));
  $waiting  = count(array_filter($tickets, fn($t)=>$t['status']==='Waiting'));
  $diffs    = array_filter(array_column($tickets,'ert_diff_min'), fn($d)=>$d!==null);
  $avgDiff  = count($diffs)>0 ? round(array_sum($diffs)/count($diffs),1) : null;
  $avgWait  = array_filter(array_column($tickets,'actual_wait_min'), fn($d)=>$d!==null);
  $avgWaitV = count($avgWait)>0 ? round(array_sum($avgWait)/count($avgWait),1) : null;
  $avgSvc   = array_filter(array_column($tickets,'call_process_min'), fn($d)=>$d!==null);
  $avgSvcV  = count($avgSvc)>0 ? round(array_sum($avgSvc)/count($avgSvc),1) : null;
?>
<div class="summary">
  <div class="sum-card"><div class="sum-lbl">Total Transactions (All Services)</div><div class="sum-val"><?= $totAll ?></div></div>
  <div class="sum-card"><div class="sum-lbl">Registrar</div><div class="sum-val" style="color:#1A56DB"><?= $tot['Registrar'] ?></div></div>
  <div class="sum-card"><div class="sum-lbl">Cashier</div><div class="sum-val" style="color:#059669"><?= $tot['Cashier'] ?></div></div>
  <div class="sum-card"><div class="sum-lbl">OSA</div><div class="sum-val" style="color:#7C3AED"><?= $tot['OSA'] ?></div></div>
  <div class="sum-card"><div class="sum-lbl">Total Tickets</div><div class="sum-val"><?= $total ?></div></div>
  <div class="sum-card"><div class="sum-lbl">Served</div><div class="sum-val" style="color:#059669"><?= $served ?></div><div class="sum-sub"><?= $total>0?round($served/$total*100).'%':'-' ?> completion</div></div>
  <div class="sum-card"><div class="sum-lbl">Skipped</div><div class="sum-val" style="color:#DC2626"><?= $skipped ?></div></div>
  <div class="sum-card"><div class="sum-lbl">Avg Actual Wait</div><div class="sum-val"><?= $avgWaitV!==null?$avgWaitV.' min':'—' ?></div></div>
  <div class="sum-card"><div class="sum-lbl">Avg Call Process</div><div class="sum-val"><?= $avgSvcV!==null?$avgSvcV.' min':'—' ?></div></div>
  <div class="sum-card"><div class="sum-lbl">Avg ERT Diff</div><div class="sum-val <?= $avgDiff!==null?($avgDiff>0?'diff-pos':($avgDiff<0?'diff-neg':'diff-zero')):'diff-zero' ?>"><?= $avgDiff!==null?($avgDiff>0?'+':'').$avgDiff.' min':'—' ?></div><div class="sum-sub">+ = actual longer than predicted</div></div>
</div>

<div class="filters" id="colbar" style="flex-direction:column;align-items:flex-start;gap:8px">
  <div style="display:flex;gap:8px;flex-wrap:wrap;align-items:center;width:100%">
    <label>Columns:</label>
    <button type="button" onclick="preset('min')">Minimal</button>
    <button type="button" onclick="preset('full')">Full report</button>
    <label style="margin-left:auto">Print layout:</label>
    <select id="orient" onchange="applyCols()">
      <option value="auto">Auto</option><option value="portrait">Portrait</option><option value="landscape">Landscape</option>
    </select>
    <span id="orient-lbl" style="font-size:12px;color:#888"></span>
  </div>
  <div id="chips" style="display:flex;gap:6px;flex-wrap:wrap"></div>
</div>

<div class="table-wrap">
  <table id="rtable">
    <thead>
      <tr>
        <th>Date</th>
        <th>Service</th>
        <th>Purpose</th>
        <th>Name</th>
        <th>Student ID</th>
        <th>Status</th>
        <th>#</th>
        <th>Ticket</th>
        <th>Time Issued</th>
        <th>ERT / Estimated Time</th>
        <th>Actual Wait</th>
        <th>Difference</th>
        <th>Call Process</th>
        <th>Time Ended</th>
        <th>Skip Count</th>
        <th>Window</th>
      </tr>
    </thead>
    <tbody>
    <?php foreach($tickets as $i=>$t): ?>
      <?php
        $diff = $t['ert_diff_min'];
        $diffClass = $diff===null?'diff-zero':($diff>0?'diff-pos':($diff<0?'diff-neg':'diff-zero'));
        $diffStr = $diff===null?'—':($diff>0?'+'.$diff.' min':$diff.' min');
        $statusClass = match($t['status']){
          'Served'=>'status-done','Skipped'=>'status-skip',
          'Waiting'=>'status-wait','Serving'=>'status-srv',default=>''
        };
      ?>
      <tr>
        <td><?= $t['issued_at']?htmlspecialchars(substr($t['issued_at'],0,10)):'—' ?></td>
        <td><?= htmlspecialchars($t['service_type']) ?></td>
        <td style="font-size:12px"><?= htmlspecialchars($t['purpose']??'—') ?></td>
        <td><strong><?= htmlspecialchars($t['full_name']??'—') ?></strong></td>
        <td style="font-family:monospace;font-size:11px;color:#555"><?= htmlspecialchars($t['student_id']??'—') ?></td>
        <td><span class="<?= $statusClass ?>"><?= $t['status'] ?></span></td>
        <td style="color:#888"><?= $i+1 ?></td>
        <td class="ticket-num"><?= htmlspecialchars($t['ticket_number']) ?></td>
        <td><?= $t['issued_at']?htmlspecialchars(substr($t['issued_at'],11,8)):'—' ?></td>
        <td><?= $t['predicted_ert']!==null?$t['predicted_ert'].' min':'—' ?></td>
        <td><?= $t['actual_wait_min']!==null?$t['actual_wait_min'].' min':'—' ?></td>
        <td class="<?= $diffClass ?>"><?= $diffStr ?></td>
        <td><?= $t['call_process_min']!==null?$t['call_process_min'].' min':'—' ?></td>
        <td><?= $t['served_at']?htmlspecialchars(substr($t['served_at'],11,8)):'—' ?></td>
        <td><?= $t['skip_count']>0?'<span style="color:#F59E0B;font-weight:600">'.$t['skip_count'].'×</span>':'—' ?></td>
        <td style="font-size:11px;color:#555"><?= htmlspecialchars($t['window_name']??'—') ?></td>
      </tr>
    <?php endforeach; ?>
    </tbody>
  </table>
</div>
<?php else: ?>
<div class="table-wrap"><div class="empty">No tickets found for <?= htmlspecialchars($date) ?><?= $svc?' ('.$svc.')':'' ?>.<br>Select a date and click Generate.</div></div>
<?php endif; ?>

<?php
// Service-specific signature section
$sigMap=['Registrar'=>'Head Registrar','Cashier'=>'Head Cashier','OSA'=>'Head OSA'];
if($svc && isset($sigMap[$svc])):?>
<div class="sig-section">
  <div class="sig-single"><?= $sigMap[$svc] ?></div>
  <div class="sig-sub">Signature over Printed Name</div>
</div>
<?php elseif(count($tickets)>0): ?>
<div class="sig-all">
  <?php foreach($sigMap as $role): ?>
  <div class="sig-box">
    <div class="sig-box-line"><?= $role ?></div>
    <div class="sig-sub">Signature over Printed Name</div>
  </div>
  <?php endforeach; ?>
</div>
<?php endif; ?>

<style id="pagestyle">@page{size:A4 landscape;margin:12mm}</style>
<script>
(function(){
  var tbl=document.getElementById('rtable'); if(!tbl) return;
  var heads=[].slice.call(tbl.querySelectorAll('thead th'));
  var names=heads.map(function(h){return h.textContent.trim();});
  var MIN=['Ticket','Time Issued','ERT / Estimated Time','Actual Wait','Time Ended'];
  var sel=names.slice();
  function applyCols(){
    var rows=tbl.querySelectorAll('tr');
    rows.forEach(function(r){
      [].slice.call(r.children).forEach(function(c,i){c.style.display=sel.indexOf(names[i])>-1?'':'none';});
    });
    var chips=document.getElementById('chips');
    chips.innerHTML=names.map(function(n){
      var on=sel.indexOf(n)>-1;
      return '<label style="display:flex;align-items:center;gap:5px;font-size:12px;padding:4px 10px;border:1px solid #E5E5E0;border-radius:16px;cursor:pointer;background:'+(on?'#EEF2FF':'#fff')+'"><input type="checkbox" '+(on?'checked ':'')+'data-n="'+n.replace(/"/g,'&quot;')+'"> '+n+'</label>';
    }).join('');
    [].slice.call(chips.querySelectorAll('input')).forEach(function(cb){
      cb.addEventListener('change',function(){
        var n=cb.getAttribute('data-n');
        if(cb.checked&&sel.indexOf(n)<0)sel.push(n);
        if(!cb.checked)sel=sel.filter(function(x){return x!==n;});
        if(!sel.length)sel=[n];
        sel=names.filter(function(x){return sel.indexOf(x)>-1;});
        applyCols();
      });
    });
    var o=document.getElementById('orient').value;
    if(o==='auto')o=sel.length>7?'landscape':'portrait';
    document.getElementById('pagestyle').textContent='@page{size:A4 '+o+';margin:12mm}';
    document.getElementById('orient-lbl').textContent='→ '+(o==='landscape'?'Landscape':'Portrait')+' ('+sel.length+' columns)';
  }
  window.applyCols=applyCols;
  window.preset=function(n){sel=(n==='min')?names.filter(function(x){return MIN.indexOf(x)>-1;}):names.slice();applyCols();};
  applyCols();
})();
</script>
</body>
</html>
