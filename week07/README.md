# 7주차 · 도커 컴포즈

## 배운 내용 정리

- 지난주 방명록은 글을 프로세스 메모리에 저장해서 재시작하면 사라졌다. 앱과 DB(Redis)를 각자 다른 컨테이너로 띄우고 연결해서 해결했다. 컨테이너 하나 = 역할 하나.
- Docker Compose는 여러 컨테이너를 하나로 합치는 도구가 아니라, 독립된 컨테이너들이 함께 동작하도록 `compose.yaml`(코드)로 구성하고 관리하는 도구다. 같은 네트워크에서는 서비스 이름(`redis`)이 곧 DNS 이름이다.
- 볼륨은 컨테이너 밖에 데이터를 보관한다. `down`은 데이터를 남기고 `down -v`는 볼륨까지 지운다. `ports:`가 없는 서비스는 호스트에 노출되지 않는다.
- 컴포즈 다듬기 4단계: `.env`로 비밀번호 분리 → healthcheck로 '준비 완료' 확인 → `--scale web=3` + nginx 리버스 프록시로 요청 분배 → `config`로 미리 검사, `watch`로 자동 반영.
- 호기심 실험: web 3개 중 하나를 `docker stop` 하면 남은 2개가 응답해서 서비스는 살아 있지만, 멈춘 web은 아무도 다시 살리지 않는다.

## 실습한 명령어와 코드

### 들어가며: 지난주 문제 재현

| 명령어 | 하는 일 |
|---|---|
| `cd ~/devops/guestbook` |  |
| `docker run -d -p 8080:5000 --name gb guestbook:v1` | 브라우저에서 방명록에 글 3개 남기기 |
| `docker restart gb` | 새로고침하면 글이 모두 사라짐 (배지: 저장소 Memory) |

`docker run`만으로 여러 컨테이너를 연결하면 이렇게 된다 (교안에서 눈으로만 본 예제). 매번 타이핑하다 오타가 나거나 팀원에게 전파하기 어렵기 때문에 파일에 적어 둔다.

```bash
docker network create mynet
docker run -d --name redis --network mynet redis:7-alpine ...
docker run -d --name web --network mynet -p 8080:5000 \
  -e REDIS_HOST=redis -e REDIS_PASSWORD=... guestbook:v1
```

### 실습 1: compose.yaml 작성과 실행

| 명령어 | 하는 일 |
|---|---|
| `cd ~/devops/guestbook` |  |
| `docker rm -f gb` | 기존 컨테이너 정리 |
| `nano -ET2 compose.yaml` | -E: Tab을 공백으로, -T2: 탭 너비 2칸 (복붙 금지, 한 줄씩 타이핑) |
| `docker compose config -q` | YAML 유효성 검사 (-q: quiet) |

```yaml
services:
  web:
    build: .                      # 같은 폴더의 Dockerfile로 빌드
    ports:
      - "8080:5000"               # 호스트 8080 → 컨테이너 5000
    environment:
      APP_TITLE: "방명록"
      REDIS_HOST: "redis"          # IP가 아니라 서비스 이름
      REDIS_PORT: "6379"
      REDIS_PASSWORD: "devops1234"
    depends_on:
      - redis                     # redis를 먼저 시작
    restart: unless-stopped       # 예상치 않게 종료 시 자동 재시작
  redis:
    image: redis:7-alpine         # 이미 있는 이미지 사용
    command: ["redis-server",
      "--requirepass", "devops1234",
      "--appendonly", "yes"]      # --requirepass로 비밀번호 지정
    volumes:
      - redis-data:/data          # 볼륨을 컨테이너의 /data에 연결

volumes:
  redis-data:                     # 볼륨 선언
```

| 명령어 | 하는 일 |
|---|---|
| `docker compose up -d` | 명령 하나로 네트워크 1개 + 볼륨 1개 + 컨테이너 2개 |
| `docker compose ps` |  |
| `docker compose logs web` |  |
| `docker compose logs -f web` | Ctrl+C 하면 로그 보기만 끝나고 컨테이너는 계속 실행 |

교안 출력

```text
[+] up 5/5
 ✔ Image guestbook-web          Built
 ✔ Network guestbook_default    Created
 ✔ Volume guestbook_redis-data  Created
 ✔ Container guestbook-redis-1  Started
 ✔ Container guestbook-web-1    Started

[INFO] Redis 연결 성공: redis:6379
```

브라우저(http://localhost:8080)에서 제목이 "방명록"으로, 배지가 "저장소: Redis"로 바뀌었는지 확인하고 글을 2~3개 남긴다.

| 명령어 | 하는 일 |
|---|---|
| `docker compose restart web` | web만 재시작 → 글이 그대로 (데이터는 redis 쪽에 있음) |
| `docker compose down` | 컨테이너, 네트워크 전부 삭제 |
| `docker compose ps` | 아무것도 없음 |
| `docker compose up -d` | 다시 생성 → 글이 여전히 남아 있음 (볼륨은 기본적으로 삭제되지 않음) |
| `docker volume ls` | local  guestbook_redis-data |
| `docker volume inspect guestbook_redis-data` |  |
| `docker compose down -v` | -v: 볼륨까지 삭제 |
| `docker compose up -d` | 이번에는 글이 사라짐 |

### 실습 2: 네트워크 격리

| 명령어 | 하는 일 |
|---|---|
| `python3 -c "import socket; socket.create_connection(('127.0.0.1', 6379), timeout=2)"` | ConnectionRefusedError: [Errno 111] Connection refused → redis에 ports:가 없어서 호스트에서 직접 접속 불가 |
| `docker compose exec web sh` | web 컨테이너 안으로 |
| `python -c "import socket; print(socket.gethostbyname('redis'))"` | 172.18.0.2 (교안 예시), redis라는 이름이 IP로 해석됨 |
| `exit` |  |

```bash
docker compose exec web python -c \
  "import socket; socket.create_connection(('redis', 6379), 2); print('TCP 연결 성공')"   # TCP 연결 성공
```

### 실습 3: 컴포즈 다듬기

```text
브라우저 :8080
      │
  [ nginx ]        3-3 문지기 (요청을 나눠준다)
   │   │   │
 [web][web][web]   3-3 --scale web=3 / 3-2 healthcheck
      │
  [ redis ]        3-1 비밀번호는 .env에서
```

한꺼번에 고치면 어디서 틀렸는지 모르니까 하나 고치고 바로 확인한다.

#### 3-1 `.env`로 비밀번호 분리

| 명령어 | 하는 일 |
|---|---|
| `cd ~/devops/guestbook` |  |
| `echo "REDIS_PASSWORD=devops1234" > .env` | 실제 값 (내 컴퓨터에만) |
| `echo "REDIS_PASSWORD=비밀번호" > .env.example` | 친구에게 보여줄 양식 |
| `echo ".env" >> ~/devops/.gitignore` | 실제 값은 Git에 올리지 않기 (암호화는 아님) |

`compose.yaml`의 비밀번호 자리 두 군데를 바꾼다.

```yaml
      REDIS_PASSWORD: "${REDIS_PASSWORD:?비밀번호 설정 필요}"   # web의 environment, 비어 있으면 이 메시지로 중단
    command: ["redis-server", "--requirepass", "${REDIS_PASSWORD}", "--appendonly", "yes"]   # redis
```

#### 3-2 healthcheck

```yaml
  web:
    depends_on:
      redis:                          # "- redis"에서 - 제거 후 : 추가
        condition: service_healthy    # redis가 healthy가 될 때까지 web 시작 보류
    healthcheck:
      test: ["CMD", "python", "-c",
        "import urllib.request;
        urllib.request.urlopen(
        'http://localhost:5000/readyz')"]   # curl이 없어서 python으로 /readyz 열어 보기
      interval: 5s                    # 5초마다 점검
      timeout: 3s                     # 3초 안에 안 끝나면 실패로 봄
      retries: 5                      # 5번 연속 실패하면 unhealthy
  redis:
    healthcheck:                      # volumes 밑에 추가
      test: ["CMD", "redis-cli", "-a",
        "${REDIS_PASSWORD}", "ping"]  # ping을 보내고 pong이 오면 성공 (수업용)
      interval: 5s
      timeout: 3s
      retries: 5
```

수업 자료 zip(`guestbook-week07.zip`)의 `compose.yaml`은 redis healthcheck를 `CMD-SHELL`과 `REDISCLI_AUTH=${REDIS_PASSWORD} redis-cli --raw ping | grep -qx PONG`으로 쓰고 있다.

| 명령어 | 하는 일 |
|---|---|
| `docker compose down && docker compose up -d` |  |
| `docker inspect --format '{{.State.Health.Status}}' guestbook-redis-1` | healthy |

교안 출력 (redis가 Healthy가 된 다음 web 시작)

```text
[+] up 3/3
 ✔ Network guestbook_default    Created
 ✔ Container guestbook-redis-1  Healthy
 ✔ Container guestbook-web-1    Started
```

#### 3-3 scale과 nginx

| 명령어 | 하는 일 |
|---|---|
| `docker compose up -d --scale web=3` | Error ... port is already allocated (web 3개가 전부 8080을 쓰려고 함) |

`ports:`를 빼면 3개가 뜨기는 하지만 호스트에 공개된 포트가 없어서 브라우저로 들어갈 수 없다. 공개된 포트에서 요청을 받아 나눠 주는 문지기(nginx)를 둔다.

`guestbook/nginx.conf`

```nginx
server {
    listen 80;                          # 컨테이너 안의 80번에서 대기 (8080과는 ports로 연결)
    resolver 127.0.0.11 valid=5s;       # 도커 내부 DNS 주소, 받은 답은 5초만 믿고 다시 물어봄
    location / {
        set $backend http://web:5000;   # 변수에 web:5000 저장
        proxy_pass $backend;            # 받은 요청을 그 주소로 대신 전달 (프록시)
    }
}
```

`compose.yaml`에 nginx 서비스를 추가하고 web의 `ports`를 `expose`로 바꾼다.

```yaml
services:
  nginx:
    image: nginx:alpine
    ports:
      - "8080:80"                                         # 바깥 문은 nginx만 연다
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro    # 내 nginx.conf를 그대로 연결 (바인드 마운트, ro: 읽기 전용)
    depends_on:
      web:
        condition: service_healthy
  web:
    build: .
    expose:                                               # ports를 expose로 변경
      - "5000"                                            # "8080:5000"을 "5000"으로, 호스트에 게시하지 않음
    ...
```

```bash
docker compose up -d --scale web=3
docker compose ps
docker ps --format "{{.ID}} {{.Names}}"
```

교안 출력

```text
8b91436d0db0 guestbook-nginx-1
27b6ea9eb146 guestbook-web-2
f0d1f9713261 guestbook-web-1
ce2c86e5602c guestbook-web-3
83371cc32a24 guestbook-redis-1
```

브라우저를 새로고침할 때마다 화면의 Pod/Host 이름이 바뀐다 (서로 다른 web 컨테이너가 응답, `docker ps`의 ID와 비교). 글은 어느 web으로 가도 똑같다. 데이터는 하나의 redis에 있기 때문이다. 앱은 여러 개, DB는 한 개.

#### 호기심: web 하나를 멈추면? (48쪽)

| 명령어 | 하는 일 |
|---|---|
| `docker stop guestbook-web-2` | web-2 멈추기 |
| `docker compose ps` | 확인하기 |
| `for i in 1 2 3 4 5 6; do curl -s -o /dev/null -w "%{http_code} " localhost:8080; done` | 6번 요청해서 상태 코드만 출력 |

```text
200 200 200 200 200 200
```

- 에러 없이 남은 web 2개가 번갈아 응답한다. 서비스는 살아 있다. (일시적으로 502 오류가 날 수도 있다. 보장되는 결과는 아니다.)
- 멈춘 web은 살아나지 않는다. `docker stop`으로 직접 중지했기 때문에 `restart: unless-stopped`가 있어도 자동으로 다시 실행하지 않는다.
- 다시 3개로 돌리려면 사람이 직접 `docker compose up -d --scale web=3`을 입력해야 한다.
- 도커도 종료된 컨테이너를 자동으로 재시작할 수는 있다. 그런데 서버 자체가 고장 나거나 원하는 컨테이너 수가 유지되지 않는 경우는? 교안에서는 "다음 시간에"로 넘어갔다.

#### 3-4 config로 미리 검사, watch로 자동 반영

| 명령어 | 하는 일 |
|---|---|
| `docker compose config --quiet && echo OK` | 문제 없으면 종료 코드 0 → OK 출력 |
| `docker compose config \| grep requirepass -A1` | .env 값이 실제로 들어갔는지 (-A1: 아래 1줄까지) |
| `mv .env .env.bak && docker compose config > /dev/null; mv .env.bak .env` | .env 없을 때 오류 보기, ;는 성공/실패 관계없이 다음 명령 실행 |
| `REDIS_PASSWORD= docker compose config --quiet` | 더 간단하게 오류 메시지 보기 |

교안 출력

```text
error while interpolating services.web.environment.REDIS_PASSWORD: required variable REDIS_PASSWORD is missing a value: 비밀번호 설정 필요
```

web에 `develop.watch`를 추가한다 (`restart:` 아래).

```yaml
  web:
    develop:
      watch:
        - action: rebuild         # 파일이 바뀌면 이미지를 다시 빌드하고 해당 서비스 컨테이너를 재생성
          path: ./app.py
        - action: rebuild
          path: ./templates
```

| 명령어 | 하는 일 |
|---|---|
| `docker compose up --watch` | 방법 1: 실행과 감시를 동시에 (Ctrl + C 하면 컨테이너도 중지) |
| `docker compose up -d --scale web=3` | 방법 2 - 터미널 1 |
| `docker compose watch --no-up` | 방법 2 - 터미널 2: 이미 실행 중인 컨테이너 감시 (Ctrl + C 하면 watch만 종료) |

방법 2로 띄워 두고 터미널 1에서 `templates/index.html`을 고쳐 저장한 뒤 터미널 2를 확인한다.

### 요즘 도커 (시연)

| 명령어 | 하는 일 |
|---|---|
| `docker ai "지금 compose.yaml이 위험한 이유는?"` | Gordon |
| `docker model pull ai/smollm2` | 작은 LLM 받기 |
| `docker model run ai/smollm2 "도커 컴포즈를 한 문장으로 설명해줘"` |  |
| `docker model pull ai/qwen3` |  |
| `docker agent run --safety strict agent.yaml "지금 compose 상태를 확인하고, 문제가 있으면 설명해줘"` |  |

`agent.yaml`은 compose처럼 YAML로 AI 에이전트를 설정한다 (`agents:`, `model: dmr/ai/qwen3`, `instruction:`, `toolsets: shell, think`). 교안 예시의 instruction에는 지우는 명령(down -v, rm, volume rm)은 실행하지 않는다고 적혀 있다.

### 기록하기 (혼자 해보기)

`week07/README.md`에 남길 것: `docker compose ps` 결과(healthy 포함), scale 후 웹 컨테이너 호스트명(컨테이너 ID)이 바뀐 화면, `down` 후 `up`과 `down -v` 후 `up`의 차이, `.env`를 Git에 올리지 않는 이유.

| 명령어 | 하는 일 |
|---|---|
| `cd ~/devops` |  |
| `git add guestbook week07 .gitignore` |  |
| `git status` | compose.yaml, nginx.conf, .env.example은 포함 / .env는 없어야 함 |
| `git commit -m "week07: compose + nginx + healthcheck"` |  |
| `git push` |  |
| `git tag week07` |  |
| `git push origin week07` |  |

## 핵심 개념 정리

음악 비유

| 음악 | 도커 컴포즈 |
|---|---|
| 각각의 악기 연주자 | 각각의 컨테이너 |
| 악보 | compose.yaml |
| 악기별 연주 파트 | services |
| 연주자들이 함께 연주 | 여러 컨테이너가 협력하여 실행 |
| 지휘자의 연주 시작 지시 | docker compose up |

docker run과 compose.yaml 비교 (환경 변수 우선순위도 그대로: 코드 기본값 < Docker ENV < compose environment)

| docker run | compose.yaml |
|---|---|
| `-p 8080:5000` | `ports: ["8080:5000"]` |
| `-e KEY=value` | `environment: {KEY: value}` |
| `--name web` (컨테이너 이름) | 서비스 이름 `web` (컨테이너 이름은 아님) |
| `-v data:/path` | `volumes: [data:/path]` |
| `-d` | `docker compose up -d` |

compose.yaml 키 (추천 순서, 정해진 규칙은 아님)

| 키 | 질문 |
|---|---|
| `image`, `build` | 어떤 이미지로 실행할 것인가? (`build`: Dockerfile로 빌드, `image`: 이미 있는 이미지) |
| `command` | 무엇을 실행할 것인가? |
| `ports`, `expose` | 어떤 포트를 사용할 것인가? |
| `environment` | 어떤 설정값을 전달할 것인가? |
| `volumes` | 어디에 파일과 데이터를 저장할 것인가? |
| `depends_on` | 어떤 서비스에 의존하는가? |
| `healthcheck` | 정상 상태를 어떻게 확인할 것인가? |
| `restart` | 종료되었을 때 어떻게 할 것인가? |
| `develop` | 개발 중 파일 변경을 어떻게 반영할 것인가? |

`.env` 정리

| 파일/문법 | 하는 일 |
|---|---|
| `.env` | `이름=값`을 한 줄씩 작성 (공백, 따옴표 없이). compose.yaml과 같은 폴더에 있으면 자동 반영 |
| `${REDIS_PASSWORD}` | 실행할 때 .env 값으로 바뀌어 들어가는 빈칸 |
| `${REDIS_PASSWORD:?메시지}` | 필수 값 검사, 비어 있으면 메시지와 함께 중단 |
| `.env.example` | 어떤 값이 필요한지 알려 주는 양식 (옵션) |
| `.gitignore`의 `.env` | 실수로 커밋하는 것 방지 |
| `.dockerignore`의 `.env` | `COPY . .`을 해도 이미지 안에 들어가지 않음 |

healthcheck

- `depends_on`만 쓰면: Redis 시작 → Web 시작 → Web이 Redis 연결 시도 → Redis가 준비 중이면 실패
- `service_healthy`를 쓰면: Redis 시작 → healthcheck 통과 → Web 시작 → 연결 시도
- `test`의 종료 코드 0이 정상. 상태는 starting → healthy 또는 unhealthy. `/readyz`는 Redis 연결이 안 되면 503.

scale, nginx

| 용어 | 뜻 |
|---|---|
| `--scale web=3` | web 서비스 컨테이너를 총 3개 실행 |
| scale-out / scale-in | 컨테이너나 서버 개수 늘리기 / 줄이기 (수평) |
| scale-up / scale-down | 개별 서버의 CPU, 메모리 높이기 / 줄이기 (수직) |
| 리버스 프록시 | 클라이언트 요청을 대신 받아 내부 서버에 전달 |
| 로드 밸런싱 | 들어온 요청을 여러 web에 분산 (은행 안내 데스크) |
| `ports` | 컨테이너 포트를 호스트에 게시 |
| `expose` | 컨테이너 내부 서비스의 사용 포트 명시, 호스트에 게시하지 않음 |

정리

| 도구 | 범위 |
|---|---|
| docker run | 개별 컨테이너를 직접 실행하고 관리 |
| docker compose | 여러 컨테이너의 구성을 정의하고 단일 도커 엔진 환경에서 관리 |
| Kubernetes | 여러 컴퓨터에 걸쳐 컨테이너 기반 서비스를 실행하고 원하는 상태가 유지되도록 자동 관리 |

## 호기심 해결: web 3개 항상 유지하기

48쪽 호기심 문제(멈춘 web은 아무도 다시 살리지 않음)를 지금까지 배운 셸 스크립트로 해결한 결과. 설명과 장단점은 보고서 4번 항목에 있다.

- 스크립트: [guestbook/keep-web3.sh](./guestbook/keep-web3.sh)
- 실험 스크립트와 기록: [guestbook/experiment/](./guestbook/experiment/)

동작: '원하는 개수(3)'와 '실제로 실행 중인 개수'를 5초마다 비교해서, 모자라면 `docker compose up -d --scale web=3`을 실행한다.

| 명령어 | 하는 일 |
|---|---|
| `cd ~/devops/week07/guestbook` |  |
| `./keep-web3.sh 3 5 > keep-web3.log 2>&1 &` | web 3개, 5초마다 확인 (백그라운드) |
| `docker stop guestbook-web-2` | 사고 내기 |
| `tail -f keep-web3.log` | 몇 초 뒤 '복구 완료: web 3개' |

실험 결과 (experiment/results.txt)

| 사고 | 감시 스크립트 없이 | 감시 스크립트 켜고 |
|---|---|---|
| `docker stop guestbook-web-2` | 계속 Exited, 2개로 운영 | 발견 후 9초 만에 다시 3개 |
| `docker rm -f guestbook-web-3` | 계속 2개 | 발견 후 5초 만에 새로 만들어 3개 |
| web 2개 동시에 `docker stop` | (실험 안 함) | 발견 후 6초 만에 3개 |
| 앱 프로세스가 스스로 죽음 | `restart: unless-stopped`로 약 2초 만에 재시작 | (재시작 정책이 먼저 처리) |
