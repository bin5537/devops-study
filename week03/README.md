# 3주차 · 셸 스크립팅

## 배운 내용 정리

- 매일 반복하는 작업을 사람이 직접 하면 시간도 들고 실수도 생긴다. 반복하는 명령어를 셸 스크립트 파일로 만들어 두면 같은 절차를 똑같이 실행할 수 있다.
- Ollama(로컬 LLM 실행 서버)에 Qwen 모델(`qwen3:0.6b`)을 받아 두고, 파이썬 웹앱 `chat.py`를 실행해서 브라우저에서 대화하는 로컬 AI 서비스를 띄웠다.
- 경로를 외워서 `cd`를 여러 번 치는 대신 `start.sh`를 만들고 shebang, 실행 권한, `cd "$(dirname "$0")" || exit 1`, `exec`의 의미를 한 줄씩 분석했다.
- `export`로 환경 변수(`MODEL`, `WEB_PORT`)를 넘겨 실행 설정을 바꾸고, 히어독(heredoc)으로 스크립트 파일을 만들었다.
- `if ! command -v python3 ...` 조건문으로 실행 환경을 점검하고, 표준 출력/표준 오류/종료 상태를 구분했다.

## 실습한 명령어와 코드

### 1. Ollama 설치와 Qwen 모델 받기 (Ubuntu 터미널에서)

| 명령어 | 하는 일 |
|---|---|
| `sudo apt update` |  |
| `sudo apt install -y python3 curl zstd` | 필요한 패키지 |
| `curl -fsSL https://ollama.com/install.sh \| sh` | Ollama 설치 스크립트 실행 |
| `ollama --version` | 설치 확인 |
| `python3 --version` |  |
| `curl -fsS http://127.0.0.1:11434/api/tags` | JSON이 나오면 Ollama 서버가 응답한 것 |
| `ollama serve` | 서버 연결이 안 될 때만 실행 |
| `ollama pull qwen3:0.6b` | 모델 다운로드 (크기까지 정확히) |
| `ollama list` | 받은 모델 목록 |

`curl .../api/tags` 결과가 `{"models":[]}`이면 서버는 응답하지만 모델 목록은 비어 있는 상태다.

사전 응답 점검 (Ollama 생성 API 직접 호출)

```bash
curl --max-time 90 -fsS http://127.0.0.1:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen3:0.6b", "prompt":"안녕! 한 문장으로 인사해 봐!", "think":false, "stream":false, "options":{"num_ctx":8192,"num_predict":512}}'
```

| 옵션 | 뜻 |
|---|---|
| `"stream":false` | 응답을 한 번에 보여주기 |
| `"think":false` | 생각 모드 끄기 |

많이 기다린 뒤 JSON의 `"response"`에 답이 나온다 (교안 예시는 `"response":"안녕하세요!"`, 결과는 매번 달라질 수 있음).

### 2. 웹 브라우저에서 열기

| 명령어 | 하는 일 |
|---|---|
| `cd ~/devops` |  |
| `mkdir -p week03/qwen-web` | -p: 필요한 상위 디렉터리까지 함께 생성 |
| `cd week03/qwen-web` |  |
| `pwd` |  |
| `explorer.exe .` | 탐색기 창을 열어 chat.py를 드래그해서 넣기 |
| `cp "/mnt/c/Users/PC/Downloads/chat.py" .` | 또는 터미널로 복사 (맨 끝의 . 주의) |
| `ls -l` |  |
| `python3 chat.py` | 웹앱 실행, 브라우저에서 http://localhost:8000 |

교안의 실행 화면

```text
웹 접속: http://localhost:8000
사용 모델: qwen3:0.6b
종료: Ctrl+C
```

다른 모델을 쓰려면 `ollama pull qwen3:1.7b`로 받고 `nano chat.py`로 모델을 수정한 뒤 `!python3`(가장 최근 python3 명령 재실행)으로 다시 실행한다.

### 3. start.sh 만들기

| 명령어 | 하는 일 |
|---|---|
| `nano start.sh` | 작업 디렉터리(~/devops/week03/qwen-web)에서 생성, 저장 Ctrl+O → Enter, 종료 Ctrl+X |

```bash
#!/bin/bash
cd "$(dirname "$0")" || exit 1
exec python3 chat.py
```

| 줄 | 하는 일 |
|---|---|
| `#!/bin/bash` | shebang. 이 파일은 Bash 문법이니 Bash로 실행하라고 OS에 알림. 파일 첫 줄에 작성 |
| `cd "$(dirname "$0")" \|\| exit 1` | 스크립트가 있는 디렉터리로 이동하고, 이동에 실패하면 상태 코드 1로 종료 |
| `exec python3 chat.py` | 현재 bash 프로세스를 python3로 바꿔서 실행 (PID 유지) |

| 명령어 | 하는 일 |
|---|---|
| `./start.sh` | 처음엔 Permission denied |
| `ls -l` | 실행 권한(x)이 없는 걸 확인 |
| `chmod u+x start.sh` | 소유자에게 실행 권한 부여 |
| `ls -l` |  |
| `./start.sh` | 실행됨 |
| `cd ~` |  |
| `./devops/week03/qwen-web/start.sh` | 다른 위치에서 실행해도 스크립트 위치 기준으로 동작 |

shebang을 파이썬으로 이해하기 (`run_py.sh`)

```bash
#!/usr/bin/env python3
# PATH에서 python3를 찾아서 실행 (#!/usr/bin/python3 처럼 직접 경로를 써도 됨)
print('Hello, DevOps!')
```

| 명령어 | 하는 일 |
|---|---|
| `chmod +x run_py.sh` |  |
| `./run_py.sh` | Hello, DevOps! |

### 4. 환경 변수로 설정 넘기기 (heredoc)

```bash
cat > start_with_export.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")" || exit 1
export MODEL="qwen3:0.6b"      # 이 스크립트 안에서만 바뀜, 원래 터미널의 환경 변수는 그대로
exec ./start.sh
EOF
chmod u+x start_with_export.sh
./start_with_export.sh
```

실습: 포트를 8080으로 바꿔서 실행하고 http://localhost:8080 으로 확인

```bash
cat > start_with_export_2.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")" || exit 1
export WEB_PORT="8080"
exec ./start.sh
EOF
chmod u+x start_with_export_2.sh
./start_with_export_2.sh
```

`cat > 파일 << 'EOF'`는 입력한 여러 줄을 파일에 저장하다가 `EOF` 줄이 나오면 입력을 끝낸다. `EOF` 대신 `END`, `FINISH`처럼 다른 문자열을 써도 된다.

### 5. 조건문으로 친절한 스크립트 만들기

`exec python3 chat.py` 바로 위에 검사 코드를 추가한다.

```bash
#!/bin/bash
cd "$(dirname "$0")" || exit 1
if ! command -v python3 >/dev/null 2>&1; then    # python3를 찾을 수 없다면
    echo "Python3를 먼저 설치하세요." >&2         # 오류 메시지로 출력 (표준 오류)
    exit 1                                       # 실패 상태로 종료
fi
exec python3 chat.py
```

| 명령어 | 하는 일 |
|---|---|
| `command -v python3` | 명령어가 있으면 경로 출력 (예: /usr/bin/python3) |
| `echo $?` | 직전 명령의 종료 코드 출력, 0이면 정상 종료 |

[참고] OS별로 설치 방법까지 안내하는 버전

```bash
if ! command -v python3 >/dev/null 2>&1; then
    echo "Python3가 설치되어 있지 않습니다." >&2
    if [ "$(uname)" = "Darwin" ]; then
        echo "[Mac] 다음 명령으로 설치하세요." >&2
        echo "  brew install python" >&2
    else
        echo "[Windows(WSL)/Ubuntu] 다음 명령으로 설치하세요." >&2
        echo "  sudo apt update" >&2
        echo "  sudo apt install python3 -y" >&2
    fi
    exit 1
fi
exec python3 chat.py
```

## 핵심 개념 정리

로컬 AI 서비스 구조

| 구성 | 주소 | 역할 |
|---|---|---|
| 브라우저 | http://localhost:8000 | 질문 전송, 답변 표시 |
| Python 웹앱 `chat.py` | 127.0.0.1:8000 | 질문을 API로 전달 (파이썬 표준 라이브러리만 사용) |
| Ollama 서버 | 127.0.0.1:11434 | 모델 실행 |
| `qwen3:0.6b` | - | 답변을 만드는 모델 (Ollama 목록 기준 약 523MB) |

셸 스크립트 문법

| 문법 | 의미 |
|---|---|
| `#!` | shebang. 어떤 인터프리터로 실행할지 지정 |
| `$0` | 현재 실행한 스크립트의 이름 또는 경로 |
| `$1`, `$2` | 첫 번째, 두 번째 인자 |
| `$#` | 전달받은 인자 개수 |
| `$@` | 전달받은 모든 인자 |
| `$?` | 직전에 실행한 명령의 종료 상태 |
| `$( ... )` | 명령어 치환. 괄호 안 명령을 실행하고 그 표준 출력을 그 자리에 넣음 |
| `dirname` | 경로에서 파일 이름을 빼고 디렉터리 부분만 출력 |
| `A \|\| B` | 논리 OR. A가 실패하면 B를 실행 |
| `exit 1` | 실패를 뜻하는 상태 코드 1을 남기고 종료 |
| `exec` | 현재 셸 프로세스를 다른 프로그램으로 교체 (PID 유지) |
| `export` | 환경 변수로 지정해서 실행하는 프로그램에 설정 전달 |
| `command -v` | 명령어가 있으면 경로를 출력, 없으면 아무것도 출력하지 않고 실패 상태 반환 |
| `>/dev/null` | 표준 출력을 버림 (`/dev/null`은 일종의 쓰레기통) |
| `2>&1` | 2번 표준 오류를 1번 표준 출력이 가는 곳으로 보냄 |
| `>&2` | 출력을 일반 출력이 아닌 오류 메시지(표준 오류)로 |

- 0: 표준 입력(stdin), 1: 표준 출력(stdout), 2: 표준 오류(stderr)
- 종료 상태는 성공이 0, 실패는 0 이외. `cd`가 성공하면 0, 없는 디렉터리면 1.
- 파라미터 수를 뜻하는 `b`는 Billion(10억). `0.6b`는 약 6억 개. 파라미터가 클수록 비슷한 조건에서는 성능이 높지만 응답이 느리고 저장 공간과 메모리가 더 필요하다.
