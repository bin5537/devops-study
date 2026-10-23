#!/usr/bin/env bash
# web=3 유지 실험: 시나리오별로 실제 명령을 실행하고 결과를 로그로 남긴다
#   bash run_experiments.sh      (week07/guestbook의 compose 프로젝트를 사용)
set -u
export MSYS_NO_PATHCONV=1                      # Git Bash 경로 자동 변환 끄기
PORT="${PORT:-8080}"                           # nginx가 열린 호스트 포트
APP="${APP:-}"
if [ "${DOCKER_SUDO:-0}" = "1" ]; then         # 서버에서 sudo로 docker를 쓸 때
  docker() { sudo -n env DOCKER_CONFIG="$HOME/.docker" /usr/bin/docker "$@"; }
  export -f docker
fi
HERE="$(cd "$(dirname "$0")" && pwd)"
APP="${APP:-$HERE/..}"
LOG="$HERE/results.txt"
cd "$APP" || exit 1
: > "$LOG"

say()  { echo "$*" | tee -a "$LOG"; }
step() { say ""; say "================================================================"; say "$*"; say "================================================================"; }
run()  { say "\$ $*"; eval "$@" 2>&1 | tee -a "$LOG"; }
now()  { date '+%H:%M:%S'; }
webs() { run "docker compose ps -a web --format 'table {{.Name}}\t{{.State}}\t{{.Status}}'"; }
# nginx(8080)로 6번 요청해서 응답한 컨테이너(hostname = 컨테이너 ID 앞 12자리)를 이름으로 바꿔 보여주기
hits() {
  say "\$ for i in 1 2 3 4 5 6; do curl -s localhost:$PORT/healthz; done   (응답한 컨테이너)"
  local line=""
  for i in 1 2 3 4 5 6; do
    local h code
    code=$(curl -s -o /tmp/hz.json -w '%{http_code}' localhost:$PORT/healthz)
    h=$(sed -E 's/.*"hostname": ?"([^"]+)".*/\1/' /tmp/hz.json 2>/dev/null)
    local n
    n=$(docker ps -a --filter "id=$h" --format '{{.Names}}' 2>/dev/null)
    line="$line $code:${n:-?}"
  done
  say " $line"
}
wait_healthy() {   # web이 원하는 개수만큼 healthy가 될 때까지 (최대 60초)
  local want=$1 t=0
  while [ $t -lt 60 ]; do
    local n
    n=$(docker compose ps web --format '{{.Health}}' | grep -c '^healthy$')
    [ "$n" -ge "$want" ] && { say "($(now)) healthy web ${n}개 (${t}초 기다림)"; return; }
    sleep 2; t=$((t+2))
  done
  say "($(now)) 60초 안에 healthy ${want}개가 안 됨"
}

step "0. 준비: 빌드하고 web 3개 + nginx + redis 띄우기"
run "docker compose down -v --remove-orphans > /dev/null 2>&1; true"
run "docker compose up -d --build --scale web=3 2>&1 | tail -n 8"
wait_healthy 3
webs
hits

step "1. 교안 48쪽 호기심: web-2를 docker stop 하면? (restart: unless-stopped)"
say "($(now)) web-2 중지"
run "docker stop guestbook-web-2"
say "20초 기다림..."; sleep 20
webs
hits
run "docker inspect -f 'web-2 RestartCount={{.RestartCount}} Status={{.State.Status}}' guestbook-web-2"

step "2. 사람이 직접 복구: docker compose up -d --scale web=3"
run "docker compose up -d --scale web=3 2>&1 | tail -n 6"
wait_healthy 3
webs

step "3. 사고로 꺼지면? (앱 프로세스가 스스로 죽는 상황을 SIGINT로 흉내)"
run "docker inspect -f 'web-1 시작 시각={{.State.StartedAt}} RestartCount={{.RestartCount}}' guestbook-web-1"
say "($(now)) web-1 안의 앱 프로세스(PID 1)에 SIGINT"
run "docker exec guestbook-web-1 python -c 'import os, signal; os.kill(1, signal.SIGINT)'"
say "10초 기다림..."; sleep 10
run "docker inspect -f 'web-1 시작 시각={{.State.StartedAt}} RestartCount={{.RestartCount}} Status={{.State.Status}}' guestbook-web-1"
webs

step "4. 컨테이너를 아예 지우면? docker rm -f guestbook-web-3"
say "($(now)) web-3 삭제"
run "docker rm -f guestbook-web-3"
say "15초 기다림..."; sleep 15
webs

step "5. 감시 스크립트 keep-web3.sh를 켜고 같은 사고를 다시 내기"
WD_LOG="$HERE/watchdog.txt"
: > "$WD_LOG"
bash ./keep-web3.sh 3 5 >> "$WD_LOG" 2>&1 &
WD=$!
say "($(now)) 감시 스크립트 시작 (PID $WD, 5초마다 확인)"
sleep 12; wait_healthy 3; webs
say ""
say "($(now)) 5-1. web-2 docker stop"
run "docker stop guestbook-web-2"
sleep 15; wait_healthy 3; webs
say ""
say "($(now)) 5-2. web-3 docker rm -f"
run "docker rm -f guestbook-web-3"
sleep 15; wait_healthy 3; webs
say ""
say "($(now)) 5-3. web-1과 web-2를 한꺼번에 docker stop"
run "docker stop guestbook-web-1 guestbook-web-2"
sleep 15; wait_healthy 3; webs
hits
say ""
say "--- 감시 스크립트 로그 ---"
cat "$WD_LOG" | tee -a "$LOG"

step "6. 한계: 감시 스크립트가 죽으면?"
kill "$WD" 2>/dev/null; wait "$WD" 2>/dev/null
say "($(now)) 감시 스크립트 종료"
run "docker stop guestbook-web-2"
say "20초 기다림..."; sleep 20
webs
run "docker compose up -d --scale web=3 2>&1 | tail -n 3"
wait_healthy 3

step "7. 원하는 개수를 파일에 적어 두기: deploy.replicas: 3"
cat > compose.replicas.yaml <<'YAML'
services:
  web:
    deploy:
      replicas: 3
YAML
run "cat compose.replicas.yaml"
run "docker compose -f compose.yaml -f compose.replicas.yaml down > /dev/null 2>&1; true"
run "docker compose -f compose.yaml -f compose.replicas.yaml up -d 2>&1 | tail -n 6"
wait_healthy 3
webs
run "docker stop guestbook-web-2"
sleep 15
say "(replicas를 적어도 멈춘 것을 다시 켜 주지는 않음)"
webs
run "docker compose -f compose.yaml -f compose.replicas.yaml up -d 2>&1 | tail -n 4"
wait_healthy 3
webs
rm -f compose.replicas.yaml

step "8. 정리"
run "docker compose down -v --remove-orphans 2>&1 | tail -n 3"
say ""
say "끝 ($(now))"
