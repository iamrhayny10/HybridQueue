// ================================================================
// GRC Queue Tracking System — URL Configuration
// ================================================================
// ONLY EDIT THIS FILE when your tunnel URL changes.
// All other files (admin dashboard, display screen) read from here.
//
// HOW TO USE:
// 1. Start your tunnel (Cloudflare/Serveo/ngrok)
// 2. Copy the URL it gives you
// 3. Paste it below as BASE_URL (no trailing slash)
// 4. Save this file
// 5. Refresh the admin dashboard / display screen
// NO APK rebuild needed for web changes.
//
// EXAMPLES:
//   Cloudflare : 'https://abc-def-ghi.trycloudflare.com'
//   Serveo     : 'https://grcqueue2.serveousercontent.com'
//   ngrok      : 'https://abc123.ngrok-free.app'
//   Local only : 'http://localhost'
// ================================================================

const BASE_URL = 'https://grcqueue2.serveousercontent.com';

// ── DO NOT EDIT BELOW THIS LINE ──────────────────────────────
const API = window.location.hostname === 'localhost'
  ? 'http://localhost/queue_system/backend/api'
  : BASE_URL + '/queue_system/backend/api';
