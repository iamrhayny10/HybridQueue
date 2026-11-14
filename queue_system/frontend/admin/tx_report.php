<?php
require_once __DIR__.'/../../backend/config/db.php';
$db=getDB();
$date=$_GET['date']??date('Y-m-d');
$stmt=$db->prepare("SELECT ct.*,u.full_name AS processed_by_name FROM cashier_transactions ct LEFT JOIN users u ON u.user_id=ct.processed_by WHERE DATE(ct.transaction_date)=? ORDER BY ct.created_at ASC");
$stmt->execute([$date]);
$txs=$stmt->fetchAll();
$total=array_sum(array_map(fn($t)=>floatval($t['amount']??0),$txs));
?><!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Cashier Transaction Report — <?=htmlspecialchars($date)?></title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Times New Roman',serif;background:#fff;color:#000;padding:28px 36px;font-size:13px}
.school-header{text-align:center;margin-bottom:6px}
.school-name{font-size:16px;font-weight:700;text-transform:uppercase;letter-spacing:.05em}
.school-sub{font-size:12px;color:#333;margin-top:2px}
.report-title{text-align:center;margin:14px 0 4px;font-size:15px;font-weight:700;text-transform:uppercase;border-top:2px solid #000;border-bottom:1px solid #000;padding:5px 0}
.report-date{text-align:center;font-size:12px;margin-bottom:14px}
table{width:100%;border-collapse:collapse;margin-bottom:16px;font-size:12px}
th{background:#f0f0f0;border:1px solid #333;padding:6px 8px;text-align:left;font-weight:700}
td{border:1px solid #333;padding:5px 8px;vertical-align:top}
.total-row td{font-weight:700;background:#f9f9f8}
.summary{display:flex;gap:24px;margin-bottom:14px}
.sum-box{border:1px solid #333;padding:8px 14px;min-width:130px}
.sum-lbl{font-size:10px;color:#555;margin-bottom:2px}
.sum-val{font-size:16px;font-weight:700}
.sig-section{margin-top:40px;display:flex;justify-content:space-between;gap:40px}
.sig-box{flex:1;text-align:center}
.sig-line{border-top:1px solid #000;margin-top:36px;padding-top:5px;font-size:12px;font-weight:600}
.sig-role{font-size:11px;color:#555}
.no-print-btn{margin-bottom:16px}
@media print{.no-print-btn{display:none}body{padding:14px 18px}}
</style>
</head>
<body>
<div class="no-print-btn">
  <button onclick="window.print()" style="padding:8px 20px;background:#8B0000;color:#fff;border:none;border-radius:6px;font-size:13px;cursor:pointer;font-weight:600">🖨️ Print / Save as PDF</button>
  <button onclick="window.close()" style="padding:8px 14px;border:1px solid #ccc;border-radius:6px;font-size:13px;cursor:pointer;margin-left:8px">Close</button>
</div>

<div class="school-header">
  <div class="school-name">Global Reciprocal Colleges</div>
  <div class="school-sub">454 GRC Bldg., Rizal Ave. Ext. Cor. 9th Avenue Grace Park, Caloocan City</div>
  <div class="school-sub">Cashier Department</div>
</div>

<div class="report-title">Daily Cashier Transaction Report</div>
<div class="report-date">Date: <?=htmlspecialchars($date)?> &nbsp;|&nbsp; Generated: <?=date('F j, Y g:i A')?></div>

<div class="summary">
  <div class="sum-box"><div class="sum-lbl">Total Transactions</div><div class="sum-val"><?=count($txs)?></div></div>
  <div class="sum-box"><div class="sum-lbl">Total Amount Collected</div><div class="sum-val">₱<?=number_format($total,2)?></div></div>
</div>

<?php if(count($txs)): ?>
<table>
  <thead>
    <tr>
      <th>#</th>
      <th>Student Name</th>
      <th>Student ID</th>
      <th>Purpose of Transaction</th>
      <th>Amount (₱)</th>
      <th>Notes</th>
      <th>Processed By</th>
    </tr>
  </thead>
  <tbody>
    <?php foreach($txs as $i=>$t): ?>
    <tr>
      <td><?=$i+1?></td>
      <td><?=htmlspecialchars($t['student_name'])?></td>
      <td><?=htmlspecialchars($t['student_id']??'—')?></td>
      <td><?=htmlspecialchars($t['purpose'])?></td>
      <td style="text-align:right"><?=$t['amount']?number_format((float)$t['amount'],2):'—'?></td>
      <td><?=htmlspecialchars($t['notes']??'—')?></td>
      <td><?=htmlspecialchars($t['processed_by_name']??'—')?></td>
    </tr>
    <?php endforeach; ?>
    <tr class="total-row">
      <td colspan="4" style="text-align:right">TOTAL</td>
      <td style="text-align:right">₱<?=number_format($total,2)?></td>
      <td colspan="2"></td>
    </tr>
  </tbody>
</table>
<?php else: ?>
<p style="text-align:center;padding:24px;color:#888">No transactions recorded for <?=htmlspecialchars($date)?>.</p>
<?php endif; ?>

<div class="sig-section">
  <div class="sig-box">
    <div class="sig-line">________________________________</div>
    <div>Cashier Staff</div>
    <div class="sig-role">Signature over Printed Name</div>
  </div>
  <div class="sig-box">
    <div class="sig-line">________________________________</div>
    <div>Cashier Supervisor / Head</div>
    <div class="sig-role">Signature over Printed Name</div>
  </div>
  <div class="sig-box">
    <div class="sig-line">________________________________</div>
    <div>School Registrar / Admin</div>
    <div class="sig-role">Signature over Printed Name</div>
  </div>
</div>

</body>
</html>
