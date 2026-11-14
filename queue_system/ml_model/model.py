"""
ml_model/model.py — Queue Tracking System ML Service
Random Forest Regressor | Flask REST on port 5001

KEY ML BEHAVIOR:
1. Learns per-purpose average service time from historical_data
2. ERT increases in real-time if current ticket is taking longer than expected
3. ERT decreases in real-time if current ticket is finishing faster
4. Pattern learning: "Getting TOR" always takes ~10 min → ML learns this
5. Base time from Control Panel is used as starting point, ML adjusts it
"""
import os, json, pickle
import numpy as np
import pandas as pd
from datetime import datetime
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import mean_absolute_error, r2_score
from flask import Flask, request, jsonify

BASE  = os.path.dirname(os.path.abspath(__file__))
MODEL = os.path.join(BASE, 'rf_model.pkl')
ENC   = os.path.join(BASE, 'label_encoder.pkl')
# Purpose-specific model (key ML feature)
PURPOSE_MODEL = os.path.join(BASE, 'purpose_model.pkl')
DATA  = os.path.join(BASE, 'training_data.csv')
TYPES = ['Registrar', 'Cashier', 'OSA']

def engineer(df):
    df = df.copy()
    df['is_peak']    = df['time_of_day'].apply(lambda h: 1 if h in range(8,12) or h in range(13,17) else 0)
    df['load_ratio'] = df['queue_length'] / df['windows_open_count'].clip(lower=1)
    return df

def train(csv_path=DATA):
    if not os.path.exists(csv_path):
        generate_data()
        csv_path = DATA
    df = pd.read_csv(csv_path)
    df = df.rename(columns={'queue_length_at_issue':'queue_length','transaction_type':'service_type'})
    df = engineer(df)
    le = LabelEncoder()
    le.fit(TYPES)
    df['svc_enc'] = le.transform(df['service_type'].apply(lambda x: x if x in TYPES else TYPES[0]))
    F = ['queue_length','svc_enc','time_of_day','day_of_week','windows_open_count','is_peak','load_ratio']
    X = df[F].values
    y = df['actual_wait_time'].values
    Xtr,Xte,ytr,yte = train_test_split(X, y, test_size=0.2, random_state=42)
    rf = RandomForestRegressor(n_estimators=200, max_depth=12, random_state=42, n_jobs=-1)
    rf.fit(Xtr, ytr)
    metrics = {
        'mae': round(float(mean_absolute_error(yte, rf.predict(Xte))), 4),
        'r2':  round(float(r2_score(yte, rf.predict(Xte))), 4),
        'trained_at': datetime.now().isoformat(),
        'rows': len(df)
    }
    with open(MODEL,'wb') as f: pickle.dump(rf, f)
    with open(ENC,'wb')   as f: pickle.dump(le, f)

    # ── Train purpose-specific model ──────────────────────────
    # Learns average service time per (service_type, purpose) combination
    # This is the KEY pattern learning: "Getting TOR" = 10 min
    purpose_avgs = {}
    if 'purpose' in df.columns and 'actual_service_time' in df.columns:
        grp = df.groupby(['service_type','purpose'])['actual_service_time'].agg(['mean','count','std'])
        for (svc, pur), row in grp.iterrows():
            if row['count'] >= 3:  # need at least 3 samples to trust the pattern
                purpose_avgs[(svc, pur)] = {
                    'mean': round(float(row['mean']), 2),
                    'count': int(row['count']),
                    'std': round(float(row['std']) if not np.isnan(row['std']) else 0, 2)
                }
    with open(PURPOSE_MODEL,'wb') as f: pickle.dump(purpose_avgs, f)
    metrics['purpose_patterns'] = len(purpose_avgs)
    print(json.dumps(metrics, indent=2))
    return metrics

def get_purpose_service_time(service_type, purpose, base_time):
    """
    Returns the ML-learned average service time for a specific purpose.
    Falls back to base_time if not enough historical data.
    """
    if not os.path.exists(PURPOSE_MODEL):
        return base_time
    try:
        with open(PURPOSE_MODEL,'rb') as f:
            avgs = pickle.load(f)
        key = (service_type, purpose)
        if key in avgs and avgs[key]['count'] >= 3:
            return avgs[key]['mean']
    except Exception:
        pass
    return base_time

def predict(queue_length, service_type, time_of_day, day_of_week, windows_open,
            base_time=None, purpose=None, elapsed_minutes=0):
    """
    Full ML prediction with:
    - Purpose-specific learned service time
    - Real-time ERT adjustment based on elapsed time
    - Upward adjustment if ticket is taking longer than expected
    - Downward adjustment if ticket finishes faster
    """
    default_base = {'Registrar': 10, 'Cashier': 5, 'OSA': 8}
    bt = base_time if base_time is not None else default_base.get(service_type, 10)
    windows = max(1, windows_open)

    # Step 1: Get purpose-adjusted service time
    # If ML has learned "Getting TOR takes 10 min", use that instead of base_time
    if purpose and purpose.strip():
        learned_time = get_purpose_service_time(service_type, purpose, bt)
    else:
        learned_time = bt

    # Step 2: Adjust based on elapsed time of current serving ticket
    # If elapsed > learned_time → ticket is taking longer → ERT increases
    # If elapsed < learned_time → ticket finishing faster → ERT decreases
    if elapsed_minutes > 0:
        # Remaining time for current ticket (can go negative = overdue)
        remaining = max(0, learned_time - elapsed_minutes)
        # If overdue (elapsed > learned_time), remaining = 0 but we add the overrun
        overrun = max(0, elapsed_minutes - learned_time)
        # Total remaining = actual remaining + any overrun still being served
        effective_remaining = remaining + (overrun * 0.5)  # overrun tapers off
    else:
        effective_remaining = learned_time

    if not os.path.exists(MODEL):
        # Cold start: use purpose-learned time as base
        # pos=0 (next): effective_remaining
        # pos=1: effective_remaining + learned_time
        # etc.
        ert = effective_remaining + (queue_length * learned_time / windows)
        return round(max(0.5, ert), 1)

    # Step 3: ML prediction using Random Forest
    with open(MODEL,'rb') as f: model = pickle.load(f)
    with open(ENC,'rb')   as f: le    = pickle.load(f)
    svc  = int(le.transform([service_type if service_type in TYPES else TYPES[0]])[0])
    peak = 1 if time_of_day in range(8,12) or time_of_day in range(13,17) else 0
    X    = np.array([[queue_length, svc, time_of_day, day_of_week, windows, peak, queue_length/windows]])
    ml_wait = float(model.predict(X)[0])  # ML predicts wait time based on historical patterns

    # Step 4: Blend ML wait time with purpose-adjusted ERT
    # ML contributes the queue/time-of-day pattern
    # Purpose model contributes the per-transaction time pattern
    if queue_length == 0:
        # First/next ticket: just remaining time of current serving
        ert = effective_remaining
    else:
        # Blend: 60% purpose-learned, 40% ML wait time pattern
        formula_ert = effective_remaining + (queue_length * learned_time / windows)
        blended = (formula_ert * 0.6) + (ml_wait * 0.4)
        ert = blended

    return round(max(0.5, ert), 1)

def generate_data(rows=2000, path=DATA):
    """
    Generate synthetic training data WITH purpose column
    so the purpose model has something to learn from.
    """
    rng = np.random.default_rng(42)
    base = {'Registrar': 12, 'Cashier': 8, 'OSA': 10}

    # Purpose-specific service times (what ML should learn)
    purpose_times = {
        'Registrar': {
            'Enrollment': 15, 'Grade Slip': 5, 'Certificate of Enrollment': 8,
            'Transcript of Records': 12, 'Good Moral Certificate': 7,
            'Document Request': 10, 'Records Verification': 6,
        },
        'Cashier': {
            'Tuition Fee Payment': 10, 'Miscellaneous Fee': 6,
            'Refund Request': 12, 'Print COM (Certificate of Matriculation)': 8,
        },
        'OSA': {
            'Scholarship Application': 14, 'Leave of Absence': 8,
            'Complaint / Grievance': 10, 'Student Organization': 7,
        }
    }

    records = []
    for _ in range(rows):
        svc  = rng.choice(TYPES)
        b    = base[svc]
        q    = int(rng.integers(0, 25))
        h    = int(rng.integers(7, 18))
        dow  = int(rng.integers(0, 5))
        w    = int(rng.integers(1, 4))
        peak = 1 if h in range(8,12) or h in range(13,17) else 0

        # Pick a random purpose for this service
        purposes_for_svc = list(purpose_times[svc].keys())
        pur = rng.choice(purposes_for_svc)
        purpose_time = purpose_times[svc][pur]

        # Service time is purpose-specific with some noise
        svc_time = max(1.0, purpose_time + float(rng.normal(0, 2)))
        # Wait time = time waiting in queue
        wait = max(1.0, (q / max(w, 1)) * purpose_time + peak * 3 + float(rng.normal(0, 2)))

        records.append({
            'queue_length_at_issue': q,
            'transaction_type':      svc,
            'purpose':               pur,
            'time_of_day':           h,
            'day_of_week':           dow,
            'windows_open_count':    w,
            'actual_wait_time':      round(wait, 2),
            'actual_service_time':   round(svc_time, 2),
        })
    pd.DataFrame(records).to_csv(path, index=False)
    print(f"Synthetic data written: {path} ({rows} rows)")

app = Flask(__name__)

@app.route('/predict', methods=['POST'])
def api_predict():
    d = request.get_json(force=True) or {}
    try:
        base_time = float(d['base_time']) if d.get('base_time') is not None else None
        ert = predict(
            queue_length   = int(d.get('queue_length', 0)),
            service_type   = str(d.get('service_type', 'Registrar')),
            time_of_day    = int(d.get('time_of_day', datetime.now().hour)),
            day_of_week    = int(d.get('day_of_week', datetime.now().weekday())),
            windows_open   = int(d.get('windows_open', 1)),
            base_time      = base_time,
            purpose        = str(d.get('purpose', '')),
            elapsed_minutes= float(d.get('elapsed_minutes', 0)),
        )
        return jsonify({
            'success': True,
            'predicted_ert_minutes': ert,
            'base_time_used': base_time,
            'purpose': d.get('purpose',''),
            'elapsed_minutes': d.get('elapsed_minutes', 0),
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/train', methods=['POST'])
def api_train():
    try:
        return jsonify({'success': True, 'metrics': train()})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/train-from-db', methods=['POST'])
def api_train_from_db():
    """
    Export real transaction data from MySQL then retrain.
    This is how ML learns real GRC patterns (purpose → service time).
    """
    try:
        import pymysql
        d    = request.get_json(force=True) or {}
        conn = pymysql.connect(
            host        = d.get('host', 'localhost'),
            user        = d.get('user', 'root'),
            password    = d.get('password', ''),
            database    = d.get('database', 'queue_tracking_db'),
            cursorclass = pymysql.cursors.DictCursor,
        )
        with conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT
                        hd.queue_length_at_issue,
                        hd.transaction_type,
                        qt.purpose,
                        hd.time_of_day,
                        hd.day_of_week,
                        hd.windows_open_count,
                        hd.actual_wait_time,
                        hd.actual_service_time
                    FROM historical_data hd
                    LEFT JOIN queue_tickets qt ON qt.ticket_id = hd.ticket_id
                    ORDER BY hd.created_at DESC
                """)
                rows = cur.fetchall()
        if not rows:
            return jsonify({'success': False, 'error': 'No historical data yet. Complete some transactions first.'}), 400
        df = pd.DataFrame(rows)
        df.to_csv(DATA, index=False)
        metrics = train(DATA)
        return jsonify({'success': True, 'rows_used': len(rows), 'metrics': metrics})
    except ImportError:
        return jsonify({'success': False, 'error': 'pymysql not installed. Run: pip install pymysql'}), 500
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/purpose-patterns', methods=['GET'])
def api_purpose_patterns():
    """Returns what the ML has learned about each purpose's service time."""
    if not os.path.exists(PURPOSE_MODEL):
        return jsonify({'success': False, 'error': 'No purpose model trained yet.'})
    try:
        with open(PURPOSE_MODEL,'rb') as f:
            avgs = pickle.load(f)
        patterns = {f"{svc}|{pur}": data for (svc, pur), data in avgs.items()}
        return jsonify({'success': True, 'patterns': patterns, 'count': len(patterns)})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/health')
def health():
    has_purpose = os.path.exists(PURPOSE_MODEL)
    purpose_count = 0
    if has_purpose:
        try:
            with open(PURPOSE_MODEL,'rb') as f:
                avgs = pickle.load(f)
            purpose_count = len(avgs)
        except Exception:
            pass
    return jsonify({
        'status': 'ok',
        'model_loaded': os.path.exists(MODEL),
        'purpose_model_loaded': has_purpose,
        'purpose_patterns_learned': purpose_count,
        'time': datetime.now().isoformat()
    })

@app.route('/capacity', methods=['POST'])
def api_capacity():
    try:
        d = request.get_json(force=True) or {}
        target_date = d.get('date', datetime.now().strftime('%Y-%m-%d'))
        hist_df = None; today_tickets = []; windows_open = 1
        if d.get('host'):
            try:
                import pymysql
                conn = pymysql.connect(host=d.get('host','localhost'),user=d.get('user','root'),
                    password=d.get('password',''),database=d.get('database','queue_tracking_db'),
                    cursorclass=pymysql.cursors.DictCursor)
                with conn:
                    with conn.cursor() as cur:
                        cur.execute("SELECT transaction_type as service_type,time_of_day,day_of_week,actual_service_time,actual_wait_time,windows_open_count,queue_length_at_issue FROM historical_data ORDER BY created_at DESC LIMIT 5000")
                        rows = cur.fetchall()
                        if rows: hist_df = pd.DataFrame(rows)
                        cur.execute("SELECT service_type,status,HOUR(issued_at) as hour FROM queue_tickets WHERE DATE(issued_at)=%s",(target_date,))
                        today_tickets = cur.fetchall()
                        cur.execute("SELECT COUNT(*) as cnt FROM service_windows WHERE is_open=1")
                        windows_open = cur.fetchone()['cnt'] or 1
            except Exception: pass
        if hist_df is None and os.path.exists(DATA):
            hist_df = pd.read_csv(DATA)
            hist_df = hist_df.rename(columns={'queue_length_at_issue':'queue_length','transaction_type':'service_type'})
        if hist_df is None:
            return jsonify({'success':False,'error':'No data available.'}),400
        hour_counts = hist_df.groupby('time_of_day').size() if 'time_of_day' in hist_df.columns else pd.Series()
        peak_hour = int(hour_counts.idxmax()) if len(hour_counts)>0 else 9
        avg_service_times = {}
        for svc in TYPES:
            col = 'service_type' if 'service_type' in hist_df.columns else 'transaction_type'
            svc_data = hist_df[hist_df[col]==svc]
            avg_service_times[svc] = round(float(svc_data['actual_service_time'].mean()),1) if len(svc_data)>0 and 'actual_service_time' in svc_data.columns else {'Registrar':12,'Cashier':8,'OSA':10}[svc]
        def cap(sh,eh,w,at):
            return {svc:round((eh-sh)*60/max(at[svc],1)*max(w,1)) for svc in TYPES}
        mc=cap(7,12,windows_open,avg_service_times); mc['total']=sum(mc[s] for s in TYPES)
        ac=cap(13,17,windows_open,avg_service_times); ac['total']=sum(ac[s] for s in TYPES)
        tbs={svc:{'served':0,'total':0} for svc in TYPES}
        ms=0;mt=0;as_=0;at_=0
        for t in today_tickets:
            h=int(t.get('hour',0));s=t.get('service_type','');st=t.get('status','')
            if s in tbs:tbs[s]['total']+=1;tbs[s]['served']+=(1 if st=='Served' else 0)
            if 7<=h<12:mt+=1;ms+=(1 if st=='Served' else 0)
            elif 13<=h<17:at_+=1;as_+=(1 if st=='Served' else 0)
        hl=lambda h:f"{h if h<=12 else h-12}:00 {'AM' if h<12 else 'PM'}"
        ch=datetime.now().hour
        return jsonify({'success':True,'date':target_date,'peak_hour':peak_hour,'peak_hour_label':hl(peak_hour),
            'windows_open':windows_open,'avg_service_times':avg_service_times,
            'current_block':'morning' if 7<=ch<12 else ('afternoon' if 13<=ch<17 else None),
            'morning':{'label':'7:00 AM – 12:00 PM','capacity':mc,'served':ms,'total':mt,'pct':round(ms/max(mc['total'],1)*100,1)},
            'afternoon':{'label':'1:00 PM – 5:00 PM','capacity':ac,'served':as_,'total':at_,'pct':round(as_/max(ac['total'],1)*100,1)},
            'today_by_service':tbs,'hour_distribution':{int(h):int(c) for h,c in hour_counts.items()}})
    except Exception as e:
        return jsonify({'success':False,'error':str(e)}),500

if __name__ == '__main__':
    import sys
    if len(sys.argv)>1 and sys.argv[1]=='generate': generate_data()
    elif len(sys.argv)>1 and sys.argv[1]=='train': train()
    else:
        if not os.path.exists(MODEL): generate_data(); train()
        app.run(host='0.0.0.0', port=5001, debug=False)
