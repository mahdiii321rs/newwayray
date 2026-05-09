#!/bin/bash

# ─────────────────────────────────────────────
#  newwayray  –  dynamic multi-config starter
# ─────────────────────────────────────────────

# Generate a unique UUID per inbound (uses kernel random UUID source)
gen_uuid() { cat /proc/sys/kernel/random/uuid; }
UUID1=$(gen_uuid)   # VLESS xHTTP packet-up  (port 443)
UUID2=$(gen_uuid)   # VLESS xHTTP stream-up  (port 8080)
UUID3=$(gen_uuid)   # VLESS WebSocket        (port 8880)
UUID4=$(gen_uuid)   # VMess WebSocket        (port 9090)
UUID5=$(gen_uuid)   # VLESS gRPC             (port 9443)
UUID6=$(gen_uuid)   # Trojan WebSocket       (port 7777)

# ── write the xray config with ALL inbounds ──────────────────────────────────
cat > /etc/config.json << EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "${UUID1}", "flow": "" }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "xhttp",
        "security": "none",
        "xhttpSettings": {
          "mode": "packet-up",
          "path": "/xhttp-pu"
        }
      },
      "tag": "vless-xhttp-packetup"
    },
    {
      "port": 8080,
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "${UUID2}" }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "xhttp",
        "security": "none",
        "xhttpSettings": {
          "mode": "stream-up",
          "path": "/xhttp-su"
        }
      },
      "tag": "vless-xhttp-streamup"
    },
    {
      "port": 8880,
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "${UUID3}" }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/ws"
        }
      },
      "tag": "vless-ws"
    },
    {
      "port": 9090,
      "protocol": "vmess",
      "settings": {
        "clients": [
          { "id": "${UUID4}", "alterId": 0 }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/vmess-ws"
        }
      },
      "tag": "vmess-ws"
    },
    {
      "port": 9443,
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "${UUID5}" }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "grpc",
        "security": "none",
        "grpcSettings": {
          "serviceName": "grpc"
        }
      },
      "tag": "vless-grpc"
    },
    {
      "port": 7777,
      "protocol": "trojan",
      "settings": {
        "clients": [
          { "password": "${UUID6}" }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/trojan-ws"
        }
      },
      "tag": "trojan-ws"
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "tag": "direct" }
  ]
}
EOF

# ── make all ports public via GitHub CLI ─────────────────────────────────────
gh codespace ports visibility 443:public 8080:public 8880:public 9090:public 9443:public 7777:public -c "$CODESPACE_NAME" 2>/dev/null || true

# ── build share links ─────────────────────────────────────────────────────────

# GitHub codespaces exposes ports as  <name>-<port>.app.github.dev  (HTTPS/TLS)
H443="${CODESPACE_NAME}-443.app.github.dev"
H8080="${CODESPACE_NAME}-8080.app.github.dev"
H8880="${CODESPACE_NAME}-8880.app.github.dev"
H9090="${CODESPACE_NAME}-9090.app.github.dev"
H9443="${CODESPACE_NAME}-9443.app.github.dev"
H7777="${CODESPACE_NAME}-7777.app.github.dev"

LINK1="vless://${UUID1}@${H443}:443?encryption=none&security=tls&sni=${H443}&type=xhttp&path=%2Fxhttp-pu&mode=packet-up#VLESS-xHTTP-PacketUp"
LINK2="vless://${UUID2}@${H8080}:443?encryption=none&security=tls&sni=${H8080}&type=xhttp&path=%2Fxhttp-su&mode=stream-up#VLESS-xHTTP-StreamUp"
LINK3="vless://${UUID3}@${H8880}:443?encryption=none&security=tls&sni=${H8880}&type=ws&path=%2Fws#VLESS-WebSocket"

# VMess link (base64-encoded JSON)
VMESS_JSON=$(printf '{"v":"2","ps":"VMess-WS","add":"%s","port":"443","id":"%s","aid":"0","scy":"none","net":"ws","type":"none","host":"%s","path":"/vmess-ws","tls":"tls","sni":"%s","alpn":""}' \
  "${H9090}" "${UUID4}" "${H9090}" "${H9090}")
VMESS_B64=$(echo -n "$VMESS_JSON" | base64 -w 0)
LINK4="vmess://${VMESS_B64}"

LINK5="vless://${UUID5}@${H9443}:443?encryption=none&security=tls&sni=${H9443}&type=grpc&serviceName=grpc#VLESS-gRPC"
LINK6="trojan://${UUID6}@${H7777}:443?security=tls&sni=${H7777}&type=ws&path=%2Ftrojan-ws#Trojan-WS"

# ── print everything ──────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   🚀  newwayray  –  your V2Ray / Xray links"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "① VLESS + xHTTP  (packet-up)  ← recommended"
echo "   ${LINK1}"
echo ""
echo "② VLESS + xHTTP  (stream-up)"
echo "   ${LINK2}"
echo ""
echo "③ VLESS + WebSocket (WS)"
echo "   ${LINK3}"
echo ""
echo "④ VMess + WebSocket (WS)"
echo "   ${LINK4}"
echo ""
echo "⑤ VLESS + gRPC"
echo "   ${LINK5}"
echo ""
echo "⑥ Trojan + WebSocket (WS)"
echo "   ${LINK6}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Each config has its own unique UUID (randomized at startup)"
echo "  TLS : provided by GitHub (*.app.github.dev)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
