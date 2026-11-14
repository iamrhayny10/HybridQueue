<?php
// ============================================================
// auth_guard.php — signed login tokens + role checks
// Used by auth.php (issues tokens) and pwd.php (checks them).
// Token = base64url(payload) . '.' . HMAC-SHA256(payload, secret)
// Clients send it in the  X-Auth-Token  header (web admin + mobile app).
// The role is always re-read from the database, never trusted from the token.
// ============================================================
require_once __DIR__.'/db.php';

function authSecret(){
    static $s=null;
    if($s!==null)return $s;
    $f=__DIR__.'/.auth_secret';
    if(is_file($f)){$v=trim((string)@file_get_contents($f));if(strlen($v)>=32)return $s=$v;}
    $v=bin2hex(random_bytes(32));
    if(@file_put_contents($f,$v,LOCK_EX)!==false){@chmod($f,0600);return $s=$v;}
    // fallback if the folder is not writable: derived from the DB settings
    return $s=hash('sha256','grc-auth|'.DB_HOST.'|'.DB_NAME.'|'.DB_USER.'|'.DB_PASS);
}

function makeAuthToken($uid,$role,$ttl=604800){   // valid 7 days
    $p=rtrim(strtr(base64_encode(json_encode(array('u'=>(int)$uid,'r'=>$role,'e'=>time()+(int)$ttl))),'+/','-_'),'=');
    return $p.'.'.hash_hmac('sha256',$p,authSecret());
}

function readAuthToken(){
    $t='';
    if(!empty($_SERVER['HTTP_X_AUTH_TOKEN']))$t=trim($_SERVER['HTTP_X_AUTH_TOKEN']);
    elseif(!empty($_SERVER['HTTP_AUTHORIZATION'])&&stripos($_SERVER['HTTP_AUTHORIZATION'],'Bearer ')===0)$t=trim(substr($_SERVER['HTTP_AUTHORIZATION'],7));
    if($t==='')return null;
    $parts=explode('.',$t);
    if(count($parts)!==2)return null;
    if(!hash_equals(hash_hmac('sha256',$parts[0],authSecret()),$parts[1]))return null;
    $d=json_decode(base64_decode(strtr($parts[0],'-_','+/')),true);
    if(!is_array($d)||empty($d['u'])||empty($d['e'])||$d['e']<time())return null;
    return $d;
}

function requireLogin(){
    $p=readAuthToken();
    if(!$p)jsonError('Please log in again.',401);
    $s=getDB()->prepare('SELECT user_id,username,full_name,role FROM users WHERE user_id=? AND is_active=1 LIMIT 1');
    $s->execute(array((int)$p['u']));
    $u=$s->fetch();
    if(!$u)jsonError('Please log in again.',401);
    return $u;
}

function requireRole($role){
    $u=requireLogin();
    if($u['role']!==$role)jsonError('Access denied.',403);
    return $u;
}
