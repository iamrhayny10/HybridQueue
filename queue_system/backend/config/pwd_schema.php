<?php
// ============================================================
// pwd_schema.php — adds the columns used by the PWD Priority Lane
// Lives in backend/config/ (tickets.php and pwd.php load it from there).
// Runs once, then leaves a marker file; no manual SQL needed.
// The marker is only written when every column really exists, so a
// failed ALTER is retried on the next request instead of being hidden.
// ============================================================
function ensurePwdColumns($db){
    $marker=__DIR__.'/.pwd_migrated';
    if(is_file($marker))return;
    $cols=array(
        'users'=>array(
            'pwd_status'        =>"VARCHAR(12) NOT NULL DEFAULT 'none'",   // none | pending | verified | rejected
            'pwd_id_number'     =>'VARCHAR(40) NULL',
            'pwd_id_photo'      =>'VARCHAR(120) NULL',
            'pwd_reject_reason' =>'VARCHAR(255) NULL',
            'pwd_verified_by'   =>'INT NULL',
            'pwd_verified_at'   =>'DATETIME NULL'
        ),
        'queue_tickets'=>array(
            'is_priority'       =>'TINYINT(1) NOT NULL DEFAULT 0'
        )
    );
    $allOk=true;
    foreach($cols as $table=>$list){
        foreach($list as $c=>$def){
            try{$db->query("SELECT $c FROM $table LIMIT 1");}
            catch(Exception $e){
                try{$db->exec("ALTER TABLE $table ADD COLUMN $c $def");}
                catch(Exception $e2){$allOk=false;}
            }
        }
    }
    if($allOk)@file_put_contents($marker,date('c'));
}
