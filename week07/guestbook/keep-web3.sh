#!/usr/bin/env bash
# web 컨테이너를 항상 N개(기본 3개)로 유지하는 감시 스크립트
#
#   ./keep-web3.sh            # web 3개, 5초마다 확인
#   ./keep-web3.sh 3 10       # web 3개, 10초마다 확인
#
# 하는 일 (INTERVAL 초마다 반복)
#   1) 실행 중인 web 개수를 센다
#   2) 원하는 개수보다 적으면 docker compose up --scale로 다시 맞춘다
#      (docker stop으로 멈춘 것은 다시 켜지고, docker rm으로 지운 것은 새로 만들어진다)
#   3) 실행은 되지만 healthcheck가 unhealthy인 web은 재시작한다

set -u

WANT="${1:-3}"        # 유지할 web 개수
INTERVAL="${2:-5}"    # 확인 간격(초)

cd "$(dirname "$0")" || exit 1   # compose.yaml이 있는 폴더에서 실행

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

running_web() {
  docker compose ps --status running -q web | wc -l | tr -d ' '
}

log "감시 시작: web ${WANT}개 유지, ${INTERVAL}초마다 확인 (끝내려면 Ctrl+C)"

while true; do
  NOW=$(running_web)

  if [ "$NOW" -lt "$WANT" ]; then
    log "web ${NOW}개 → ${WANT}개로 복구 시작"
    if docker compose up -d --no-recreate --scale web="$WANT" web > /dev/null 2>&1; then
      log "복구 완료: web $(running_web)개"
    else
      log "복구 실패 (다음 확인 때 다시 시도)"
    fi
  fi

  # 켜져는 있지만 응답을 못 하는(unhealthy) web은 재시작
  for id in $(docker compose ps -q web); do
    STATE=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$id" 2> /dev/null)
    if [ "$STATE" = "unhealthy" ]; then
      NAME=$(docker inspect -f '{{.Name}}' "$id" | tr -d '/')
      log "${NAME} 상태 unhealthy → 재시작"
      docker restart "$id" > /dev/null
    fi
  done

  sleep "$INTERVAL"
done
