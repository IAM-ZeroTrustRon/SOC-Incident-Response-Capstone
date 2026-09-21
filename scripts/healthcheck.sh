#!/usr/bin/env bash
# healthcheck.sh: verify remediated ports are closed and SSH is still open.
# Pure bash: uses /dev/tcp and bash builtins only (no nc, nmap, timeout, sleep).
#
# Tech Solutions Inc. (simulated) - Automated health check for legacyserver.
# Team-standard script for the PerScholas Module 195 Cybersecurity capstone
# (Task 10), adapted from a version written by teammate Parker Collins and
# verified independently in each team member's own lab. See
# docs/05-lessons-learned.md for the prompt-iteration story behind the
# earlier draft of this check.
#
# Usage: ./healthcheck.sh [host] [timeout_seconds]
# Exit codes: 0 = SECURE, 1 = VULNERABLE, 2 = SSH not reachable (check failed)

HOST="${1:-192.168.2.3}"
TIMEOUT="${2:-2}"

# Ports that should be CLOSED after remediation, with the service each one exposed
declare -A REMEDIATED=(
  [21]="FTP (vsftpd)"
  [1524]="Ingreslock bind shell"
  [3632]="distccd"
  [6667]="IRC (UnrealIRCd)"
  [1099]="Java RMI registry"
  [5900]="VNC"
  [8787]="Ruby DRb"
)
SSH_PORT=22

# Bash-only sleep: read waits on a pipe that never gets data until -t expires
nap() { read -rt "$1" <> <(:) || true; }

# Returns 0 = open, 1 = closed (refused), 2 = no response within TIMEOUT (filtered)
check_port() {
  local port=$1 pid i
  ( exec 3<>"/dev/tcp/${HOST}/${port}" ) 2>/dev/null &
  pid=$!
  for (( i = 0; i < TIMEOUT * 10; i++ )); do
    if ! kill -0 "$pid" 2>/dev/null; then
      wait "$pid" && return 0 || return 1
    fi
    nap 0.1
  done
  kill "$pid" 2>/dev/null
  wait "$pid" 2>/dev/null
  return 2
}

state_name() {
  case $1 in
    0) echo "OPEN" ;;
    1) echo "CLOSED" ;;
    2) echo "FILTERED" ;;
  esac
}

echo "Health check: ${HOST} (timeout ${TIMEOUT}s per port)"
echo "------------------------------------------------------"

vulnerable=0
for port in $(printf '%s\n' "${!REMEDIATED[@]}" | sort -n); do
  check_port "$port"; rc=$?
  if (( rc == 0 )); then
    result="FAIL"; vulnerable=1
  else
    result="PASS"
  fi
  printf '%-5s %-24s %-9s %s\n' "$port" "${REMEDIATED[$port]}" "$(state_name $rc)" "$result"
done

check_port "$SSH_PORT"; rc=$?
if (( rc == 0 )); then
  ssh_ok=1; result="PASS"
else
  ssh_ok=0; result="FAIL"
fi
printf '%-5s %-24s %-9s %s\n' "$SSH_PORT" "SSH (must stay open)" "$(state_name $rc)" "$result"

echo "------------------------------------------------------"
if (( vulnerable )); then
  echo "VULNERABLE"
  exit 1
elif (( ! ssh_ok )); then
  echo "CHECK FAILED: SSH unreachable. Host may be down, so closed results can't be trusted."
  exit 2
else
  echo "SECURE"
  exit 0
fi
