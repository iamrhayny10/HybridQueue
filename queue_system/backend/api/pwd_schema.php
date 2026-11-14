<?php
// ============================================================
// pwd_schema.php — adds the columns used by the PWD Priority Lane
// (runs once, then leaves a marker file; no manual SQL needed)
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
    foreach($cols as $table=>$list){
        foreach($list as $c=>$def){
            try{$db->query("SELECT $c FROM $table LIMIT 1");}
            catch(Exception $e){try{$db->exec("ALTER TABLE $table ADD COLUMN $c $def");}catch(Exception $e2){}}
        }
    }
    @file_put_contents($marker,date('c'));
}
