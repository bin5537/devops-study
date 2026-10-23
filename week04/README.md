# 4주차 · 자동화와 협업, 네트워크

4주차 교안 `03. 자동화와 협업`, `04. 네트워크`와 짧은 참고 자료 `Zone.Identifier`를 함께 정리했다.

## 배운 내용 정리

- 디렉터리 구조와 절대/상대 경로를 정리하고, `find`, `grep`, `|`(파이프)로 필요한 파일과 내용을 찾았다.
- 변수, 인자, 조건, 반복을 써서 셸 스크립트를 작성했다. 프로그램과 프로세스를 구분하고 PID로 프로세스를 확인하고 종료했다.
- `tar`로 압축하는 백업 스크립트(`backup.sh`)를 만들고 `diff`로 복원본이 원본과 같은지 확인했다. 결과물은 `.gitignore`로 Git에서 뺐다.
- Git 협업 흐름: 브랜치 → 커밋/푸시 → Pull Request → Merge. 일부러 충돌(Conflict)을 만들어 로컬에서 해결하고 다시 Merge했다.
- 네트워크: IP 주소, 포트, DNS의 역할을 배우고 `ip addr`, `ping`, `dig`, `curl`, `ss`로 상태를 확인했다. `python3 -m http.server`로 내 컴퓨터에 웹 서버를 띄우고 포트 충돌을 일으킨 뒤 해결했다.

## 실습한 명령어와 코드

### A. 자동화 기초

자동화 체험: 디렉터리 100개 만들기

| 명령어 | 하는 일 |
|---|---|
| `for i in $(seq 1 100); do mkdir -p test/dir$i; done` | 1부터 100까지 반복하면서 디렉터리 생성 |
| `ls test` |  |
| `rm -rf test` | test 디렉터리 삭제 |
| `ls -ld /home /etc /var/log /tmp /usr/bin` | 주요 디렉터리 자체 정보 (-d: 디렉터리 자체) |

파일 찾기와 파이프

| 명령어 | 하는 일 |
|---|---|
| `cd ~/devops` |  |
| `find . -type f -name "*.sh"` | 셸 스크립트 파일 찾기 |
| `grep -R -n "exit 1" week03 2>/dev/null` | exit 1을 포함하는 줄 찾기 (-R: 하위 디렉터리까지, -n: 줄 번호) |
| `grep -R "exit 1" week03 2>/dev/null \| wc -l` | 찾은 줄 수 세기 (wc -l: 줄 수) |

텍스트 파일 만들고 확인하기

```bash
cd ~/devops/week04
mkdir -p test
cd test
cat > diary.txt << 'EOF'
월요일 - 리눅스를 배웠다.
화요일 - Git과 GitHub를 배웠다.
수요일 - 네트워크를 배웠다.
목요일 - 도커는 언제나 배울까?
EOF
```

| 명령어 | 하는 일 |
|---|---|
| `cat diary.txt` |  |
| `head -2 diary.txt` | 앞 2줄 출력 |
| `tail -1 diary.txt` | 뒤 1줄 출력 |
| `wc -l diary.txt` | 전체 줄 수 출력 |

`server.log`로 grep, find 연습 (LMS에서 받아 `~/devops/week04/test`로 이동)

| 명령어 | 하는 일 |
|---|---|
| `grep "ERROR" server.log` | ERROR가 든 줄만 |
| `grep -i "error" server.log` | -i: 대소문자 무시 |
| `grep -c "ERROR" server.log` | -c: 개수만 |
| `grep -n "ERROR" server.log` | -n: 줄 번호와 함께 |
| `grep -v "INFO" server.log` | -v: INFO가 없는 줄만 (반전) |
| `find . -name "*.txt"` | txt 파일 찾기 |
| `find . -type d` | 디렉터리만 찾기 |
| `find / -name "start.sh" 2>/dev/null` | 시스템 전체에서 찾기 (오래 걸릴 수 있음) |
| `find / -name "start.sh"` | 2>/dev/null을 빼고 실행해 보기 (2>/dev/null: 표준 오류를 버림) |

파이프와 리다이렉션

| 명령어 | 하는 일 |
|---|---|
| `cat server.log \| grep ERROR` | cat 결과를 grep에 전달 (grep ERROR server.log와 같은 결과) |
| `cat server.log \| grep ERROR \| wc -l` | 위 결과의 줄 수 |
| `ls -l /etc \| grep conf \| head -5` | 파이프를 두 번 사용 |
| `grep ERROR server.log > errors.txt` | 결과를 파일로 저장 |
| `cat errors.txt` |  |

변수와 명령 치환 (`var.sh`)

```bash
#!/bin/bash
USERNAME="홍길동"                       # = 양옆에 공백 없이
TODAY=$(date +%Y%m%d)                  # date 명령 결과를 변수에 저장
echo "이름: $USERNAME"
echo "파일명: backup_${TODAY}.tar.gz"   # 변수 이름 경계를 {}로 표시
```

| 명령어 | 하는 일 |
|---|---|
| `chmod u+x var.sh && ./var.sh` | 권한 주고 성공하면 바로 실행 |

인자와 종료 코드 (`greet.sh`)

```bash
#!/bin/bash
if [ $# -eq 0 ]; then                   # 인자 개수가 0이면 ([ ] 안쪽 양옆에 공백 필요)
  echo "사용법: $0 [이름]"
  exit 1                                # 비정상 종료
fi
echo "안녕하세요, $1님! (인자 개수: $#)"  # ${1}도 사용 가능
```

| 명령어 | 하는 일 |
|---|---|
| `chmod u+x greet.sh` |  |
| `./greet.sh` | 사용법 출력 |
| `echo $?` | → 1 |
| `./greet.sh 홍길동` | 안녕하세요, 홍길동님! (인자 개수: 1) |
| `echo $?` | → 0 |

조건문과 파일 검사 (`check.sh`)

```bash
#!/bin/bash
FILE="$1"
if [ -z "$FILE" ]; then                 # 문자열 길이가 0이면 (인자가 없으면)
  echo "파일명을 입력하세요"; exit 1
fi
if [ -f "$FILE" ]; then                 # 파일이 존재하면
  echo "파일"
elif [ -d "$FILE" ]; then               # 디렉터리가 존재하면
  echo "디렉터리"
else
  echo "없음"; exit 1
fi
```

| 명령어 | 하는 일 |
|---|---|
| `chmod u+x check.sh` |  |
| `./check.sh var.sh` | 파일 |
| `./check.sh /etc` | 디렉터리 |
| `./check.sh 없는파일` | 없음 |

반복문: 현재 디렉터리의 .sh 파일 이름 출력

```bash
for f in *.sh; do echo "스크립트: $f"; done
```

### B. 프로세스와 백업

| 명령어 | 하는 일 |
|---|---|
| `sudo apt update` |  |
| `sudo apt install -y tree jq htop` | 맥은 brew install |
| `tree ~/devops -L 2` | 디렉터리 구조를 2단계 깊이까지 |

프로세스 확인하고 종료하기

| 명령어 | 하는 일 |
|---|---|
| `ps aux \| head -5` | 프로세스 정보 앞 5줄 |
| `ps aux \| grep bash` | bash를 포함하는 프로세스 |
| `htop` | CPU, 메모리 사용량을 실시간으로 (종료: q) |
| `sleep 300 &` | &: 백그라운드 실행 (화면에 PID 표시) |
| `jobs` | 현재 셸의 실행 작업 |
| `ps aux \| grep sleep` | PID 확인 |
| `kill <PID>` | 정상 종료 요청 (SIGTERM) |
| `ps aux \| grep sleep` | 사라진 것 확인 |
| `sleep 300 &` |  |
| `kill -9 <PID>` | 강제 종료 (SIGKILL), 최후의 수단 |

백업 스크립트 (`week04/backup.sh`)

```bash
#!/bin/bash
# 사용법: ./backup.sh [백업할_폴더]

cd "$(dirname "$0")" || exit 1           # 스크립트가 있는 위치 기준으로 실행

SOURCE_DIR=${1:-test}                    # 인자가 없으면 test 디렉터리
BACKUP_DIR="backups"
TODAY=$(date +%Y%m%d_%H%M%S)
FILENAME="${TODAY}_$$.tar.gz"            # $$: 현재 셸의 PID, 이름 충돌 가능성 줄이기

# 1) 원본 확인
if [ ! -d "$SOURCE_DIR" ]; then
  echo "오류: '$SOURCE_DIR' 디렉터리가 없습니다."
  exit 1
fi
# 2) 백업 폴더 준비
mkdir -p "$BACKUP_DIR" || exit 1

# 3) 압축
echo "백업 시작: $SOURCE_DIR → $BACKUP_DIR/$FILENAME"
tar -czf "$BACKUP_DIR/$FILENAME" "$SOURCE_DIR"

# 4) 결과 확인
if [ $? -eq 0 ]; then                    # 직전 명령(tar)의 종료 코드가 0이면 성공
  SIZE=$(du -sh "$BACKUP_DIR/$FILENAME" | cut -f1)
  echo "백업 완료! (크기: $SIZE)"
else
  echo "백업 실패"
  exit 1
fi

# 5) 목록
echo "현재 보관 중인 백업:"
ls -1 "$BACKUP_DIR"                      # 한 줄에 하나씩 출력
```

백업하고 복원 확인

| 명령어 | 하는 일 |
|---|---|
| `cd ~/devops/week04` |  |
| `./backup.sh test` | 백업 |
| `ls backups/*.tar.gz` | 파일 확인 |
| `ARCHIVE="backups/<방금생성된파일명>.tar.gz"` | 위 목록에서 복사해서 넣기 |
| `tar -tzf "$ARCHIVE"` | 내용 확인 |
| `mkdir -p restore-check` | 복원 확인용 디렉터리 |
| `tar -xzf "$ARCHIVE" -C restore-check` | restore-check 안에 압축 풀기 |
| `diff -rq test restore-check/test` | 원본과 복원본 비교 |
| `echo $?` | 0이면 같음 |

백업 결과물은 Git으로 관리하지 않는다

```bash
cd ~/devops/
cat >> .gitignore << 'EOF'
week04/backups/
week04/restore-check/
EOF
git add .gitignore
git add week04
git commit -m "week04: 백업 스크립트 초안"
git push
```

### C. Git 협업

브랜치 만들기

| 명령어 | 하는 일 |
|---|---|
| `cd ~/devops` |  |
| `git branch` | 현재 브랜치 확인 (* main) |
| `git switch -c feature/backup-log` | 브랜치 생성 + 이동 |
| `git branch` | 2개 확인, * 가 feature/backup-log로 바뀜 |

브랜치에서 작업하고 커밋, 푸시

```bash
git switch feature/backup-log
cat >> week04/backup.sh << 'EOF'

# 로그 기록
echo "$(date '+%Y-%m-%d %H:%M:%S') 백업 완료: $FILENAME" >> "$BACKUP_DIR/backup.log"
echo "로그 기록 완료"
EOF
```

| 명령어 | 하는 일 |
|---|---|
| `git status` | 상태 확인 (습관적으로) |
| `git diff week04/backup.sh` | 바뀐 내용 확인 (습관적으로) |
| `git add week04/backup.sh` |  |
| `git commit -m "feat: 백업 로그 기록 기능 추가"` |  |
| `git push -u origin feature/backup-log` | 원격 저장소에 feature/backup-log 브랜치 올리기 |

Pull Request 올리고 Merge

```bash
gh pr create --title "백업 로그 기록 기능 추가" \
  --body "백업이 끝나면 backup.log에 백업 일시와 파일명을 기록합니다." \
  --base main \
  --head feature/backup-log                      # --head는 생략 가능
```

| 명령어 | 하는 일 |
|---|---|
| `gh pr view --web` | 웹에서 PR 확인 |
| `gh pr merge --squash --delete-branch` | 스쿼시 머지로 main에 합치면서 브랜치 삭제 |
| `git switch main` | main 브랜치로 이동 |
| `git pull --ff-only` | 바뀐 내용 받기 (fast-forward만 허용) |
| `git log --oneline -3` | 최근 3개 커밋 보기 |

충돌 만들기 (실제 프로젝트에서는 main에 직접 push를 막기도 함)

| 명령어 | 하는 일 |
|---|---|
| `cd week04` |  |
| `git branch fix/message` | 브랜치만 만들기 (이동은 안 함) |
| `git switch main` |  |
| `git branch` |  |
| `sed -i 's/로그 기록 완료/로그 기록/' backup.sh` | main에서 마지막 문구 수정 (macOS: sed -i '' ...) |
| `tail -1 backup.sh` | echo "로그 기록" |
| `git add backup.sh` |  |
| `git status` |  |
| `git commit -m "문구 수정"` |  |
| `git push` | main에 바로 푸시 |
| `git switch fix/message` |  |
| `tail -1 backup.sh` |  |
| `sed -i 's/로그 기록 완료/[완료] 로그 기록/' backup.sh` | 같은 줄을 다르게 수정 |
| `tail -1 backup.sh` | echo "[완료] 로그 기록" |
| `git add backup.sh` |  |
| `git status` |  |
| `git commit -m "문구 수정"` |  |
| `git push -u origin fix/message` |  |
| `gh pr create --title "문구 수정" --body "수정" --base main` |  |
| `gh pr view --web` |  |

Merge 시도 → 실패 (교안 출력)

```text
$ gh pr merge --squash --delete-branch
X Pull request #3 is not mergeable: the merge commit cannot be cleanly created.
To have the pull request merged after all the requirements have been met, add the `--auto` flag.
Run the following to resolve the merge conflicts locally:
  gh pr checkout 3 && git fetch origin main && git merge origin/main
```

로컬에서 충돌 해결

| 명령어 | 하는 일 |
|---|---|
| `gh pr checkout fix/message` | PR 브랜치 가져오기 (PR 번호 3을 써도 됨) |
| `git fetch origin` | 원격 최신 내용 가져오기 (origin main까지 써도 됨) |
| `git merge origin/main` | main 내용을 합치기 → CONFLICT |

```text
Auto-merging week04/backup.sh
CONFLICT (content): Merge conflict in week04/backup.sh
Automatic merge failed; fix conflicts and then commit the result.
```

`backup.sh` 마지막 부분이 이렇게 바뀌어 있다.

```text
<<<<<<< HEAD
echo "[완료] 로그 기록"
=======
echo "로그 기록"
>>>>>>> origin/main
```

`<<<<<<< HEAD`, `=======`, `>>>>>>> origin/main` 세 줄을 지우고 원하는 내용만 남긴다 (둘 다 남겨도 됨). 교안에서는 `echo "[완료] 로그 기록"`만 남겼다.

| 명령어 | 하는 일 |
|---|---|
| `cd ~/devops` |  |
| `git status` |  |
| `git add week04/backup.sh` |  |
| `git commit -m "resolve: merge conflict"` |  |
| `git push` | PR이 업데이트됨 |
| `gh pr view --web` | No conflicts with base branch 확인 |
| `gh pr merge --squash --delete-branch` | 이제 Merge 가능 |
| `git switch main` |  |
| `git pull --ff-only` |  |

main 브랜치에 직접 푸시 막기 (터미널 방법, 해당 저장소 admin 권한 필요)

```bash
gh api --method PUT repos/<깃허브아이디>/<레포이름>/branches/main/protection --input - <<'EOF'
{
  "required_status_checks": null,
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 0
  },
  "restrictions": null
}
EOF
```

| 명령어 | 하는 일 |
|---|---|
| `gh api repos/<깃허브아이디>/<레포이름>/branches/main/protection` | 설정 확인 (리뷰 없이 merge 허용 상태) |

웹에서는 Settings > Rulesets > New ruleset > New branch ruleset에서 이름을 정하고, Active로 설정, Add target > Include default branch, Require a pull request before merging을 선택한다. 설정 후 main에서 `git push`를 하면 아래처럼 거절된다 (교안 출력, 설정 방식에 따라 오류 메시지는 다를 수 있음).

```text
remote: error: GH006: Protected branch update failed for refs/heads/main.
remote:
remote: - Changes must be made through a pull request.
 ! [remote rejected] main -> main (protected branch hook declined)
```

### D. 네트워크

내 IP 확인

| 명령어 | 하는 일 |
|---|---|
| `ip addr` | Ubuntu / WSL2의 네트워크 인터페이스와 IP |
| `ip addr show eth0` | 특정 인터페이스만 |
| `hostname -I` | 사설 IP 확인 |
| `curl ifconfig.me` | 공인 IP 확인 (공통) |

맥은 `ifconfig`, `ipconfig getifaddr en0`을 쓴다.

연결 확인과 DNS 조회

| 명령어 | 하는 일 |
|---|---|
| `ping -c 4 8.8.8.8` | 구글 DNS에 IP로 응답 확인 (-c 4: 4번만) |
| `ping -c 4 cs.inhatc.ac.kr` | 도메인으로 |
| `ping -c 4 127.0.0.1` | 나 자신 |
| `curl -I https://cs.inhatc.ac.kr` | HTTP 응답 헤더만 확인 |
| `sudo apt install -y dnsutils` | dig, nslookup 설치 (맥은 기본 사용 가능) |
| `dig cs.inhatc.ac.kr` | DNS 레코드까지 자세히 |
| `dig cs.inhatc.ac.kr +short` | IP만 |
| `nslookup cs.inhatc.ac.kr` | 간단하게 |
| `cat /etc/hosts` | 로컬 이름 매핑 (로컬 전화번호부) |

교안 예시: `ping cs.inhatc.ac.kr`은 `100% packet loss`였지만 `curl -I`는 `HTTP/1.1 400 Bad Request`를 받았다. 400이어도 HTTP 응답을 받았으니 웹 서버까지 통신은 된 것이다.

HTTP 요청과 jq

| 명령어 | 하는 일 |
|---|---|
| `curl https://google.com` | HTML 본문 |
| `curl -I https://google.com` | 헤더만 (응답 코드 확인) |
| `curl -s https://api.github.com/users/torvalds \| jq .name` | -s: 진행 메시지 숨김, jq로 값만 꺼내기 |
| `curl -o test.html https://google.com` | -o: 결과를 파일로 저장 |
| `echo '{"name":"Kam","age":"21"}' \| jq` | JSON 보기 좋게 |
| `echo '{"name":"Kam","age":"21"}' \| jq '.name'` | "Kam" |
| `echo '{"name":"Kam","age":"21"}' \| jq -r '.name'` | Kam (-r: raw, 따옴표 없이) |
| `echo '{"users":[{"name":"Neary"},{"name":"Kam"}]}' \| jq '.users[0].name'` | "Neary" |

LISTEN 중인 TCP 포트 확인

| 명령어 | 하는 일 |
|---|---|
| `ss -tlnp` | t=TCP, l=listen, n=숫자로, p=프로세스 |
| `sudo ss -tlnp` | 프로세스 이름까지 |
| `ss -tlnp \| grep <포트번호>` | 특정 포트만 |

맥은 `lsof -nP -iTCP -sTCP:LISTEN`.

웹 서버 띄우기

| 명령어 | 하는 일 |
|---|---|
| `mkdir -p ~/devops/week04/site` |  |
| `cd ~/devops/week04/site` |  |
| `cp "/mnt/c/<경로>/index.html" .` | LMS의 index.html 복사 (경로 정확하게) |
| `python3 -m http.server 8080` | 학습/테스트용 간단한 웹 서버, 브라우저에서 http://localhost:8080 |
| `python3 -m http.server 8080 --bind 0.0.0.0` | 모든 네트워크 인터페이스에서 연결 받기 |

```text
Serving HTTP on 0.0.0.0 port 8080 (http://0.0.0.0:8080/) ...
127.0.0.1 - - [19/Sep/2026 17:34:23] "GET / HTTP/1.1" 200 -
```

새 터미널(Windows Terminal에서 Ubuntu 탭 추가)에서 확인

| 명령어 | 하는 일 |
|---|---|
| `curl http://localhost:8080` | HTML 응답 확인 |
| `curl -I http://localhost:8080` | 상태 코드 확인 (200 OK) |
| `ss -tlnp \| grep 8080` | 8080이 LISTEN 상태인지 |

포트 충돌과 해결: 터미널 1에서 서버를 켜 둔 채 터미널 2에서 같은 8080으로 띄우면 `OSError: [Errno 98] Address already in use`가 난다.

| 명령어 | 하는 일 |
|---|---|
| `python3 -m http.server 8000` | 해결 1: 다른 포트 사용 |
| `ss -tlnp \| grep 8080` | 해결 2: 포트를 쓰는 프로세스의 PID 확인 |
| `kill 4299` | 교안 예시 PID, 기본 SIGTERM |
| `ss -tlnp \| grep 8080` | 없음 |
| `pkill -f "http.server"` | 여러 서버 정리 (조건에 맞는 다른 프로세스도 종료될 수 있음) |

```text
LISTEN 0 5 0.0.0.0:8080 0.0.0.0:* users:(("python3",pid=4299,fd=3))
```

포트 여러 개 띄워 보기

| 명령어 | 하는 일 |
|---|---|
| `python3 -m http.server 8080 &` | &: 백그라운드 실행 |
| `python3 -m http.server 8081 &` |  |
| `python3 -m http.server 8082 &` |  |
| `ss -tlnp \| grep python` | 세 포트 확인 |
| `curl -s localhost:8080 \| head -3` |  |
| `pkill -f "http.server"` | 정리 |

### E. [참고] Zone.Identifier

윈도우에서 받은 파일을 WSL로 복사하거나 압축을 풀면 `index.html:Zone.Identifier` 같은 파일이 생길 수 있다. 윈도우 MotW(Mark of the Web) 정보로, ADS(Alternate Data Stream) 형태로 저장되어 탐색기에서는 안 보인다.

```bash
cat >> .gitignore << 'EOF'
*:Zone.Identifier
EOF
```

| 명령어 | 하는 일 |
|---|---|
| `find . -type f -name '*:Zone.Identifier' -delete` | 이미 생긴 파일 찾아서 삭제 |
| `git add -A` |  |
| `git commit --amend --no-edit` | 이미 커밋했다면 직전 커밋을 수정 |

## 핵심 개념 정리

디렉터리와 경로

| 위치 | 용도 |
|---|---|
| `/home` | 사용자 작업 공간 (`~`는 보통 `/home/사용자`) |
| `/etc` | 시스템과 프로그램의 설정 |
| `/var/log` | 시스템과 서비스의 로그 |
| `/tmp` | 임시 파일 |
| `/usr/bin` | 주요 실행 파일과 명령어 |

- 절대 경로: `/home/neary/devops/week03/qwen-web/start.sh`
- 상대 경로: `./week03/qwen-web/start.sh` (현재 위치가 `~/devops`일 때)
- `.` 현재, `..` 상위, `~` 홈, `/` 루트
- 스크립트에 `cd "$(dirname "$0")"`를 쓰는 이유: 어디에서 호출하든 스크립트가 있는 위치를 기준으로 실행하기 위해.
- `|`(파이프): 파일을 넘기는 게 아니라 앞 명령의 표준 출력을 뒤 명령의 표준 입력으로 연결.

조건 검사 연산자 (`[ ]`)

| 연산자 | 의미 |
|---|---|
| `-f 파일` | 파일이 존재하는지 |
| `-d 폴더` | 폴더가 존재하는지 |
| `-z 문자열` | 문자열 길이가 0인지 |
| `-n 문자열` | 문자열 길이가 0이 아닌지 |
| `-eq` / `-ne` | 정수가 같은지 / 다른지 |
| `-gt` / `-lt` | 정수가 큰지 / 작은지 |
| `-ge` / `-le` | 크거나 같은지 / 작거나 같은지 |

프로세스와 시그널

| 시그널 | 번호 | 의미 |
|---|---|---|
| SIGTERM | 15 | 정상 종료 요청 (정리할 기회를 가짐), `kill` 기본값 |
| SIGKILL | 9 | 즉시 종료 (데이터 손실 위험), `kill -9` |
| SIGINT | 2 | Ctrl + C |

- 프로그램: 디스크에 저장된 실행 코드 / 프로세스: 실행 중인 프로그램
- `ps aux`: a(모든 사용자), u(사용자 중심의 상세), x(터미널에 연결되지 않은 프로세스 포함)

tar, diff

| 옵션 | 의미 |
|---|---|
| `tar -czf` | 압축 생성 (c=create, z=gzip, f=파일명 지정) |
| `tar -tzf` | 내용 확인 (t=list) |
| `tar -xzf ... -C 디렉터리` | 지정한 디렉터리에 압축 해제 (x=extract, -C: Change directory) |
| `diff -rq A B` | 하위까지(r) 차이가 있는지만 간단히(q). 종료 코드 0 같음, 1 다름, 2 오류 |
| `diff -ru A B` | 다른 내용을 -와 +로 보여줌 (u: unified format) |

Git 협업

- 협업하는 이유: 실패해도 안전한 공간 → 브랜치, 합치기 전에 누군가 봐 줌 → Pull Request(코드 리뷰), 컴퓨터가 자동으로 검사 → CI
- 팀에서 쓰는 브랜치 이름 예시: `feature/기능명`(또는 `feat/기능명`), `fix/버그명`, `docs/문서명`
- 충돌 이유: 공통 조상 A를 기준으로 B(main)와 C(fix/message)가 같은 줄을 다르게 고쳤기 때문. Git은 둘 중 하나를 함부로 고르지 않는다.
- 충돌 해결 흐름: 해결 → add → commit → push → PR 업데이트 → gh pr merge
- `.gitignore`: 지정한 파일을 새로 Git 추적 대상에 넣지 않음. 이미 추적 중이면 `git rm --cached <파일명>` 또는 `git rm -r --cached <디렉터리명>`.

| Merge 옵션 | 결과 |
|---|---|
| `--merge` | 기존 커밋 유지 + merge commit 생성 |
| `--squash` | 여러 커밋을 하나로 합쳐서 반영 |
| `--rebase` | feature 브랜치의 각 커밋을 새 커밋으로 만들어 main 뒤에 일렬로 적용 |

네트워크

| 개념 | 정리 |
|---|---|
| IP 주소 | 네트워크에서 장치를 식별하는 주소 (건물 주소) |
| 공인 IP / 사설 IP | 인터넷 전체에서 유일 / 내부 네트워크에서만 유일 (192.168.x.x, 10.x.x.x, 172.16~31.x.x) |
| NAT | 공유기나 게이트웨이가 내부 사설 IP를 공인 IP와 매핑해서 인터넷과 통신 |
| 127.0.0.1 | localhost, 내 컴퓨터 자신 |
| 0.0.0.0 | 서버가 bind하면 모든 IPv4 네트워크 인터페이스에서 연결을 받음 |
| 포트 | 컴퓨터 안에서 실행 중인 서비스를 구분하는 번호 (0~65,535, Well-known 0~1023) |
| DNS | 도메인 이름에 대응하는 IP 주소를 찾음 (전화번호부) |
| TCP / UDP | TCP는 등기 우편(전달 여부 확인, 순서 보장), UDP는 빠른 우편(전달 확인 안 함, 순서 보장 없음) |

| 포트 | 용도 |
|---|---|
| 22 | SSH |
| 80 / 443 | HTTP / HTTPS |
| 3306 | MySQL |
| 6379 | Redis |
| 5000 | Flask 개발 서버에서 자주 사용 |
| 8080 | 개발용 웹 서버에서 자주 사용 |

| 응답 코드 | 의미 |
|---|---|
| 200 | OK |
| 400 | Bad Request |
| 404 | Not Found |
| 500 | Internal Server Error |
| 503 | Service Unavailable |

- TCP/IP 계층: 응용(HTTP, DNS, SSH) / 전송(TCP, UDP, 포트) / 인터넷(IP) / 링크(이더넷, WiFi)
- `cs.inhatc.ac.kr` 접속 흐름: DNS → IP → TCP 443 연결 → TLS 연결 → HTTPS 요청 → 웹 서버 → HTML 응답
