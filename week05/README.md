# 5주차 · 도커 (w/ GitHub Issue)

## 배운 내용 정리

- "내 컴퓨터에서는 되는데요?" 문제를 줄이려면 앱만 보내지 말고 실행에 필요한 라이브러리, 설정, 파일을 함께 묶어 보내면 된다. 이게 컨테이너이고, Docker는 애플리케이션을 개발(Develop), 배포(Ship), 실행(Run)하기 위한 오픈 플랫폼이다.
- 하이퍼바이저(VM)와 컨테이너의 차이, 이미지(붕어빵 틀)와 컨테이너(붕어빵)의 관계, 레지스트리, Docker의 클라이언트-서버 구조(dockerd)를 정리했다.
- Docker Desktop을 설치하고 WSL Integration을 켠 뒤 `hello-world`, `nginx` 컨테이너를 실행했다.
- `docker run`, `ps`, `logs`, `exec`, `stop`, `rm`, `images`와 `-d`, `-p`, `--name`, `-e`, `-it`, `--rm`, `-v`, `-w` 옵션을 썼고, 파이썬 3.9와 3.12를 설치 없이 컨테이너로 비교했다.
- Docker 실습을 GitHub Issue로 정의하고 Issue → Branch → 기록 → Commit/Push → PR → Merge → Issue Close 흐름으로 결과를 남겼다.

## 실습한 명령어와 코드

### 1. 설치 확인

Docker Desktop 설치 후 Settings > Resources > WSL Integration에서 Enable integration with my default WSL distro를 켜고, 사용 중인 Ubuntu 토글도 켠 다음 Apply & Restart. 로그인은 Skip 가능.

| 명령어 | 하는 일 |
|---|---|
| `docker --version` | Docker version xx.x.x, build xxxxxx |
| `docker run hello-world` | 로컬에 이미지가 없으면 받아서 실행 |

교안 출력 일부

```text
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
...
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

`permission denied while trying to connect to the docker API at unix:///var/run/docker.sock` 같은 에러가 나면 파워셸에서 아래를 실행한다. 그래도 안 되면 Docker Desktop 실행 여부와 WSL Integration을 확인한다.

```powershell
wsl --shutdown
wsl
```

맥은 `uname -m` 결과가 `arm64`면 Apple Silicon, `x86_64`면 Intel Chip용을 받는다.

### 2. nginx 컨테이너 실행

| 명령어 | 하는 일 |
|---|---|
| `cd ~/devops` |  |
| `mkdir -p week05 && cd week05` |  |
| `docker run -d -p 8080:80 --name web nginx` | 백그라운드(-d)로, 호스트 8080 → 컨테이너 80, 이름 web |

브라우저에서 http://localhost:8080 접속. 호스트에 nginx도 파이썬도 설치하지 않았는데 서버가 뜬다. nginx와 실행에 필요한 파일을 담은 이미지를 받아 컨테이너로 실행했기 때문이다.

| 명령어 | 하는 일 |
|---|---|
| `docker run -d -p 8081:80 --name web2 nginx` | 호스트 포트만 바꿔서 여러 개 |
| `docker run -d -p 8082:80 --name web3 nginx` |  |
| `docker ps` | 실행 중인 web, web2, web3 확인 |
| `docker run -d -p 8080:80 --name web4 nginx` | 포트 충돌 |
| `docker run -d -p 8084:80 --name web nginx` | 이름 충돌 |
| `docker rm -f web4` | web4 정리 |

교안의 충돌 에러

```text
... Bind for 0.0.0.0:8080 failed: port is already allocated
docker: Error response from daemon: Conflict. The container name "/web" is already in use by container ...
```

### 3. 기본 명령어

| 명령어 | 하는 일 |
|---|---|
| `docker ps` | 실행 중인 컨테이너 |
| `docker ps -a` | 멈춘 컨테이너까지 전부 |
| `docker images` | 내려받은 이미지 목록 |
| `docker logs web` | 지금까지의 로그 (docker logs <컨테이너이름>) |
| `docker logs -f web` | 실시간으로 계속 (-f: --follow, 종료 Ctrl + C) |
| `docker stop web2 web3` | 정지 → docker ps에서 안 보이고 ps -a에서 Exited 상태 |
| `docker start web2` | 다시 켜기 |
| `docker restart web3` | stop 그리고 start |
| `docker rm -f web2 web3` | 삭제 (-f: 실행 중이어도 강제), 이미지는 남아 있음 |

### 4. 컨테이너 안으로

| 명령어 | 하는 일 |
|---|---|
| `docker exec -it web bash` | 컨테이너 안에서 셸 실행 (-i: 입력 받기, -t: 가상 터미널) |

컨테이너 안 (프롬프트가 `root@<컨테이너ID>:/#` 로 바뀜)

| 명령어 | 하는 일 |
|---|---|
| `pwd` |  |
| `ls /` | 호스트 전체가 아니라 이미지의 파일만 보임 |
| `cat /etc/os-release` | Debian |
| `ls /etc/nginx/` |  |
| `cat /etc/nginx/nginx.conf` |  |
| `ls /usr/share/nginx/html/` |  |
| `cat /usr/share/nginx/html/index.html` |  |
| `echo "<h1>Hi</h1>" > /usr/share/nginx/html/index.html` | 첫 화면 수정 → 브라우저에서 Hi |
| `exit` | 나와도 컨테이너는 살아 있음 |

| 명령어 | 하는 일 |
|---|---|
| `docker rm -f web` | 컨테이너 삭제 |
| `docker run -d -p 8080:80 --name web nginx` | 같은 이미지로 새로 만들면 Hi로 바꾼 내용이 사라짐 |

### 5. Docker 활용

| 명령어 | 하는 일 |
|---|---|
| `docker run -d -p 8083:80 -e MY_NAME=Kam --name env_test nginx` | -e: 환경 변수 주입 |
| `docker exec -it env_test bash` | 안에서 echo $MY_NAME → Kam |
| `docker exec env_test env \| grep MY_NAME` | MY_NAME=Kam |
| `docker run -it --rm ubuntu:24.04 bash` | 리눅스 플레이그라운드 (--rm: 종료 시 자동 삭제) |
| `apt update && apt install -y tree` | (컨테이너 안) tree 설치 |
| `tree /etc` | (컨테이너 안) /etc 구조 보기 |
| `exit` | (컨테이너 안) 나가기 |
| `docker run --rm ubuntu:24.04 echo "hi"` | hi |
| `docker run --rm python:3.12-slim python -c "print(0.1+0.2)"` | 0.30000000000000004 (-c: command) |

서로 다른 파이썬 버전 실행하기

| 명령어 | 하는 일 |
|---|---|
| `docker run --rm python:3.9-slim python --version` | Python 3.9.25 |
| `docker run --rm python:3.12-slim python --version` | Python 3.12.14 |

`test.py` (match-case는 파이썬 3.10부터 지원)

```python
value = 2
match value:
    case 1:
        print("one")
    case 2:
        print("two")
    case _:
        print("other")
```

| 명령어 | 하는 일 |
|---|---|
| `docker run --rm -v "$PWD:/app" -w /app python:3.9-slim python test.py` | SyntaxError: invalid syntax |
| `docker run --rm -v "$PWD:/app" -w /app python:3.12-slim python test.py` | two |

| 옵션 | 뜻 |
|---|---|
| `-v "$PWD:/app"` | 현재 디렉터리를 컨테이너의 /app에 연결 |
| `-w /app` | 컨테이너의 작업 디렉터리를 /app으로 |

정리

| 명령어 | 하는 일 |
|---|---|
| `docker ps -a` | 현재 컨테이너 확인 |
| `docker system df` | 디스크 사용량 확인 |
| `docker rm -f web web2 web3 web4 env_test 2>/dev/null` | 실습 컨테이너 한 번에 제거 |

### 6. GitHub Issue로 실습 관리하기

이슈 만들기: 저장소를 웹으로 열고 Issues > New issue

```bash
cd ~/devops
gh auth status
gh repo view --web
```

이슈 제목은 `5주차 Docker 실행 환경 확인 및 nginx 실행`, 본문은 아래처럼 목표와 완료 조건을 체크박스로 적는다. 만들면 번호가 자동으로 붙는다 (교안 예시는 #6).

```markdown
## 목표

Docker 실행 환경 확인 및 nginx 컨테이너 실행

## 완료 조건

- [ ] `docker --version` 정상 출력
- [ ] `docker run hello-world` 실행
- [ ] `web`이라는 이름으로 nginx 컨테이너 실행
- [ ] 브라우저 또는 `curl`로 `http://localhost:8080` 응답 확인
- [ ] `docker ps`에서 실행 상태를 확인
- [ ] 실습 결과를 `week05/README.md`에 기록
- [ ] 수업에서 만든 컨테이너 정리
- [ ] 혼자서 해보기 완료
```

이슈 작업 브랜치

| 명령어 | 하는 일 |
|---|---|
| `git switch main` |  |
| `git pull --ff-only` | main 최신 유지 |
| `ISSUE_NO=6` | 이슈 번호를 변수에 저장 (웹에서 확인) |
| `git switch -c "docs/issue-${ISSUE_NO}-docker-start"` | 작업 브랜치 생성 |
| `git branch` | * docs/issue-6-docker-start |

실습 결과 기록 (하나씩 끝낼 때마다 이슈 체크박스에 체크)

| 명령어 | 하는 일 |
|---|---|
| `cd ~/devops/week05/` |  |
| `docker --version > docker-version.txt` |  |
| `docker info > docker-info.txt` |  |
| `docker run --rm hello-world > docker-run-hello-world.txt` |  |
| `docker run -d -p 8080:80 --name web nginx` | 포트 번호, 이름 충돌 조심 |
| `curl -I http://localhost:8080 > curl-result.txt` |  |
| `docker ps > docker-ps.txt` |  |

```bash
cat > README.md << 'EOF'
# 5주차 - Docker
... (이하 중략)
EOF
```

혼자서 해보기 (교안 과제)

1. 컨테이너 3개를 포트 8091, 8092, 8093, 이름 `nginx1`, `nginx2`, `nginx3`으로 실행
2. 각 컨테이너에 `exec`로 들어가 `index.html`을 수정해서 구분되게 만들기 (예: `Welcome to nginx1`)
3. 각 페이지를 브라우저에서 확인 후 캡처, `week05/images/`에 저장
4. `curl`로 세 페이지를 확인한 결과를 `week05/README.md`에 추가
5. `docker ps` 결과 캡처, `week05/images/`에 저장
6. 실습이 끝나면 nginx1, nginx2, nginx3, web 등 컨테이너 정리

커밋, 푸시, Pull Request

```bash
git status
git add ~/devops/week05/
git commit -m "5주차: Docker 실행 환경 및 nginx 확인 (#${ISSUE_NO})"
git push -u origin "docs/issue-${ISSUE_NO}-docker-start"
gh pr create --title "5주차: Docker" --body "Close #${ISSUE_NO}
## 작업 내용
- Docker 실행 환경 확인
- hello-world 실행

## 검증
- docker ps -a
- curl -I http://localhost:8080"
```

Merge 후 Issue 종료 확인

| 명령어 | 하는 일 |
|---|---|
| `gh pr merge --squash --delete-branch` | 교안 출력: Squashed and merged pull request #7 (5주차: Docker) |
| `git switch main` |  |
| `git pull --ff-only` |  |
| `gh issue view "$ISSUE_NO" --json state -q .state` | CLOSED (또는 웹에서 확인) |

PR 본문의 `Close #6` 때문에 Merge되면서 Issue가 자동으로 닫힌다.

## 핵심 개념 정리

하이퍼바이저(VM) 방식 vs 컨테이너 방식

| 구분 | 하이퍼바이저(VM) | 컨테이너 |
|---|---|---|
| 구조 | 하드웨어 → 호스트 OS → 하이퍼바이저 → VM마다 Guest OS + 앱 | 하드웨어 → 호스트 OS(커널 공유) → Docker 엔진 → 앱 |
| 무게 | 무겁다 (VM마다 Guest OS 필요) | 커널 공유 |
| 시작 | 상대적으로 느림 | 일반적으로 빠름 |
| 이미지 크기 | 크다 (기가바이트 단위) | 작다 (메가바이트 단위) |
| 격리 | 강한 격리 | 프로세스 수준으로 격리 |

Docker 구성 요소

| 요소 | 뜻 |
|---|---|
| Image | 컨테이너를 만들기 위한 읽기 전용 템플릿 (붕어빵 틀) |
| Container | 이미지로부터 생성된 인스턴스 (붕어빵). 실행/정지 가능, 쓰기 가능, 삭제하면 쓰기 계층이 사라짐 |
| Dockerfile | 이미지를 어떻게 만들지 작성하는 파일 (다음 주) |
| Registry | 이미지를 저장하고 공유하는 곳 (Docker Hub, ghcr.io) |
| dockerd | docker 클라이언트의 요청을 받아 실제로 이미지와 컨테이너를 관리하는 데몬 |

- 이미지 하나로 컨테이너를 몇 개든 만들 수 있다 (클래스와 객체 관계와 비슷).
- 이미지 = 프로그램과 실행 환경을 함께 압축한 파일. 컨테이너를 실행하면 격리된 환경 안에서 프로그램이 프로세스로 실행된다.
- namespace: 시야 격리 ("안 보이게 만들기"). 컨테이너 안 메인 프로세스는 PID 1, 자기만의 네트워크, `ls /`로 이미지 파일만 보임.
- cgroup: 자원 사용량 제한 ("많이 못 쓰게 만들기"). 메모리 상한, CPU 제한.

`docker run` 옵션

| 옵션 | 의미 |
|---|---|
| `-d` | detached, 백그라운드 실행 (안 붙이면 터미널이 묶임) |
| `-p 8080:80` | publish, 호스트 포트 8080 → 컨테이너 포트 80 |
| `--name web` | 컨테이너 이름(별명) 지정 |
| `-e KEY=값` | 환경 변수 주입 |
| `-it` | `-i`(stdin 열기) + `-t`(가상 터미널 할당) |
| `--rm` | 종료하면 컨테이너 자동 삭제 |
| `-v "$PWD:/app"` | 디렉터리 연결 |
| `-w /app` | 작업 디렉터리 지정 |

이슈 기반 작업 흐름

| 단계 | 의미 |
|---|---|
| Issue | 무엇을, 왜 할 것인가 (오류만 적는 곳이 아님, 완료 조건이 있는 하나의 작업) |
| Branch | 해당 작업을 안전하게 진행하는 공간 |
| Pull Request | 변경 내용을 검토하고 합쳐 달라는 요청 |
| Merge | 변경 내용 반영 |

- PR 본문에 `Close #이슈번호`가 있으면 Merge될 때 이슈가 자동으로 종료된다. 쓸 수 있는 단어: close, closes, closed / fix, fixes, fixed / resolve, resolves, resolved
