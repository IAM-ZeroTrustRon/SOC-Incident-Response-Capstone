#!/bin/bash
# legacyserver_healthcheck.sh
# Tech Solutions Inc. (simulated) - Automated health check for legacyserver
# Confirms all previously exploited/backdoor ports remain closed.
#
# Built iteratively with an AI "virtual analyst" (Claude) as part of a
# PerScholas Module 195 Cybersecurity capstone. See docs/05-lessons-learned.md
# for the prompt-iteration story behind this script (including a real
# zsh-vs-bash debugging session).

TARGET="192.168.2.3"
PORTS=(21 1524 1099 3632 6667 6697 8787)
NAMES=("vsftpd backdoor" "Ingreslock bindshell" "Java RMI" "distccd" "UnrealIRCd" "UnrealIRCd-SSL" "Ruby DRb")

FLAGGED=0
echo "=== Tech Solutions Inc. - legacyserver Health Check ==="
echo "Target: $TARGET"
echo "Timestamp: $(date)"
echo ""

for i in "${!PORTS[@]}"; do
  PORT="${PORTS[$i]}"
  NAME="${NAMES[$i]}"
  timeout 2 bash -c "cat < /dev/null > /dev/tcp/$TARGET/$PORT" 2>/dev/null
  if [ $? -eq 0 ]; then
    echo "[FLAGGED] Port $PORT ($NAME) is OPEN"
    FLAGGED=1
  else
    echo "[OK] Port $PORT ($NAME) closed"
  fi
done

echo ""
if [ $FLAGGED -eq 0 ]; then
  echo "RESULT: SECURE"
else
  echo "RESULT: INSECURE - investigate immediately"
fi
