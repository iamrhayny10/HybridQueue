<?php
// ============================================================
// pwd.php — PWD Priority Lane verification
//   Student (mobile app, signed token):  POST ?action=apply   GET ?action=status
//   Admin   (web dashboard, 403 for others): GET ?action=list  GET ?action=photo  POST ?action=review
// ============================================================
error_reporting(0);
@ini_set('display_errors','0');
require_once __DIR__.'/../config/auth_guard.php';
require_once __DIR__.'/../config/pwd_schema.php';
sendHeaders();
$db=getDB();ensurePwdColumns($db);
$method=$_SERVER['REQUEST_METHOD'];
$action=isset($_GET['action'])?$_GET['action']:'';
$body=json_decode(file_get_contents('php://input'),true);if(!$body)$body=array();
$UPLOAD_DIR=__DIR__.'/../uploads/pwd';

function pwdUploadDir($dir){
    if(!is_dir($dir))@mkdir($dir,0755,true);
    if(!is_file($dir.'/.htaccess'))@file_put_contents($dir.'/.htaccess',"Require all denied\nDeny from all\n");   // images are never served directly
    if(!is_file($dir.'/index.html'))@file_put_contents($dir.'/index.html','');
}

// ── STUDENT: submit PWD ID number + photo for verification ───
if($method==='POST'&&$action==='apply'){
    $me=requireLogin();
    if($me['role']!=='Student')jsonError('Only students can apply for the PWD Priority Lane.',403);
    $s=$db->prepare('SELECT pwd_status,pwd_id_photo FROM users WHERE user_id=?');$s->execute(array($me['user_id']));$cur=$s->fetch();
    if($cur['pwd_status']==='verified')jsonError('Your PWD status is already verified.',409);

    $num=strtoupper(trim(isset($body['pwd_id_number'])?$body['pwd_id_number']:''));
    if(!preg_match('/^[A-Z0-9][A-Z0-9\-\/ ]{5,29}$/',$num))jsonError('Enter a valid PWD ID number (6–30 characters: letters, numbers, dashes).');
    $c=$db->prepare("SELECT user_id FROM users WHERE pwd_id_number=? AND user_id<>? AND pwd_status IN('pending','verified') LIMIT 1");
    $c->execute(array($num,$me['user_id']));
    if($c->fetch())jsonError('This PWD ID number is already registered to another account.',409);

    $raw=isset($body['photo_base64'])?$body['photo_base64']:'';
    if(strpos($raw,',')!==false)$raw=substr($raw,strpos($raw,',')+1);
    $img=base64_decode($raw,true);
    if(!$img||strlen($img)<1000)jsonError('Please attach a clear photo of your PWD ID.');
    if(strlen($img)>4*1024*1024)jsonError('Photo is too large (max 4 MB).');
    $info=@getimagesizefromstring($img);
    if(!$info||!in_array($info[2],array(IMAGETYPE_JPEG,IMAGETYPE_PNG),true))jsonError('Photo must be a JPG or PNG image.');
    $ext=$info[2]===IMAGETYPE_PNG?'png':'jpg';

    pwdUploadDir($UPLOAD_DIR);
    $fname='u'.$me['user_id'].'_'.time().'.'.$ext;
    if(@file_put_contents($UPLOAD_DIR.'/'.$fname,$img)===false)jsonError('Could not save the photo. Please try again.',500);
    if(!empty($cur['pwd_id_photo'])&&is_file($UPLOAD_DIR.'/'.basename($cur['pwd_id_photo'])))@unlink($UPLOAD_DIR.'/'.basename($cur['pwd_id_photo']));

    $db->prepare("UPDATE users SET pwd_status='pending',pwd_id_number=?,pwd_id_photo=?,pwd_reject_reason=NULL,pwd_verified_by=NULL,pwd_verified_at=NULL WHERE user_id=?")
       ->execute(array($num,$fname,$me['user_id']));
    logAction($me['user_id'],'pwd_applied','Student submitted PWD ID for verification.');
    jsonOut(array('success'=>true,'pwd_status'=>'pending','message'=>'Submitted. Please wait for the school to verify your PWD ID.'));
}

// ── STUDENT: my PWD status ───────────────────────────────────
if($method==='GET'&&$action==='status'){
    $me=requireLogin();
    $s=$db->prepare('SELECT pwd_status,pwd_id_number,pwd_reject_reason FROM users WHERE user_id=?');$s->execute(array($me['user_id']));$r=$s->fetch();
    jsonOut(array('success'=>true,'pwd_status'=>$r['pwd_status'],'pwd_id_number'=>$r['pwd_id_number'],'reject_reason'=>$r['pwd_reject_reason']));
}

// ── ADMIN: everything below ──────────────────────────────────
if($method==='GET'&&$action==='list'){
    requireRole('Admin');
    $st=isset($_GET['status'])?$_GET['status']:'pending';
    $sql="SELECT user_id,full_name,username AS student_id,email,pwd_status,pwd_id_number,pwd_reject_reason,pwd_verified_at,(pwd_id_photo IS NOT NULL AND pwd_id_photo<>'') AS has_photo FROM users WHERE role='Student' AND pwd_status<>'none'";
    $p=array();
    if(in_array($st,array('pending','verified','rejected'),true)){$sql.=' AND pwd_status=?';$p[]=$st;}
    $sql.=' ORDER BY FIELD(pwd_status,\'pending\',\'verified\',\'rejected\'),full_name';
    try{$q=$db->prepare($sql);$q->execute($p);}
    catch(Exception $e){$q=$db->prepare(str_replace(' ORDER BY FIELD(pwd_status,\'pending\',\'verified\',\'rejected\'),full_name',' ORDER BY full_name',$sql));$q->execute($p);}
    jsonOut(array('success'=>true,'applications'=>$q->fetchAll()));
}
if($method==='GET'&&$action==='photo'){
    requireRole('Admin');
    $uid=(int)(isset($_GET['user_id'])?$_GET['user_id']:0);
    $s=$db->prepare("SELECT pwd_id_photo FROM users WHERE user_id=? AND role='Student'");$s->execute(array($uid));$f=$s->fetchColumn();
    $path=$UPLOAD_DIR.'/'.basename((string)$f);
    if(!$f||!is_file($path)){http_response_code(404);header('Content-Type: application/json');echo json_encode(array('success'=>false,'error'=>'No photo.'));exit;}
    header('Content-Type: '.(substr($path,-3)==='png'?'image/png':'image/jpeg'));
    header('Cache-Control: no-store');
    readfile($path);exit;
}
if($method==='POST'&&$action==='review'){
    $me=requireRole('Admin');
    $uid=(int)(isset($body['user_id'])?$body['user_id']:0);
    $dec=isset($body['decision'])?$body['decision']:'';
    $reason=trim(isset($body['reason'])?$body['reason']:'');
    $s=$db->prepare("SELECT user_id,full_name,username,pwd_status FROM users WHERE user_id=? AND role='Student'");$s->execute(array($uid));$u=$s->fetch();
    if(!$u)jsonError('Student not found.',404);
    if($dec==='approve'){
        if($u['pwd_status']!=='pending')jsonError('Only pending applications can be approved.',409);
        $db->prepare("UPDATE users SET pwd_status='verified',pwd_reject_reason=NULL,pwd_verified_by=?,pwd_verified_at=NOW() WHERE user_id=?")->execute(array($me['user_id'],$uid));
        logAction($me['user_id'],'pwd_verified',"PWD verified for {$u['full_name']} ({$u['username']}) by {$me['username']}.");
        jsonOut(array('success'=>true,'message'=>'PWD status verified. The student can now use the Priority Lane.'));
    }
    if($dec==='reject'||$dec==='revoke'){
        if($reason==='')jsonError('Please enter a reason.');
        if($dec==='reject'&&$u['pwd_status']!=='pending')jsonError('Only pending applications can be rejected.',409);
        if($dec==='revoke'&&$u['pwd_status']!=='verified')jsonError('Only verified students can be revoked.',409);
        $db->prepare("UPDATE users SET pwd_status='rejected',pwd_reject_reason=?,pwd_verified_by=?,pwd_verified_at=NULL WHERE user_id=?")->execute(array(substr($reason,0,250),$me['user_id'],$uid));
        logAction($me['user_id'],$dec==='reject'?'pwd_rejected':'pwd_revoked',"PWD {$dec} for {$u['full_name']} ({$u['username']}) by {$me['username']}: $reason");
        jsonOut(array('success'=>true,'message'=>$dec==='reject'?'Application rejected.':'Priority access revoked.'));
    }
    jsonError('decision must be approve, reject or revoke.');
}
jsonError('Invalid action.',404);
