#!/bin/sh
set -e

### CONFIG #########################################################

DOMAIN_UNICODE="妈.妈"
DOMAIN_PUNY="xn--hvs.xn--hvs"

SITE_DIR="/usr/local/var/mama-site"
DNSMASQ_CONF="/usr/local/etc/dnsmasq.conf"
RESOLVER_DIR="/etc/resolver"
RESOLVER_FILE="$RESOLVER_DIR/$DOMAIN_PUNY"

###################################################################

echo "▶ Installing local domain: $DOMAIN_UNICODE ($DOMAIN_PUNY)"
echo

### 1. /etc/hosts (append-only, idempotent) ########################

echo "▶ Updating /etc/hosts"

if ! grep -qE "^[[:space:]]*127\.0\.0\.1[[:space:]]+$DOMAIN_PUNY" /etc/hosts; then
  echo "127.0.0.1 $DOMAIN_PUNY" | sudo tee -a /etc/hosts >/dev/null
  echo "  ✔ Added IPv4 hosts entry"
else
  echo "  ℹ IPv4 hosts entry already exists"
fi

if ! grep -qE "^[[:space:]]*::1[[:space:]]+$DOMAIN_PUNY" /etc/hosts; then
  echo "::1 $DOMAIN_PUNY" | sudo tee -a /etc/hosts >/dev/null
  echo "  ✔ Added IPv6 hosts entry"
else
  echo "  ℹ IPv6 hosts entry already exists"
fi

echo

### 2. Homebrew + dnsmasq ##########################################

if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew not found. Install Homebrew first."
  exit 1
fi

if ! brew list dnsmasq >/dev/null 2>&1; then
  echo "▶ Installing dnsmasq"
  brew install dnsmasq
else
  echo "ℹ dnsmasq already installed"
fi

echo

### 3. dnsmasq config ##############################################

echo "▶ Configuring dnsmasq"

sudo mkdir -p "$(dirname "$DNSMASQ_CONF")"

if ! grep -q "$DOMAIN_PUNY" "$DNSMASQ_CONF" 2>/dev/null; then
  sudo tee -a "$DNSMASQ_CONF" >/dev/null <<EOF

# $DOMAIN_UNICODE local override
address=/$DOMAIN_PUNY/127.0.0.1
address=/$DOMAIN_PUNY/::1
EOF
  echo "  ✔ Added dnsmasq rules"
else
  echo "  ℹ dnsmasq already configured"
fi

echo

### 4. /etc/resolver ##############################################

echo "▶ Creating /etc/resolver entry"

sudo mkdir -p "$RESOLVER_DIR"

sudo tee "$RESOLVER_FILE" >/dev/null <<EOF
nameserver 127.0.0.1
port 53
EOF

echo "  ✔ Resolver created: $RESOLVER_FILE"
echo

### 5. Start dnsmasq ###############################################

echo "▶ Starting dnsmasq"

sudo brew services restart dnsmasq || sudo dnsmasq

echo

### 6. Local site directory #######################################

echo "▶ Creating site directory: $SITE_DIR"

sudo mkdir -p "$SITE_DIR"
sudo chown "$(whoami)" "$SITE_DIR"

if [ ! -f "$SITE_DIR/index.html" ]; then
  cat > "$SITE_DIR/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>妈.妈 — local toolbox</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="color-scheme" content="light dark" />
  <style>
    :root {
      --bg: #f6f7f9;
      --fg: #111;
      --muted: #666;
      --card: #fff;
      --border: #e5e7eb;
      --accent: #2563eb;
      --accent2: #111827;
      --danger: #dc2626;
      --ok: #16a34a;
      --shadow: 0 10px 25px rgba(0,0,0,0.08);
      --radius: 14px;
      --pad: 16px;
      --fontScale: 1;
      --mono: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
      --sans: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, "Apple Color Emoji","Segoe UI Emoji";
    }

    [data-theme="dark"]{
      --bg: #0b1220;
      --fg: #e5e7eb;
      --muted: #9ca3af;
      --card: #0f172a;
      --border: #22314a;
      --accent: #60a5fa;
      --accent2: #cbd5e1;
      --shadow: 0 14px 30px rgba(0,0,0,0.35);
    }

    html, body { height: 100%; }
    body {
      margin: 0;
      background: var(--bg);
      color: var(--fg);
      font-family: var(--sans);
      font-size: calc(14px * var(--fontScale));
      line-height: 1.35;
    }

    .app {
      display: grid;
      grid-template-rows: auto auto 1fr;
      min-height: 100%;
    }

    header {
      padding: 14px 18px;
      border-bottom: 1px solid var(--border);
      background: var(--card);
      box-shadow: 0 1px 0 rgba(0,0,0,0.03);
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
    }

    .brand {
      display: flex;
      align-items: baseline;
      gap: 12px;
    }

    .brand h1 {
      margin: 0;
      font-size: 20px;
      font-weight: 700;
      letter-spacing: -0.2px;
    }

    .brand .tag {
      color: var(--muted);
      font-size: 12px;
    }

    .topActions {
      display: flex;
      gap: 8px;
      align-items: center;
      flex-wrap: wrap;
      justify-content: flex-end;
    }

    .pill {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 8px 10px;
      border: 1px solid var(--border);
      border-radius: 999px;
      background: color-mix(in srgb, var(--card) 90%, transparent);
      color: var(--fg);
      font-size: 12px;
      user-select: none;
    }

    button, .btn {
      border: 1px solid var(--border);
      background: transparent;
      color: var(--fg);
      padding: 8px 10px;
      border-radius: 10px;
      cursor: pointer;
      font-size: 12px;
    }

    button.primary {
      background: var(--accent);
      border-color: color-mix(in srgb, var(--accent) 80%, black);
      color: white;
    }
    button.danger { border-color: color-mix(in srgb, var(--danger) 60%, var(--border)); color: var(--danger); }

    button:disabled { opacity: 0.6; cursor: not-allowed; }

    .tabs {
      background: var(--card);
      border-bottom: 1px solid var(--border);
      padding: 10px 12px;
      display: flex;
      gap: 8px;
      overflow: auto;
      scrollbar-width: thin;
    }

    .tabBtn {
      border: 1px solid var(--border);
      background: transparent;
      padding: 8px 12px;
      border-radius: 999px;
      cursor: pointer;
      white-space: nowrap;
      font-size: 13px;
      color: var(--muted);
    }
    .tabBtn.active {
      background: var(--accent);
      border-color: color-mix(in srgb, var(--accent) 70%, black);
      color: white;
    }

    main {
      padding: 18px;
      display: grid;
      place-items: start center;
    }

    .wrap { width: min(1080px, 100%); }

    .grid {
      display: grid;
      grid-template-columns: 1fr;
      gap: 14px;
    }
    @media (min-width: 860px){
      .grid.two { grid-template-columns: 1fr 1fr; }
    }

    .card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: var(--pad);
      box-shadow: var(--shadow);
    }

    .card h2, .card h3 {
      margin: 0 0 10px 0;
      font-size: 15px;
      letter-spacing: -0.2px;
    }

    .muted { color: var(--muted); }
    .row { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
    .spacer { flex: 1; }

    .subtabs { display: flex; gap: 8px; flex-wrap: wrap; margin: 4px 0 12px; }
    .subBtn { padding: 7px 10px; border-radius: 10px; }
    .subBtn.active { background: color-mix(in srgb, var(--accent) 18%, var(--card)); border-color: color-mix(in srgb, var(--accent) 45%, var(--border)); color: var(--fg); }

    input[type="text"], input[type="number"], select, textarea {
      width: 100%;
      box-sizing: border-box;
      border: 1px solid var(--border);
      background: color-mix(in srgb, var(--card) 95%, transparent);
      color: var(--fg);
      border-radius: 10px;
      padding: 10px 10px;
      font-family: var(--mono);
      font-size: 13px;
    }
    textarea { min-height: 110px; resize: vertical; }

    .kv {
      display: grid;
      grid-template-columns: 160px 1fr;
      gap: 8px;
      align-items: start;
      font-size: 13px;
    }
    .kv b { color: var(--accent2); font-weight: 700; }

    pre {
      margin: 0;
      padding: 10px;
      border-radius: 10px;
      border: 1px dashed var(--border);
      background: color-mix(in srgb, var(--bg) 60%, transparent);
      overflow: auto;
      font-family: var(--mono);
      font-size: 12px;
      white-space: pre-wrap;
      word-break: break-word;
    }

    .badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 4px 8px;
      border-radius: 999px;
      border: 1px solid var(--border);
      font-size: 12px;
      user-select: none;
    }
    .badge.ok { border-color: color-mix(in srgb, var(--ok) 35%, var(--border)); color: var(--ok); }
    .badge.bad { border-color: color-mix(in srgb, var(--danger) 35%, var(--border)); color: var(--danger); }

    .hint { font-size: 12px; color: var(--muted); margin-top: 8px; }
    .mini { font-size: 12px; }

    .split {
      display: grid;
      grid-template-columns: 1fr;
      gap: 12px;
    }
    @media (min-width: 860px){
      .split { grid-template-columns: 1fr 1fr; }
    }

    .list {
      display: grid;
      gap: 8px;
    }

    .noteItem {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 8px;
      border: 1px solid var(--border);
      border-radius: 10px;
      cursor: pointer;
      background: color-mix(in srgb, var(--card) 92%, transparent);
    }
    .noteItem.active {
      border-color: color-mix(in srgb, var(--accent) 45%, var(--border));
      box-shadow: 0 0 0 3px color-mix(in srgb, var(--accent) 15%, transparent);
    }
    .noteTitle { font-weight: 600; }
    .noteMeta { color: var(--muted); font-size: 12px; }

    .footer {
      text-align: center;
      padding: 18px;
      color: var(--muted);
      font-size: 12px;
    }

    .kbd {
      font-family: var(--mono);
      font-size: 12px;
      padding: 2px 6px;
      border-radius: 6px;
      border: 1px solid var(--border);
      background: color-mix(in srgb, var(--bg) 50%, transparent);
    }
  </style>
</head>

<body>
  <div class="app" id="appRoot">
    <header>
      <div class="brand">
        <h1>妈.妈</h1>
        <div class="tag">local toolbox · xn--hvs.xn--hvs</div>
      </div>

      <div class="topActions">
        <div class="pill">
          <span id="pillClock">—</span>
          <span class="badge" id="pillOnline">—</span>
        </div>

        <button id="btnTheme" title="Toggle theme (Alt+T)">Theme</button>
        <button id="btnFontDown" title="Font smaller">A−</button>
        <button id="btnFontUp" title="Font bigger">A+</button>
        <button id="btnExportAll" class="primary" title="Export notes + settings">Export</button>
        <button id="btnImportAll" title="Import notes + settings">Import</button>
        <input id="fileImportAll" type="file" accept="application/json" style="display:none" />
      </div>
    </header>

    <div class="tabs" id="tabs"></div>

    <main>
      <div class="wrap" id="view"></div>
    </main>

    <div class="footer">
      Runs on your machine · No tracking · Keyboard: <span class="kbd">Alt+1…6</span> switch tabs, <span class="kbd">Alt+T</span> theme, <span class="kbd">/</span> focus search (where available)
    </div>
  </div>

<script>
/* ===========================
   Storage + helpers
=========================== */
const STORE_KEY = "mama_toolbox_v1";

function nowMs(){ return Date.now(); }
function fmtDate(ms){ return new Date(ms).toLocaleString(); }

function safeJsonParse(s){
  try { return { ok:true, val: JSON.parse(s) }; } catch(e){ return { ok:false, err:String(e) }; }
}

function saveState(state){
  localStorage.setItem(STORE_KEY, JSON.stringify(state));
}

function loadState(){
  const raw = localStorage.getItem(STORE_KEY);
  if(!raw) return null;
  const p = safeJsonParse(raw);
  return p.ok ? p.val : null;
}

function uid(){
  if (crypto?.randomUUID) return crypto.randomUUID();
  // fallback
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, c => {
    const r = (crypto.getRandomValues(new Uint8Array(1))[0] & 15) >> 0;
    const v = c === "x" ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

function clamp(n, a, b){ return Math.max(a, Math.min(b, n)); }
function $el(tag, attrs={}, children=[]){
  const e = document.createElement(tag);
  for (const [k,v] of Object.entries(attrs)){
    if(k === "class") e.className = v;
    else if(k === "html") e.innerHTML = v;
    else if(k.startsWith("on") && typeof v === "function") e.addEventListener(k.slice(2), v);
    else e.setAttribute(k, v);
  }
  for (const ch of children) e.appendChild(ch);
  return e;
}
function text(s){ return document.createTextNode(String(s)); }
function copyToClipboard(s){
  navigator.clipboard?.writeText(String(s)).catch(()=>{});
}

/* ===========================
   Punycode (RFC 3492) minimal encode/decode
   (self-contained implementation)
=========================== */
const punycode = (() => {
  const maxInt = 2147483647;
  const base = 36;
  const tMin = 1;
  const tMax = 26;
  const skew = 38;
  const damp = 700;
  const initialBias = 72;
  const initialN = 128;
  const delimiter = "-";

  const regexNonASCII = /[^\x20-\x7E]/;
  const regexSeparators = /[\x2E\u3002\uFF0E\uFF61]/g;

  function ucs2decode(str){
    const output = [];
    for (let i = 0; i < str.length; i++){
      const value = str.charCodeAt(i);
      if (value >= 0xD800 && value <= 0xDBFF && i + 1 < str.length){
        const extra = str.charCodeAt(i + 1);
        if ((extra & 0xFC00) === 0xDC00){
          output.push(((value & 0x3FF) << 10) + (extra & 0x3FF) + 0x10000);
          i++;
          continue;
        }
      }
      output.push(value);
    }
    return output;
  }

  function ucs2encode(arr){
    return arr.map(value => {
      if (value > 0xFFFF){
        value -= 0x10000;
        return String.fromCharCode((value >>> 10) + 0xD800) + String.fromCharCode((value & 0x3FF) + 0xDC00);
      }
      return String.fromCharCode(value);
    }).join("");
  }

  function basicToDigit(codePoint){
    if (codePoint - 48 < 10) return codePoint - 22;
    if (codePoint - 65 < 26) return codePoint - 65;
    if (codePoint - 97 < 26) return codePoint - 97;
    return base;
  }

  function digitToBasic(digit){
    // 0..25 -> a..z, 26..35 -> 0..9
    return digit + 22 + 75 * (digit < 26) - ((digit < 26) ? 0 : 15);
  }

  function adapt(delta, numPoints, firstTime){
    delta = firstTime ? Math.floor(delta / damp) : (delta >> 1);
    delta += Math.floor(delta / numPoints);
    let k = 0;
    while (delta > (((base - tMin) * tMax) >> 1)){
      delta = Math.floor(delta / (base - tMin));
      k += base;
    }
    return k + Math.floor(((base - tMin + 1) * delta) / (delta + skew));
  }

  function encode(input){
    const output = [];
    input = String(input);
    const inputCodePoints = ucs2decode(input);

    let n = initialN;
    let delta = 0;
    let bias = initialBias;

    for (const currentValue of inputCodePoints){
      if (currentValue < 0x80) output.push(String.fromCharCode(currentValue));
    }

    let basicLength = output.length;
    let handledCPCount = basicLength;

    if (basicLength) output.push(delimiter);

    while (handledCPCount < inputCodePoints.length){
      let m = maxInt;
      for (const currentValue of inputCodePoints){
        if (currentValue >= n && currentValue < m) m = currentValue;
      }

      const handledCPCountPlusOne = handledCPCount + 1;
      if (m - n > Math.floor((maxInt - delta) / handledCPCountPlusOne)) throw new RangeError("punycode overflow");

      delta += (m - n) * handledCPCountPlusOne;
      n = m;

      for (const currentValue of inputCodePoints){
        if (currentValue < n){
          delta++;
          if (delta > maxInt) throw new RangeError("punycode overflow");
        }

        if (currentValue === n){
          let q = delta;
          for (let k = base; ; k += base){
            const t = k <= bias ? tMin : (k >= bias + tMax ? tMax : k - bias);
            if (q < t) break;
            const code = t + ((q - t) % (base - t));
            output.push(String.fromCharCode(digitToBasic(code)));
            q = Math.floor((q - t) / (base - t));
          }

          output.push(String.fromCharCode(digitToBasic(q)));
          bias = adapt(delta, handledCPCountPlusOne, handledCPCount === basicLength);
          delta = 0;
          handledCPCount++;
        }
      }

      delta++;
      n++;
    }

    return output.join("");
  }

  function decode(input){
    input = String(input);
    const output = [];

    const inputLength = input.length;
    let n = initialN;
    let i = 0;
    let bias = initialBias;

    let basic = input.lastIndexOf(delimiter);
    if (basic < 0) basic = 0;

    for (let j = 0; j < basic; j++){
      const c = input.charCodeAt(j);
      if (c >= 0x80) throw new RangeError("punycode bad input");
      output.push(c);
    }

    for (let index = basic > 0 ? basic + 1 : 0; index < inputLength; ){
      const oldi = i;
      let w = 1;

      for (let k = base; ; k += base){
        if (index >= inputLength) throw new RangeError("punycode bad input");
        const digit = basicToDigit(input.charCodeAt(index++));
        if (digit >= base) throw new RangeError("punycode bad input");
        if (digit > Math.floor((maxInt - i) / w)) throw new RangeError("punycode overflow");
        i += digit * w;

        const t = k <= bias ? tMin : (k >= bias + tMax ? tMax : k - bias);
        if (digit < t) break;
        const baseMinusT = base - t;
        if (w > Math.floor(maxInt / baseMinusT)) throw new RangeError("punycode overflow");
        w *= baseMinusT;
      }

      const outLen = output.length + 1;
      bias = adapt(i - oldi, outLen, oldi === 0);
      const nPlus = Math.floor(i / outLen);
      if (nPlus > maxInt - n) throw new RangeError("punycode overflow");
      n += nPlus;
      i = i % outLen;
      output.splice(i, 0, n);
      i++;
    }

    return ucs2encode(output);
  }

  function toASCII(domain){
    domain = String(domain).replace(regexSeparators, ".");
    return domain.split(".").map(label => {
      return regexNonASCII.test(label) ? "xn--" + encode(label) : label;
    }).join(".");
  }

  function toUnicode(domain){
    domain = String(domain).replace(regexSeparators, ".");
    return domain.split(".").map(label => {
      if (label.toLowerCase().startsWith("xn--")){
        const core = label.slice(4);
        try { return decode(core); } catch { return label; }
      }
      return label;
    }).join(".");
  }

  return { encode, decode, toASCII, toUnicode };
})();

/* ===========================
   Base64 UTF-8 safe
=========================== */
function b64EncodeUtf8(str){
  const bytes = new TextEncoder().encode(str);
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin);
}
function b64DecodeUtf8(b64){
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i=0;i<bin.length;i++) bytes[i] = bin.charCodeAt(i);
  return new TextDecoder().decode(bytes);
}

/* ===========================
   Hashes (WebCrypto + MD5 fallback)
=========================== */
async function digestHex(algo, msg){
  const data = new TextEncoder().encode(msg);
  const buf = await crypto.subtle.digest(algo, data);
  const arr = Array.from(new Uint8Array(buf));
  return arr.map(b => b.toString(16).padStart(2, "0")).join("");
}

// MD5 (compact JS implementation)
function md5(str){
  function cmn(q, a, b, x, s, t){
    a = (a + q + x + t) | 0;
    return (((a << s) | (a >>> (32 - s))) + b) | 0;
  }
  function ff(a, b, c, d, x, s, t){ return cmn((b & c) | (~b & d), a, b, x, s, t); }
  function gg(a, b, c, d, x, s, t){ return cmn((b & d) | (c & ~d), a, b, x, s, t); }
  function hh(a, b, c, d, x, s, t){ return cmn(b ^ c ^ d, a, b, x, s, t); }
  function ii(a, b, c, d, x, s, t){ return cmn(c ^ (b | ~d), a, b, x, s, t); }

  function toWords(input){
    const bytes = new TextEncoder().encode(input);
    const len = bytes.length;
    const words = [];
    for (let i=0;i<len;i++) words[i>>2] |= bytes[i] << ((i%4)*8);
    words[len>>2] |= 0x80 << ((len%4)*8);
    words[(((len + 8) >>> 6) << 4) + 14] = len * 8;
    return words;
  }
  function toHex(num){
    let s = "";
    for (let j=0;j<4;j++) s += ((num >> (j*8)) & 0xFF).toString(16).padStart(2,"0");
    return s;
  }

  const x = toWords(str);
  let a = 1732584193, b = -271733879, c = -1732584194, d = 271733878;

  for (let i=0;i<x.length;i+=16){
    const oa=a, ob=b, oc=c, od=d;

    a = ff(a,b,c,d, x[i+0], 7, -680876936);
    d = ff(d,a,b,c, x[i+1],12, -389564586);
    c = ff(c,d,a,b, x[i+2],17,  606105819);
    b = ff(b,c,d,a, x[i+3],22, -1044525330);
    a = ff(a,b,c,d, x[i+4], 7, -176418897);
    d = ff(d,a,b,c, x[i+5],12,  1200080426);
    c = ff(c,d,a,b, x[i+6],17, -1473231341);
    b = ff(b,c,d,a, x[i+7],22, -45705983);
    a = ff(a,b,c,d, x[i+8], 7,  1770035416);
    d = ff(d,a,b,c, x[i+9],12, -1958414417);
    c = ff(c,d,a,b, x[i+10],17, -42063);
    b = ff(b,c,d,a, x[i+11],22, -1990404162);
    a = ff(a,b,c,d, x[i+12], 7,  1804603682);
    d = ff(d,a,b,c, x[i+13],12, -40341101);
    c = ff(c,d,a,b, x[i+14],17, -1502002290);
    b = ff(b,c,d,a, x[i+15],22,  1236535329);

    a = gg(a,b,c,d, x[i+1], 5, -165796510);
    d = gg(d,a,b,c, x[i+6], 9, -1069501632);
    c = gg(c,d,a,b, x[i+11],14,  643717713);
    b = gg(b,c,d,a, x[i+0],20, -373897302);
    a = gg(a,b,c,d, x[i+5], 5, -701558691);
    d = gg(d,a,b,c, x[i+10], 9,  38016083);
    c = gg(c,d,a,b, x[i+15],14, -660478335);
    b = gg(b,c,d,a, x[i+4],20, -405537848);
    a = gg(a,b,c,d, x[i+9], 5,  568446438);
    d = gg(d,a,b,c, x[i+14], 9, -1019803690);
    c = gg(c,d,a,b, x[i+3],14, -187363961);
    b = gg(b,c,d,a, x[i+8],20,  1163531501);
    a = gg(a,b,c,d, x[i+13], 5, -1444681467);
    d = gg(d,a,b,c, x[i+2], 9, -51403784);
    c = gg(c,d,a,b, x[i+7],14,  1735328473);
    b = gg(b,c,d,a, x[i+12],20, -1926607734);

    a = hh(a,b,c,d, x[i+5], 4, -378558);
    d = hh(d,a,b,c, x[i+8],11, -2022574463);
    c = hh(c,d,a,b, x[i+11],16,  1839030562);
    b = hh(b,c,d,a, x[i+14],23, -35309556);
    a = hh(a,b,c,d, x[i+1], 4, -1530992060);
    d = hh(d,a,b,c, x[i+4],11,  1272893353);
    c = hh(c,d,a,b, x[i+7],16, -155497632);
    b = hh(b,c,d,a, x[i+10],23, -1094730640);
    a = hh(a,b,c,d, x[i+13], 4,  681279174);
    d = hh(d,a,b,c, x[i+0],11, -358537222);
    c = hh(c,d,a,b, x[i+3],16, -722521979);
    b = hh(b,c,d,a, x[i+6],23,  76029189);
    a = hh(a,b,c,d, x[i+9], 4, -640364487);
    d = hh(d,a,b,c, x[i+12],11, -421815835);
    c = hh(c,d,a,b, x[i+15],16,  530742520);
    b = hh(b,c,d,a, x[i+2],23, -995338651);

    a = ii(a,b,c,d, x[i+0], 6, -198630844);
    d = ii(d,a,b,c, x[i+7],10,  1126891415);
    c = ii(c,d,a,b, x[i+14],15, -1416354905);
    b = ii(b,c,d,a, x[i+5],21, -57434055);
    a = ii(a,b,c,d, x[i+12], 6,  1700485571);
    d = ii(d,a,b,c, x[i+3],10, -1894986606);
    c = ii(c,d,a,b, x[i+10],15, -1051523);
    b = ii(b,c,d,a, x[i+1],21, -2054922799);
    a = ii(a,b,c,d, x[i+8], 6,  1873313359);
    d = ii(d,a,b,c, x[i+15],10, -30611744);
    c = ii(c,d,a,b, x[i+6],15, -1560198380);
    b = ii(b,c,d,a, x[i+13],21,  1309151649);
    a = ii(a,b,c,d, x[i+4], 6, -145523070);
    d = ii(d,a,b,c, x[i+11],10, -1120210379);
    c = ii(c,d,a,b, x[i+2],15,  718787259);
    b = ii(b,c,d,a, x[i+9],21, -343485551);

    a = (a + oa) | 0;
    b = (b + ob) | 0;
    c = (c + oc) | 0;
    d = (d + od) | 0;
  }
  return (toHex(a) + toHex(b) + toHex(c) + toHex(d));
}

/* ===========================
   App state model
=========================== */
const defaultState = {
  theme: "light",
  fontScale: 1,
  activeTab: "home",
  activeSub: {
    tools: "puny",
    daily: "timer",
    notes: "notes",
    network: "status"
  },
  notes: {
    activeId: null,
    items: [] // {id,title,body,created,updated}
  }
};

let state = (() => {
  const s = loadState();
  if (!s || typeof s !== "object") return structuredClone(defaultState);
  // merge shallow
  const merged = structuredClone(defaultState);
  Object.assign(merged, s);
  merged.activeSub = Object.assign({}, defaultState.activeSub, s.activeSub || {});
  merged.notes = Object.assign({}, defaultState.notes, s.notes || {});
  merged.notes.items = Array.isArray(merged.notes.items) ? merged.notes.items : [];
  return merged;
})();

function persist(){
  saveState(state);
}

function setTheme(theme){
  state.theme = theme;
  document.documentElement.setAttribute("data-theme", theme);
  persist();
}

function setFontScale(scale){
  state.fontScale = clamp(scale, 0.85, 1.35);
  document.documentElement.style.setProperty("--fontScale", String(state.fontScale));
  persist();
}

/* ===========================
   Tabs registry
=========================== */
const TAB_ORDER = ["home","tools","daily","notes","network","about"];
const TAB_META = {
  home:   { title:"Home" },
  tools:  { title:"Tools" },
  daily:  { title:"Daily" },
  notes:  { title:"Notes" },
  network:{ title:"Network" },
  about:  { title:"About" }
};

function renderTabs(){
  const tabs = document.getElementById("tabs");
  tabs.innerHTML = "";
  TAB_ORDER.forEach((id, idx) => {
    const b = $el("button", {
      class: "tabBtn" + (state.activeTab === id ? " active":""),
      onclick: () => { state.activeTab = id; persist(); render(); },
      title: `Switch tab (Alt+${idx+1})`
    }, [text(TAB_META[id].title)]);
    tabs.appendChild(b);
  });
}

function setSub(tab, sub){
  state.activeSub[tab] = sub;
  persist();
  render();
}

function subButton(tab, sub, label){
  return $el("button", {
    class: "subBtn" + (state.activeSub[tab] === sub ? " active" : ""),
    onclick: () => setSub(tab, sub)
  }, [text(label)]);
}

function renderSubtabs(tab, items){
  const row = $el("div", { class:"subtabs" });
  items.forEach(([sub, label]) => row.appendChild(subButton(tab, sub, label)));
  return row;
}

/* ===========================
   UI components
=========================== */
function card(title, bodyNode, extraTopNode=null){
  const h = $el("h2", {}, [text(title)]);
  const c = $el("div", { class:"card" }, extraTopNode ? [h, extraTopNode, bodyNode] : [h, bodyNode]);
  return c;
}

function kv(pairs){
  const root = $el("div", { class:"kv" });
  for (const [k,v] of pairs){
    root.appendChild($el("b", {}, [text(k)]));
    if (v instanceof Node) root.appendChild(v);
    else root.appendChild($el("div", {}, [text(v)]));
  }
  return root;
}

function hr(){
  return $el("div", { style:"height:1px;background:var(--border);margin:12px 0;" });
}

/* ===========================
   Home tab
=========================== */
function viewHome(){
  const host = location.hostname || "(no host)";
  const unicodeHost = punycode.toUnicode(host);
  const asciiHost = punycode.toASCII(unicodeHost);

  const top = $el("div", { class:"grid two" });

  top.appendChild(card("Status", $el("div", {}, [
    kv([
      ["Host (raw)", host],
      ["Host (Unicode)", unicodeHost],
      ["Host (ASCII)", asciiHost],
      ["Protocol", location.protocol || "-"],
      ["Path", location.pathname || "/"],
    ]),
    $el("div", { class:"hint" }, [
      text("Tip: your DNS override must answer A/AAAA for "),
      $el("span", { class:"kbd" }, [text("xn--hvs.xn--hvs")]),
      text(" for browser to hit localhost without tricks.")
    ])
  ])));

  top.appendChild(card("Quick actions", $el("div", { class:"row" }, [
    $el("button", { class:"primary", onclick: ()=>{ state.activeTab="tools"; persist(); render(); } }, [text("Open Tools")]),
    $el("button", { onclick: ()=>{ state.activeTab="daily"; persist(); render(); } }, [text("Open Daily")]),
    $el("button", { onclick: ()=>{ state.activeTab="notes"; persist(); render(); } }, [text("Open Notes")]),
    $el("button", { onclick: ()=>copyToClipboard(location.href) }, [text("Copy URL")]),
  ]), $el("div", { class:"hint" }, [
    text("Keyboard: "),
    $el("span", { class:"kbd" }, [text("Alt+1…6")]),
    text(" tabs · "),
    $el("span", { class:"kbd" }, [text("Alt+T")]),
    text(" theme")
  ])));

  const bottom = $el("div", { class:"grid two" });

  bottom.appendChild(card("Local commands", $el("div", {}, [
    $el("pre", { id:"homeCmd" }, [text(
`# Verify local DNS (examples)
dig xn--hvs.xn--hvs A
dig xn--hvs.xn--hvs AAAA

# Force override test (no DNS)
curl --resolve xn--hvs.xn--hvs:80:127.0.0.1 http://xn--hvs.xn--hvs

# Serve this folder
python3 -m http.server 80 --bind ::`
    )])
  ])));

  bottom.appendChild(card("System snapshot", $el("div", {}, [
    kv([
      ["Online", navigator.onLine ? "Yes" : "No"],
      ["Platform", navigator.platform || "-"],
      ["Cores", navigator.hardwareConcurrency || "-"],
      ["Memory (approx)", navigator.deviceMemory ? `${navigator.deviceMemory} GB` : "—"],
      ["Language", navigator.language || "-"],
    ]),
    hr(),
    $el("div", { class:"mini muted" }, [text("User-Agent")]),
    $el("pre", {}, [text(navigator.userAgent)])
  ])));

  return $el("div", { class:"wrap" }, [top, bottom]);
}

/* ===========================
   Tools tab
=========================== */
function viewTools(){
  const subtabs = renderSubtabs("tools", [
    ["puny","Punycode"],
    ["json","JSON"],
    ["url","URL"],
    ["b64","Base64"],
    ["hash","Hash"],
    ["uuid","UUID + Password"]
  ]);

  let body;
  const sub = state.activeSub.tools;

  if (sub === "puny") body = toolsPuny();
  else if (sub === "json") body = toolsJson();
  else if (sub === "url") body = toolsUrl();
  else if (sub === "b64") body = toolsBase64();
  else if (sub === "hash") body = toolsHash();
  else body = toolsUuidPass();

  return $el("div", { class:"wrap" }, [
    card("Tools", body, subtabs)
  ]);
}

function toolsPuny(){
  const input = $el("input", { type:"text", id:"punyIn", placeholder:"Enter domain: 妈.妈 or xn--hvs.xn--hvs" });
  const outU = $el("pre", { id:"punyOutU" }, [text("—")]);
  const outA = $el("pre", { id:"punyOutA" }, [text("—")]);

  const btn = $el("button", { class:"primary", onclick: () => {
    const v = input.value.trim();
    if (!v){ outU.textContent="—"; outA.textContent="—"; return; }
    outU.textContent = punycode.toUnicode(v);
    outA.textContent = punycode.toASCII(v);
  }}, [text("Convert")]);

  const btnCopyU = $el("button", { onclick: ()=>copyToClipboard(outU.textContent) }, [text("Copy Unicode")]);
  const btnCopyA = $el("button", { onclick: ()=>copyToClipboard(outA.textContent) }, [text("Copy ASCII")]);

  return $el("div", { class:"grid two" }, [
    $el("div", { class:"card", style:"box-shadow:none" }, [
      $el("h3", {}, [text("Input")]),
      input,
      $el("div", { class:"row", style:"margin-top:10px" }, [btn, $el("div",{class:"spacer"}), btnCopyU, btnCopyA]),
      $el("div", { class:"hint" }, [text("Works per-label (.) as well. Handles xn-- prefixes automatically.")])
    ]),
    $el("div", { class:"card", style:"box-shadow:none" }, [
      $el("h3", {}, [text("Output")]),
      $el("div", { class:"mini muted" }, [text("Unicode")]),
      outU,
      $el("div", { style:"height:8px" }),
      $el("div", { class:"mini muted" }, [text("ASCII (punycode)")]),
      outA
    ])
  ]);
}

function toolsJson(){
  const input = $el("textarea", { id:"jsonIn", placeholder:"Paste JSON here..." });
  const out = $el("textarea", { id:"jsonOut", placeholder:"Formatted JSON / error..." });

  const btnFmt = $el("button", { class:"primary", onclick: () => {
    const p = safeJsonParse(input.value);
    if (!p.ok){ out.value = "❌ " + p.err; return; }
    out.value = JSON.stringify(p.val, null, 2);
  }}, [text("Format")]);

  const btnMin = $el("button", { onclick: () => {
    const p = safeJsonParse(input.value);
    if (!p.ok){ out.value = "❌ " + p.err; return; }
    out.value = JSON.stringify(p.val);
  }}, [text("Minify")]);

  const btnCopy = $el("button", { onclick: ()=>copyToClipboard(out.value) }, [text("Copy output")]);

  return $el("div", { class:"split" }, [
    $el("div", { class:"card", style:"box-shadow:none" }, [
      $el("h3", {}, [text("Input")]),
      input,
      $el("div", { class:"row", style:"margin-top:10px" }, [btnFmt, btnMin, $el("div",{class:"spacer"}), $el("button",{onclick:()=>input.value=""},[text("Clear")])]),
    ]),
    $el("div", { class:"card", style:"box-shadow:none" }, [
      $el("h3", {}, [text("Output")]),
      out,
      $el("div", { class:"row", style:"margin-top:10px" }, [
        btnCopy,
        $el("div",{class:"spacer"}),
        $el("button",{onclick:()=>out.value=""},[text("Clear")])
      ])
    ])
  ]);
}

function toolsUrl(){
  const input = $el("textarea", { id:"urlIn", placeholder:"Text or URL..." });
  const out = $el("textarea", { id:"urlOut", placeholder:"Output..." });

  const btnEnc = $el("button", { class:"primary", onclick:()=>{ out.value = encodeURIComponent(input.value); } }, [text("encodeURIComponent")]);
  const btnDec = $el("button", { onclick:()=>{ try{ out.value = decodeURIComponent(input.value); }catch(e){ out.value = "❌ " + e; } } }, [text("decodeURIComponent")]);
  const btnEsc = $el("button", { onclick:()=>{ out.value = encodeURI(input.value); } }, [text("encodeURI")]);
  const btnUnesc = $el("button", { onclick:()=>{ try{ out.value = decodeURI(input.value); }catch(e){ out.value = "❌ " + e; } } }, [text("decodeURI")]);

  const btnCopy = $el("button", { onclick:()=>copyToClipboard(out.value) }, [text("Copy output")]);

  return $el("div", { class:"split" }, [
    $el("div", { class:"card", style:"box-shadow:none" }, [
      $el("h3", {}, [text("Input")]),
      input,
      $el("div",{class:"row",style:"margin-top:10px"},[
        btnEnc, btnDec, btnEsc, btnUnesc, $el("div",{class:"spacer"}), $el("button",{onclick:()=>input.value=""},[text("Clear")])
      ]),
    ]),
    $el("div", { class:"card", style:"box-shadow:none" }, [
      $el("h3", {}, [text("Output")]),
      out,
      $el("div",{class:"row",style:"margin-top:10px"},[
        btnCopy, $el("div",{class:"spacer"}), $el("button",{onclick:()=>out.value=""},[text("Clear")])
      ]),
      $el("div",{class:"hint"},[text("Tip: for query strings, use encodeURIComponent for each value, not the whole URL.")])
    ])
  ]);
}

function toolsBase64(){
  const input = $el("textarea", { id:"b64In", placeholder:"Text or base64..." });
  const out = $el("textarea", { id:"b64Out", placeholder:"Output..." });

  const btnEnc = $el("button", { class:"primary", onclick:()=>{
    try { out.value = b64EncodeUtf8(input.value); } catch(e){ out.value = "❌ " + e; }
  }}, [text("Encode UTF-8")]);

  const btnDec = $el("button", { onclick:()=>{
    try { out.value = b64DecodeUtf8(input.value.trim()); } catch(e){ out.value = "❌ " + e; }
  }}, [text("Decode UTF-8")]);

  const btnCopy = $el("button", { onclick:()=>copyToClipboard(out.value) }, [text("Copy output")]);

  return $el("div", { class:"split" }, [
    $el("div", { class:"card", style:"box-shadow:none" }, [
      $el("h3", {}, [text("Input")]),
      input,
      $el("div",{class:"row",style:"margin-top:10px"},[
        btnEnc, btnDec, $el("div",{class:"spacer"}), $el("button",{onclick:()=>input.value=""},[text("Clear")])
      ]),
    ]),
    $el("div", { class:"card", style:"box-shadow:none" }, [
      $el("h3", {}, [text("Output")]),
      out,
      $el("div",{class:"row",style:"margin-top:10px"},[
        btnCopy, $el("div",{class:"spacer"}), $el("button",{onclick:()=>out.value=""},[text("Clear")])
      ])
    ])
  ]);
}

function toolsHash(){
  const input = $el("textarea", { id:"hashIn", placeholder:"Message to hash..." });
  const out = $el("pre", { id:"hashOut" }, [text("—")]);

  const sel = $el("select", { id:"hashAlgo" }, [
    $el("option",{value:"SHA-256"},[text("SHA-256 (WebCrypto)")]),
    $el("option",{value:"SHA-1"},[text("SHA-1 (WebCrypto)")]),
    $el("option",{value:"SHA-384"},[text("SHA-384 (WebCrypto)")]),
    $el("option",{value:"SHA-512"},[text("SHA-512 (WebCrypto)")]),
    $el("option",{value:"MD5"},[text("MD5 (JS)")]),
  ]);

  const btn = $el("button", { class:"primary", onclick: async ()=>{
    const msg = input.value;
    const algo = sel.value;
    try {
      if (algo === "MD5") out.textContent = md5(msg);
      else out.textContent = await digestHex(algo, msg);
    } catch(e){
      out.textContent = "❌ " + e;
    }
  }}, [text("Hash")]);

  const btnCopy = $el("button", { onclick: ()=>copyToClipboard(out.textContent) }, [text("Copy")]);

  return $el("div", { class:"grid two" }, [
    $el("div", { class:"card", style:"box-shadow:none" }, [
      $el("h3", {}, [text("Input")]),
      input,
      $el("div",{class:"row",style:"margin-top:10px"},[
        sel, btn, $el("div",{class:"spacer"}), $el("button",{onclick:()=>input.value=""},[text("Clear")])
      ]),
    ]),
    $el("div", { class:"card", style:"box-shadow:none" }, [
      $el("h3", {}, [text("Output (hex)")]),
      out,
      $el("div",{class:"row",style:"margin-top:10px"},[
        btnCopy,
        $el("div",{class:"spacer"}),
        $el("button",{onclick:()=>out.textContent="—"},[text("Clear")])
      ]),
      $el("div",{class:"hint"},[text("MD5 is included mainly for interoperability with old tooling.")])
    ])
  ]);
}

function toolsUuidPass(){
  const uuidOut = $el("pre", { id:"uuidOut" }, [text("—")]);
  const btnUuid = $el("button", { class:"primary", onclick:()=>{ uuidOut.textContent = uid(); } }, [text("Generate UUID")]);
  const btnUuidCopy = $el("button", { onclick:()=>copyToClipboard(uuidOut.textContent) }, [text("Copy")]);

  const len = $el("input", { type:"number", min:"6", max:"128", value:"20", id:"passLen" });
  const passOut = $el("pre", { id:"passOut" }, [text("—")]);
  const chk1 = $el("input", { type:"checkbox", id:"passUpper", checked:"checked" });
  const chk2 = $el("input", { type:"checkbox", id:"passLower", checked:"checked" });
  const chk3 = $el("input", { type:"checkbox", id:"passNum", checked:"checked" });
  const chk4 = $el("input", { type:"checkbox", id:"passSym" });

  function genPass(){
    const n = clamp(parseInt(len.value || "20", 10), 6, 128);
    const U="ABCDEFGHIJKLMNOPQRSTUVWXYZ", L="abcdefghijklmnopqrstuvwxyz", N="0123456789", S="!@#$%^&*()-_=+[]{};:,.<>/?";
    let chars = "";
    if (chk1.checked) chars += U;
    if (chk2.checked) chars += L;
    if (chk3.checked) chars += N;
    if (chk4.checked) chars += S;
    if (!chars) { passOut.textContent = "❌ choose at least 1 character set"; return; }

    const buf = new Uint32Array(n);
    crypto.getRandomValues(buf);
    let out = "";
    for (let i=0;i<n;i++) out += chars[buf[i] % chars.length];
    passOut.textContent = out;
  }

  return $el("div", { class:"grid two" }, [
    $el("div", { class:"card", style:"box-shadow:none" }, [
      $el("h3", {}, [text("UUID")]),
      uuidOut,
      $el("div",{class:"row",style:"margin-top:10px"},[btnUuid, btnUuidCopy])
    ]),
    $el("div", { class:"card", style:"box-shadow:none" }, [
      $el("h3", {}, [text("Password generator")]),
      $el("div",{class:"row"},[
        $el("div",{style:"min-width:130px"},[text("Length")]),
        len
      ]),
      $el("div",{class:"row",style:"margin-top:8px"},[
        $el("label",{class:"row",style:"gap:6px"},[chk1,text("Upper")]),
        $el("label",{class:"row",style:"gap:6px"},[chk2,text("Lower")]),
        $el("label",{class:"row",style:"gap:6px"},[chk3,text("Numbers")]),
        $el("label",{class:"row",style:"gap:6px"},[chk4,text("Symbols")]),
      ]),
      $el("div",{style:"height:8px"}),
      passOut,
      $el("div",{class:"row",style:"margin-top:10px"},[
        $el("button",{class:"primary",onclick:genPass},[text("Generate")]),
        $el("button",{onclick:()=>copyToClipboard(passOut.textContent)},[text("Copy")]),
      ]),
      $el("div",{class:"hint"},[text("Generated locally using crypto.getRandomValues().")])
    ])
  ]);
}

/* ===========================
   Daily tab (stopwatch, timer, timestamp, calculator)
=========================== */
let sw = { running:false, t0:0, acc:0, lap:[] };
let timer = { running:false, end:0, tick:null };

function viewDaily(){
  const subtabs = renderSubtabs("daily", [
    ["timer","Stopwatch + Timer"],
    ["time","Timestamps"],
    ["calc","Calculator"]
  ]);
  const sub = state.activeSub.daily;
  let body = (sub === "timer") ? dailyTimer()
           : (sub === "time")  ? dailyTimestamps()
           : dailyCalc();

  return $el("div", { class:"wrap" }, [
    card("Daily", body, subtabs)
  ]);
}

function msToHMS(ms){
  const neg = ms < 0;
  ms = Math.abs(ms);
  const h = Math.floor(ms / 3600000);
  ms -= h*3600000;
  const m = Math.floor(ms / 60000);
  ms -= m*60000;
  const s = Math.floor(ms / 1000);
  const cs = Math.floor((ms - s*1000) / 10); // centiseconds
  const out = (h>0 ? String(h).padStart(2,"0")+":" : "") +
              String(m).padStart(2,"0")+":"+
              String(s).padStart(2,"0")+"."+
              String(cs).padStart(2,"0");
  return neg ? "-" + out : out;
}

function dailyTimer(){
  const swOut = $el("pre", { id:"swOut" }, [text("00:00.00")]);
  const laps = $el("pre", { id:"swLaps" }, [text("—")]);

  function renderSw(){
    const ms = sw.running ? (nowMs() - sw.t0 + sw.acc) : sw.acc;
    swOut.textContent = msToHMS(ms);
    if (sw.lap.length){
      laps.textContent = sw.lap.map((x,i)=>`${String(i+1).padStart(2,"0")}. ${msToHMS(x)}`).join("\n");
    } else laps.textContent = "—";
  }

  const btnStart = $el("button", { class:"primary", onclick:()=>{
    if (!sw.running){
      sw.running = true;
      sw.t0 = nowMs();
    }
    renderSw();
  }}, [text("Start")]);

  const btnStop = $el("button", { onclick:()=>{
    if (sw.running){
      sw.acc += nowMs() - sw.t0;
      sw.running = false;
    }
    renderSw();
  }}, [text("Stop")]);

  const btnReset = $el("button", { onclick:()=>{
    sw = { running:false, t0:0, acc:0, lap:[] };
    renderSw();
  }}, [text("Reset")]);

  const btnLap = $el("button", { onclick:()=>{
    const ms = sw.running ? (nowMs() - sw.t0 + sw.acc) : sw.acc;
    if (ms > 0) sw.lap.unshift(ms);
    renderSw();
  }}, [text("Lap")]);

  const tIn = $el("input", { type:"number", min:"1", max:"86400", value:"120", id:"timerSec" });
  const tOut = $el("pre", { id:"timerOut" }, [text("—")]);

  function renderTimer(){
    if (!timer.running){
      tOut.textContent = "—";
      return;
    }
    const left = timer.end - nowMs();
    if (left <= 0){
      timer.running = false;
      clearInterval(timer.tick);
      timer.tick = null;
      tOut.textContent = "✅ Done";
      try { navigator.vibrate?.(200); } catch {}
      return;
    }
    tOut.textContent = msToHMS(left);
  }

  const tStart = $el("button", { class:"primary", onclick:()=>{
    const sec = clamp(parseInt(tIn.value || "60", 10), 1, 86400);
    timer.running = true;
    timer.end = nowMs() + sec*1000;
    if (timer.tick) clearInterval(timer.tick);
    timer.tick = setInterval(renderTimer, 50);
    renderTimer();
  }}, [text("Start")]);

  const tStop = $el("button", { onclick:()=>{
    timer.running = false;
    if (timer.tick) clearInterval(timer.tick);
    timer.tick = null;
    renderTimer();
  }}, [text("Stop")]);

  const tReset = $el("button", { onclick:()=>{
    timer.running = false;
    if (timer.tick) clearInterval(timer.tick);
    timer.tick = null;
    tOut.textContent = "—";
  }}, [text("Reset")]);

  // tick stopwatch display
  const swTick = setInterval(()=> {
    if (state.activeTab !== "daily" || state.activeSub.daily !== "timer") return;
    if (sw.running) renderSw();
    if (timer.running) renderTimer();
  }, 50);

  // ensure cleaned on rerender (lightweight)
  setTimeout(()=>{ clearInterval(swTick); }, 2000);

  return $el("div", { class:"grid two" }, [
    $el("div", { class:"card", style:"box-shadow:none" }, [
      $el("h3", {}, [text("Stopwatch")]),
      swOut,
      $el("div",{class:"row",style:"margin-top:10px"},[btnStart, btnStop, btnLap, btnReset]),
      $el("div",{style:"height:8px"}),
      $el("div",{class:"mini muted"},[text("Laps")]),
      laps
    ]),
    $el("div", { class:"card", style:"box-shadow:none" }, [
      $el("h3", {}, [text("Timer")]),
      $el("div",{class:"row"},[
        $el("div",{style:"min-width:140px"},[text("Seconds")]),
        tIn
      ]),
      $el("div",{style:"height:8px"}),
      tOut,
      $el("div",{class:"row",style:"margin-top:10px"},[tStart, tStop, tReset]),
      $el("div",{class:"hint"},[text("Uses local time only. No notifications — just on-page status + optional vibration.")])
    ])
  ]);
}

function dailyTimestamps(){
  const nowOut = $el("pre", { id:"tsNow" }, [text("—")]);
  const epochOut = $el("pre", { id:"tsEpoch" }, [text("—")]);

  function refreshNow(){
    const ms = nowMs();
    nowOut.textContent = fmtDate(ms);
    epochOut.textContent = `ms: ${ms}\nsec: ${Math.floor(ms/1000)}`;
  }
  refreshNow();
  setInterval(()=>{ if (state.activeTab==="daily" && state.activeSub.daily==="time") refreshNow(); }, 1000);

  const inTs = $el("input", { type:"text", id:"tsIn", placeholder:"Enter epoch seconds or ms (e.g. 1700000000 or 1700000000000)" });
  const out = $el("pre", { id:"tsOut" }, [text("—")]);

  const btn = $el("button", { class:"primary", onclick:()=>{
    const raw = inTs.value.trim();
    if (!raw){ out.textContent = "—"; return; }
    if (!/^\d+$/.test(raw)){ out.textContent = "❌ numbers only"; return; }
    let n = Number(raw);
    if (!Number.isFinite(n)){ out.textContent="❌ invalid number"; return; }
    // heuristic: 10 digits => seconds
    if (raw.length <= 10) n = n * 1000;
    out.textContent = fmtDate(n);
  }}, [text("Convert")]);

  const btnISO = $el("button", { onclick:()=>{
    const d = new Date();
    out.textContent = d.toISOString();
  }}, [text("Now ISO")]);

  return $el("div", { class:"grid two" }, [
    $el("div", { class:"card", style:"box-shadow:none" }, [
      $el("h3", {}, [text("Now")]),
      nowOut,
      $el("div",{style:"height:8px"}),
      $el("div",{class:"mini muted"},[text("Epoch")]),
      epochOut
    ]),
    $el("div", { class:"card", style:"box-shadow:none" }, [
      $el("h3", {}, [text("Convert epoch → date")]),
      inTs,
      $el("div",{class:"row",style:"margin-top:10px"},[btn, btnISO, $el("div",{class:"spacer"}), $el("button",{onclick:()=>{inTs.value="";out.textContent="—";}},[text("Clear")])]),
      $el("div",{style:"height:10px"}),
      out
    ])
  ]);
}

function dailyCalc(){
  const input = $el("input", { type:"text", id:"calcIn", placeholder:"Example: (12+3)*4/5  or  2**10" });
  const out = $el("pre", { id:"calcOut" }, [text("—")]);

  function safeEval(expr){
    // allow digits, operators, whitespace, parentheses, dot, exponent, commas
    // disallow letters to avoid arbitrary JS execution
    if (!/^[0-9+\-*/().,\s%**]+$/.test(expr.replace(/\*\*/g,"**"))) return { ok:false, err:"Only numbers and operators + - * / % ( ) . ** allowed" };
    try {
      // eslint-disable-next-line no-new-func
      const fn = new Function(`"use strict"; return (${expr});`);
      const val = fn();
      if (typeof val !== "number" || !Number.isFinite(val)) return { ok:false, err:"Result is not a finite number" };
      return { ok:true, val };
    } catch(e){
      return { ok:false, err:String(e) };
    }
  }

  const btn = $el("button", { class:"primary", onclick:()=>{
    const expr = input.value.trim();
    if (!expr){ out.textContent="—"; return; }
    const r = safeEval(expr);
    out.textContent = r.ok ? String(r.val) : "❌ " + r.err;
  }}, [text("Compute")]);

  return $el("div", { class:"grid two" }, [
    $el("div", { class:"card", style:"box-shadow:none" }, [
      $el("h3", {}, [text("Expression")]),
      input,
      $el("div",{class:"row",style:"margin-top:10px"},[
        btn,
        $el("button",{onclick:()=>{input.value="";out.textContent="—";}},[text("Clear")]),
        $el("div",{class:"spacer"}),
        $el("button",{onclick:()=>copyToClipboard(out.textContent)},[text("Copy result")])
      ]),
      $el("div",{class:"hint"},[text("Safety: letters are blocked to prevent running arbitrary JS.")])
    ]),
    $el("div", { class:"card", style:"box-shadow:none" }, [
      $el("h3", {}, [text("Result")]),
      out
    ])
  ]);
}

/* ===========================
   Notes tab (multi-note, export/import)
=========================== */
function ensureNote(){
  if (!state.notes.items.length){
    const id = uid();
    const n = { id, title:"Welcome", body:"This is your local scratchpad.\n\n- Create multiple notes\n- Export / Import\n- Everything stays on your machine", created: nowMs(), updated: nowMs() };
    state.notes.items.push(n);
    state.notes.activeId = id;
    persist();
  }
  if (!state.notes.activeId && state.notes.items[0]){
    state.notes.activeId = state.notes.items[0].id;
    persist();
  }
}

function getActiveNote(){
  return state.notes.items.find(x => x.id === state.notes.activeId) || null;
}

function viewNotes(){
  ensureNote();

  const left = $el("div", {});
  const right = $el("div", {});

  const list = $el("div", { class:"list" });
  state.notes.items
    .slice()
    .sort((a,b)=>b.updated - a.updated)
    .forEach(n => {
      const item = $el("div", {
        class:"noteItem" + (n.id === state.notes.activeId ? " active":""),
        onclick:()=>{ state.notes.activeId = n.id; persist(); render(); }
      }, [
        $el("div", {}, [
          $el("div", { class:"noteTitle" }, [text(n.title || "Untitled")]),
          $el("div", { class:"noteMeta" }, [text("Updated: " + fmtDate(n.updated))])
        ]),
        $el("div", { class:"spacer" }),
        $el("button", { onclick:(e)=>{ e.stopPropagation(); copyToClipboard(n.body||""); }, title:"Copy note content" }, [text("Copy")])
      ]);
      list.appendChild(item);
    });

  const btnNew = $el("button", { class:"primary", onclick:()=>{
    const id = uid();
    const t = "New note";
    state.notes.items.push({ id, title:t, body:"", created: nowMs(), updated: nowMs() });
    state.notes.activeId = id;
    persist();
    render();
  }}, [text("New")]);

  const btnExport = $el("button", { onclick: exportAll }, [text("Export")]);
  const btnImport = $el("button", { onclick: ()=>document.getElementById("fileImportAll").click() }, [text("Import")]);

  left.appendChild(card("Notes", $el("div", {}, [
    $el("div", { class:"row" }, [btnNew, btnExport, btnImport]),
    $el("div", { style:"height:10px" }),
    list
  ])));

  const active = getActiveNote();
  const title = $el("input", { type:"text", id:"noteTitle", value: active?.title || "" });
  const body = $el("textarea", { id:"noteBody", placeholder:"Write here...", html:"" });
  body.value = active?.body || "";

  function touch(){
    const n = getActiveNote();
    if (!n) return;
    n.title = title.value;
    n.body = body.value;
    n.updated = nowMs();
    persist();
  }
  title.addEventListener("input", ()=>{ touch(); renderPill(); renderNotesListOnly(); });
  body.addEventListener("input", ()=>{ touch(); });

  const btnDel = $el("button", { class:"danger", onclick:()=>{
    const n = getActiveNote();
    if (!n) return;
    // no confirm popup (you can undo via export if needed)
    state.notes.items = state.notes.items.filter(x => x.id !== n.id);
    state.notes.activeId = state.notes.items[0]?.id || null;
    persist();
    render();
  }}, [text("Delete")]);

  const btnCopy = $el("button", { onclick:()=>copyToClipboard(body.value) }, [text("Copy content")]);

  const btnDup = $el("button", { onclick:()=>{
    const n = getActiveNote();
    if(!n) return;
    const id = uid();
    state.notes.items.push({ id, title:(n.title||"")+" (copy)", body:n.body||"", created: nowMs(), updated: nowMs() });
    state.notes.activeId = id;
    persist();
    render();
  }}, [text("Duplicate")]);

  right.appendChild(card("Editor", $el("div", {}, [
    $el("div",{class:"row"},[
      $el("div",{style:"min-width:60px"},[text("Title")]),
      title
    ]),
    $el("div",{style:"height:10px"}),
    body,
    $el("div",{class:"row",style:"margin-top:10px"},[
      btnCopy, btnDup, $el("div",{class:"spacer"}), btnDel
    ]),
    $el("div",{class:"hint"},[text("Autosaves locally. Export if you want a backup.")])
  ])));

  const wrap = $el("div", { class:"wrap" });
  wrap.appendChild($el("div", { class:"grid two" }, [left, right]));
  return wrap;
}

function renderNotesListOnly(){
  // lightweight: skip; full render is fine for local
}

/* ===========================
   Network tab (safe, local)
=========================== */
async function getLocalIPs(){
  // Best-effort via WebRTC (may be blocked by browser settings)
  const ips = new Set();
  try {
    const pc = new RTCPeerConnection({ iceServers: [] });
    pc.createDataChannel("x");
    const offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    await new Promise((resolve) => {
      const timeout = setTimeout(resolve, 600);
      pc.onicecandidate = (e) => {
        if (!e || !e.candidate) { clearTimeout(timeout); resolve(); return; }
        const cand = e.candidate.candidate;
        const m = cand.match(/(\d{1,3}(\.\d{1,3}){3})|([a-f0-9:]{2,})/i);
        if (m) ips.add(m[0]);
      };
    });
    pc.close();
  } catch {}
  return Array.from(ips);
}

function viewNetwork(){
  const subtabs = renderSubtabs("network", [
    ["status","Status"],
    ["debug","Debug tips"]
  ]);

  const sub = state.activeSub.network;

  let body = (sub === "debug") ? networkDebug() : networkStatus();

  return $el("div", { class:"wrap" }, [
    card("Network", body, subtabs)
  ]);
}

function networkStatus(){
  const host = location.hostname || "(no host)";
  const uni = punycode.toUnicode(host);
  const asc = punycode.toASCII(uni);

  const ipPre = $el("pre", { id:"ipList" }, [text("Loading…")]);
  getLocalIPs().then(ips => {
    ipPre.textContent = ips.length ? ips.join("\n") : "— (blocked or unavailable)";
  });

  const onlineBadge = navigator.onLine
    ? $el("span",{class:"badge ok"},[text("Online")])
    : $el("span",{class:"badge bad"},[text("Offline")]);

  const dnsHint = $el("pre", {}, [text(
`Browser DNS is not directly readable from JS.
Use terminal checks:
dig xn--hvs.xn--hvs A
dig xn--hvs.xn--hvs AAAA

Then:
curl --resolve xn--hvs.xn--hvs:80:127.0.0.1 http://xn--hvs.xn--hvs`
  )]);

  return $el("div", { class:"grid two" }, [
    $el("div", { class:"card", style:"box-shadow:none" }, [
      $el("h3", {}, [text("Browser view")]),
      kv([
        ["Online", onlineBadge],
        ["Hostname (Unicode)", uni],
        ["Hostname (ASCII)", asc],
        ["Protocol", location.protocol || "-"],
      ]),
      hr(),
      $el("div",{class:"mini muted"},[text("Local IPs (best-effort)")]),
      ipPre,
      $el("div",{class:"hint"},[text("Some browsers hide local IPs for privacy; that's normal.")])
    ]),
    $el("div", { class:"card", style:"box-shadow:none" }, [
      $el("h3", {}, [text("DNS / routing")]),
      dnsHint
    ])
  ]);
}

function networkDebug(){
  return $el("div", { class:"card", style:"box-shadow:none" }, [
    $el("h3", {}, [text("Common fixes (macOS)")]),
    $el("pre", {}, [text(
`# Flush caches
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Check resolver routing
scutil --dns | grep -A2 xn--hvs

# Check local port
sudo lsof -nP -iTCP:80

# If browser resets, test forced override:
curl --resolve xn--hvs.xn--hvs:80:127.0.0.1 http://xn--hvs.xn--hvs`
    )]),
    $el("div",{class:"hint"},[text("If curl works with --resolve but browser doesn't, you’re looking at browser DNS/HSTS/HTTPS-upgrade behavior.")])
  ]);
}

/* ===========================
   About tab
=========================== */
function viewAbout(){
  return $el("div", { class:"wrap" }, [
    card("About", $el("div", { class:"grid two" }, [
      $el("div", { class:"card", style:"box-shadow:none" }, [
        $el("h3", {}, [text("What is this?")]),
        $el("p", {}, [text("A local-first toolbox running on your machine, reachable via 妈.妈 / xn--hvs.xn--hvs.")]),
        $el("p", { class:"muted mini" }, [text("No analytics, no login, no cloud dependency.")])
      ]),
      $el("div", { class:"card", style:"box-shadow:none" }, [
        $el("h3", {}, [text("Data storage")]),
        $el("p", {}, [text("Settings + notes are stored in your browser localStorage.")]),
        $el("p", { class:"muted mini" }, [text("Use Export to back up or move to another machine.")])
      ])
    ]))
  ]);
}

/* ===========================
   Render switchboard
=========================== */
function render(){
  renderTabs();
  renderPill();

  const view = document.getElementById("view");
  view.innerHTML = "";

  let node;
  if (state.activeTab === "home") node = viewHome();
  else if (state.activeTab === "tools") node = viewTools();
  else if (state.activeTab === "daily") node = viewDaily();
  else if (state.activeTab === "notes") node = viewNotes();
  else if (state.activeTab === "network") node = viewNetwork();
  else node = viewAbout();

  view.appendChild(node);
}

function renderPill(){
  document.getElementById("pillClock").textContent = new Date().toLocaleTimeString();
  const pillOnline = document.getElementById("pillOnline");
  pillOnline.className = "badge " + (navigator.onLine ? "ok" : "bad");
  pillOnline.textContent = navigator.onLine ? "Online" : "Offline";
}

/* ===========================
   Export / Import (all)
=========================== */
function exportAll(){
  const payload = {
    version: 1,
    exportedAt: nowMs(),
    state
  };
  const blob = new Blob([JSON.stringify(payload, null, 2)], { type:"application/json" });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = `mama-export-${new Date().toISOString().replace(/[:.]/g,"-")}.json`;
  a.click();
  URL.revokeObjectURL(a.href);
}

function importAllFile(file){
  const reader = new FileReader();
  reader.onload = () => {
    const p = safeJsonParse(String(reader.result || ""));
    if (!p.ok){ alert("Import failed: " + p.err); return; }
    const obj = p.val;
    if (!obj || typeof obj !== "object" || !obj.state){ alert("Import failed: missing state"); return; }
    // basic merge / replace
    state = obj.state;
    // sanity
    if (!state.activeSub) state.activeSub = structuredClone(defaultState.activeSub);
    if (!state.notes) state.notes = structuredClone(defaultState.notes);
    if (!Array.isArray(state.notes.items)) state.notes.items = [];
    persist();
    applyThemeAndFont();
    render();
  };
  reader.readAsText(file);
}

/* ===========================
   Top controls + keyboard
=========================== */
function applyThemeAndFont(){
  setTheme(state.theme === "dark" ? "dark" : "light");
  setFontScale(state.fontScale || 1);
}

document.getElementById("btnTheme").addEventListener("click", () => {
  setTheme(state.theme === "dark" ? "light" : "dark");
});

document.getElementById("btnFontUp").addEventListener("click", () => setFontScale((state.fontScale || 1) + 0.05));
document.getElementById("btnFontDown").addEventListener("click", () => setFontScale((state.fontScale || 1) - 0.05));

document.getElementById("btnExportAll").addEventListener("click", exportAll);
document.getElementById("btnImportAll").addEventListener("click", () => document.getElementById("fileImportAll").click());

document.getElementById("fileImportAll").addEventListener("change", (e) => {
  const f = e.target.files?.[0];
  if (f) importAllFile(f);
  e.target.value = "";
});

window.addEventListener("online", renderPill);
window.addEventListener("offline", renderPill);

document.addEventListener("keydown", (e) => {
  if (e.altKey && !e.ctrlKey && !e.metaKey){
    // Alt+1..6
    const n = parseInt(e.key, 10);
    if (n >= 1 && n <= TAB_ORDER.length){
      state.activeTab = TAB_ORDER[n-1];
      persist();
      render();
      e.preventDefault();
      return;
    }
    if (e.key.toLowerCase() === "t"){
      setTheme(state.theme === "dark" ? "light" : "dark");
      e.preventDefault();
      return;
    }
  }
});

/* ===========================
   Boot
=========================== */
applyThemeAndFont();
render();
setInterval(() => { renderPill(); }, 1000);
</script>
</body>
</html>
EOF
  echo "  ✔ index.html created (placeholder)"
else
  echo "  ℹ index.html already exists"
fi

echo

### 7. Flush DNS caches ###########################################

echo "▶ Flushing DNS caches"

sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder 2>/dev/null || true

echo

### DONE ###########################################################

echo "✅ Installation complete"
echo
echo "Next steps:"
echo "  cd $SITE_DIR"
echo "  sudo python3 -m http.server 80 --bind ::"
echo
echo "Then open:"
echo "  http://$DOMAIN_UNICODE/"

cat <<'EOF'
NOTE:
On macOS, background processes started with sudo will be suspended
if sudo attempts to prompt for a password.

Always warm the sudo cache first:

  sudo -v && sudo python3 -m http.server 80 --bind :: >/dev/null 2>&1 &
EOF
