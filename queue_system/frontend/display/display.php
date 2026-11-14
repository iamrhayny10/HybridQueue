<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>GRC Queue Display</title>
<style>
:root{--mar:#7B1F2B;--mar2:#8F2E3B;--cream:#FFF7F2;--peach:#FFF1E0;--line:#EBDDD0;--ink:#2B1A1A;--mute:#7A6A62;--gold:#F5B942;--goldbtn:#D4A017}
*{box-sizing:border-box;margin:0;padding:0}
html{font-size:clamp(13px,1.05vw,26px)}
body{font-family:'Segoe UI',system-ui,-apple-system,sans-serif;background:var(--cream);color:var(--ink);height:100vh;display:flex;flex-direction:column;overflow:hidden}

/* header */
.topbar{background:var(--mar);padding:1rem 1.6rem;display:flex;align-items:center;justify-content:space-between;flex-shrink:0}
.tbl{display:flex;align-items:center;gap:1rem}
.logo-box{width:3.5rem;height:3.5rem;background:#FFF7F2;border-radius:.9rem;display:flex;align-items:center;justify-content:center;flex-shrink:0}
.logo-img{width:2.6rem;height:2.6rem;object-fit:contain}
.tb-title{font-size:1.75rem;font-weight:700;color:#fff;line-height:1.15}
.tb-sub{font-size:1rem;color:#EBCFD2;margin-top:.15rem}
.tbr{text-align:right}
.tbr-date{font-size:1.05rem;color:#EBCFD2}
.tbr-time{font-size:2.2rem;font-weight:700;font-family:Consolas,'Courier New',monospace;color:var(--gold);line-height:1.1}

/* now serving */
.ns{padding:1.1rem 1.6rem .6rem;flex-shrink:0}
.ns-lbl{font-size:1.05rem;font-weight:600;letter-spacing:.14em;text-transform:uppercase;color:var(--mar);margin-bottom:.8rem}
.ns-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(14rem,1fr));gap:.9rem}
.ns-card{background:#fff;border:2px solid var(--line);border-radius:1.2rem;padding:1.1rem 1.2rem;min-height:11.5rem;display:flex;flex-direction:column;transition:all .4s}
.ns-win{font-size:1.4rem;font-weight:700;color:var(--ink)}
.ns-staff{font-size:1.05rem;color:var(--mute);margin-top:.1rem}
.ns-num{font-size:3.1rem;font-weight:700;color:var(--mute);line-height:1.15;margin-top:.5rem;font-family:'Segoe UI',system-ui,sans-serif}
.ns-svc{margin-top:auto;font-size:1.1rem;font-weight:700;text-transform:uppercase;letter-spacing:.02em;color:var(--ink)}
.ns-card.serving{background:var(--mar);border-color:var(--mar)}
.ns-card.serving .ns-win{color:#fff}.ns-card.serving .ns-staff{color:#EBCFD2}
.ns-card.serving .ns-num{color:var(--gold);font-family:Consolas,'Courier New',monospace;font-size:3.4rem;letter-spacing:.02em}
.ns-card.serving .ns-svc{color:#FFF7F2}
.prio{display:inline-block;background:var(--gold);color:#4A2A00;font-size:.9rem;font-weight:700;padding:.15rem .7rem;border-radius:1rem;margin-top:.25rem;align-self:flex-start}
.blink{animation:blink 1.4s infinite}@keyframes blink{0%,100%{opacity:1}50%{opacity:.65}}

/* service queues */
.queues{flex:1;display:grid;grid-template-columns:repeat(3,1fr);gap:.9rem;padding:.5rem 1.6rem 1rem;min-height:0;overflow:hidden}
.qcol{background:#fff;border:2px solid var(--line);border-radius:1.2rem;display:flex;flex-direction:column;overflow:hidden;min-height:0}
.qhdr{padding:.9rem 1.1rem;background:var(--peach);border-bottom:2px solid var(--line);display:flex;align-items:center;justify-content:space-between;flex-shrink:0}
.qtitle{display:flex;align-items:center;gap:.7rem;font-size:1.4rem;font-weight:600;color:var(--ink)}
.dot{width:.9rem;height:.9rem;border-radius:50%;flex-shrink:0}
.dot.reg{background:#3B82F6}.dot.cas{background:#10B981}.dot.osa{background:#F59E0B}
.qcnt{font-size:1.05rem;font-weight:600;padding:.3rem .9rem;border-radius:2rem;background:#F8E7B5;color:#6B4E00}
.qcnt.clear{background:#CFF5E4;color:#065F46}
.qbody{flex:1;overflow-y:auto;min-height:0}
.qbody::-webkit-scrollbar{width:4px}.qbody::-webkit-scrollbar-thumb{background:#E3CDBB;border-radius:2px}
.qrow{display:flex;align-items:center;justify-content:space-between;padding:.85rem 1.1rem;border-bottom:2px solid var(--line)}
.qrow:last-child{border-bottom:none}
.qnum{font-size:1.9rem;font-family:Consolas,'Courier New',monospace;font-weight:500}
.qnum.reg{color:#1D4ED8}.qnum.cas{color:#047857}.qnum.osa{color:#B45309}
.qtag{display:inline-block;background:#DBEAFE;color:#1E40AF;font-size:.85rem;font-weight:700;padding:.1rem .6rem;border-radius:1rem;margin-left:.6rem;vertical-align:middle;font-family:'Segoe UI',system-ui,sans-serif}
.qrow.pr{background:#FFFBEA}
.qstat{font-size:1.15rem;color:var(--mute)}
.empty{text-align:center;padding:2.4rem 1rem;color:var(--mute);font-size:1.2rem}

/* notice bar */
.ticker{background:var(--mar);padding:.8rem 1.6rem;flex-shrink:0;display:flex;align-items:center;gap:1rem;overflow:hidden;white-space:nowrap;margin:0}
.ticker-lbl{background:var(--goldbtn);color:#3B2A00;font-size:1rem;font-weight:700;padding:.3rem 1rem;border-radius:.6rem;flex-shrink:0;letter-spacing:.03em}
.ticker-track{flex:1;overflow:hidden}
.ticker-txt{display:inline-block;animation:marquee 45s linear infinite;font-size:1.15rem;color:#FFF7F2;white-space:nowrap}
@keyframes marquee{0%{transform:translateX(100vw)}100%{transform:translateX(-100%)}}
</style>
</head><body>
<div class="topbar">
  <div class="tbl"><div class="logo-box"><img src="../assets/images/grc_logo.png" alt="GRC" class="logo-img"></div><div><div class="tb-title">GRC Queue Monitor</div><div class="tb-sub">Global Reciprocal Colleges — Registrar Building</div></div></div>
  <div class="tbr"><div class="tbr-date" id="d-date"></div><div class="tbr-time" id="d-time"></div></div>
</div>
<div class="ns">
  <div class="ns-lbl">Now serving</div>
  <div class="ns-grid" id="ns-grid">
    <div class="ns-card"><div class="ns-win">Registrar</div><div class="ns-num">Ready</div><div class="ns-svc">Window closed</div></div>
    <div class="ns-card"><div class="ns-win">Cashier</div><div class="ns-num">Ready</div><div class="ns-svc">Window closed</div></div>
    <div class="ns-card"><div class="ns-win">OSA</div><div class="ns-num">Ready</div><div class="ns-svc">Window closed</div></div>
  </div>
</div>
<div class="queues">
  <div class="qcol"><div class="qhdr"><div class="qtitle"><span class="dot reg"></span>Registrar</div><div class="qcnt clear" id="cnt-Registrar">All clear</div></div><div class="qbody" id="col-Registrar"><div class="empty">No tickets in queue</div></div></div>
  <div class="qcol"><div class="qhdr"><div class="qtitle"><span class="dot cas"></span>Cashier</div><div class="qcnt clear" id="cnt-Cashier">All clear</div></div><div class="qbody" id="col-Cashier"><div class="empty">No tickets in queue</div></div></div>
  <div class="qcol"><div class="qhdr"><div class="qtitle"><span class="dot osa"></span>OSA</div><div class="qcnt clear" id="cnt-OSA">All clear</div></div><div class="qbody" id="col-OSA"><div class="empty">No tickets in queue</div></div></div>
</div>
<div class="ticker"><span class="ticker-lbl">NOTICE</span><div class="ticker-track"><span class="ticker-txt">Welcome to Global Reciprocal Colleges Queue Tracker. &nbsp;|&nbsp; Please get your queue number via the GRC Queue mobile app. &nbsp;|&nbsp; Registrar: enrollment, grades, certificates, transcript. &nbsp;|&nbsp; Cashier: tuition fees, payments, refunds. &nbsp;|&nbsp; OSA: student affairs, scholarships, organizations. &nbsp;|&nbsp; Persons with Disability (PWD) are served first through the Priority Lane. &nbsp;|&nbsp; Please watch this screen for your number. Thank you for your patience.</span></div></div>
<script>
// API URL — change this when your tunnel URL changes
const API=window.location.hostname==='localhost'?'http://localhost/queue_system/backend/api':'https://grcqueue2.serveousercontent.com/queue_system/backend/api';
const SVCS=['Registrar','Cashier','OSA'];const CLS={Registrar:'reg',Cashier:'cas',OSA:'osa'};
const isPr=t=>parseInt(t&&t.is_priority)===1;
function tick(){const now=new Date();
  document.getElementById('d-time').textContent=now.toLocaleTimeString('en-US',{hour:'2-digit',minute:'2-digit',second:'2-digit'});
  document.getElementById('d-date').textContent=now.toLocaleDateString('en-US',{weekday:'long',year:'numeric',month:'long',day:'numeric'});}
setInterval(tick,1000);tick();
async function refresh(){
  try{
    const hdrs={'Content-Type':'application/json','bypass-tunnel-reminder':'true','User-Agent':'GRCQueueDisplay/1.0'};
    const[wr,tr]=await Promise.all([fetch(API+'/windows.php',{headers:hdrs}).then(r=>r.json()),fetch(API+'/tickets.php',{headers:hdrs}).then(r=>r.json())]);
    const wins=wr.windows||[];const tickets=tr.tickets||[];
    const ns=document.getElementById('ns-grid');
    // One card per OPEN WINDOW — each window shows its own number independently.
    const openWins=wins.filter(w=>w.is_open==1).sort((a,b)=>{const o=SVCS.indexOf(a.service_type)-SVCS.indexOf(b.service_type);return o||a.window_name.localeCompare(b.window_name);});
    if(!openWins.length){
      ns.innerHTML=SVCS.map(svc=>`<div class="ns-card"><div class="ns-win">${svc}</div><div class="ns-num">Ready</div><div class="ns-svc">No windows open</div></div>`).join('');
    }else{
      ns.innerHTML=openWins.map(win=>{const svc=win.service_type;
        const srv=tickets.find(t=>t.window_id===win.window_id&&t.status==='Serving');
        const staff=win.staff_name||'Staff';
        if(srv)return`<div class="ns-card serving"><div class="ns-win">${win.window_name}</div><div class="ns-staff">${staff}</div><div class="ns-num blink">${srv.ticket_number}</div>${isPr(srv)?'<div class="prio">♿ PWD PRIORITY</div>':''}<div class="ns-svc">${svc} · Serving</div></div>`;
        return`<div class="ns-card"><div class="ns-win">${win.window_name}</div><div class="ns-staff">${staff}</div><div class="ns-num">Ready</div><div class="ns-svc">${svc} · Open</div></div>`;
      }).join('');
    }
    SVCS.forEach(svc=>{const c=CLS[svc];
      // waiting tickets only; PWD priority first, then by time issued
      const waiting=tickets.filter(t=>t.service_type===svc&&t.status==='Waiting')
        .sort((a,b)=>(isPr(b)-isPr(a))||(new Date(String(a.issued_at).replace(' ','T'))-new Date(String(b.issued_at).replace(' ','T'))));
      const cnt=document.getElementById('cnt-'+svc);
      cnt.textContent=waiting.length===0?'All clear':`${waiting.length} waiting`;
      cnt.className='qcnt'+(waiting.length===0?' clear':'');
      const col=document.getElementById('col-'+svc);
      if(!waiting.length){col.innerHTML='<div class="empty">No tickets in queue</div>';return;}
      col.innerHTML=waiting.map(t=>`<div class="qrow${isPr(t)?' pr':''}"><div class="qnum ${c}">${t.ticket_number}${isPr(t)?'<span class="qtag">♿ PWD</span>':''}</div><div class="qstat">Waiting</div></div>`).join('');
    });
  }catch(e){console.error('Refresh error',e);}
}
refresh();setInterval(refresh,5000);
</script></body></html>
