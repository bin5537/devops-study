# 2주차 · 실습 환경 구축과 버전 관리 기초

## 배운 내용 정리

- 서버는 하드웨어이기도 하고 소프트웨어이기도 하다. 서버를 운영하는 방식으로 베어메탈, 하이퍼바이저(가상 머신), 컨테이너를 비교했다.
- 윈도우에서 WSL2로 Ubuntu를 설치해서 리눅스 실습 환경을 만들었다. 작업 공간은 리눅스 전용 공간인 `~/devops`.
- 파일, 디렉터리, 권한을 다루는 기본 리눅스 명령어와 `history`, `!!` 같은 편의 기능을 익혔다.
- Git으로 커밋을 만들고, 예전 커밋으로 이동하거나 비교하고, 브랜치를 나눠서 작업하는 방법을 배웠다.
- GitHub CLI(`gh`)로 로그인하고 저장소를 만들어 푸시한 뒤, README.md에 주차별 내용을 정리하는 방식을 배웠다.

## 실습한 명령어와 코드

### 1. WSL2 설치 (파워셸)

파워셸은 설치할 때만 관리자 권한으로 실행한다.

| 명령어 | 하는 일 |
|---|---|
| `wsl -l -v` | 설치된 배포판 목록 확인 (-l: list, -v: verbose) |
| `wsl --install` | WSL 기능, 가상 머신 플랫폼 활성화 + 리눅스 커널 + 기본 Ubuntu 설치 |
| `wsl --install -d Ubuntu` | 제대로 설치되지 않았을 때 배포판을 지정해서 설치 (-d: distribution) |
| `wsl --unregister Ubuntu` | 배포판 제거 |
| `wsl --list --online` | 설치할 수 있는 배포판 목록 (--list는 -l의 긴 옵션) |
| `wsl --install -d Ubuntu-24.04` | 특정 버전의 Ubuntu 설치 |
| `wsl --set-version Ubuntu-24.04 2` | 이미 설치된 Ubuntu-24.04를 WSL 2로 변경 |
| `wsl --set-default-version 2` | 앞으로 설치할 배포판의 기본 버전을 2로 |
| `wsl --set-default Ubuntu-24.04` | wsl만 입력했을 때 실행될 기본 배포판 지정 |
| `wsl` | 기본 Ubuntu 실행 |
| `wsl -d Ubuntu-24.04` | 특정 배포판 실행 |

교안의 `wsl -l -v` 예시 출력 (`*`는 wsl만 입력했을 때 실행될 기본 배포판)

```text
  NAME            STATE           VERSION
* Ubuntu          Stopped         2
  Ubuntu-24.04    Stopped         2
```

Ubuntu 터미널에서 `exit`를 입력하면 파워셸로 돌아온다. 처음 실행하면 아이디, 비밀번호를 영문 소문자로 입력한다.

### 2. Ubuntu 사용 준비

| 명령어 | 하는 일 |
|---|---|
| `cd ~` | 리눅스 전용 공간(홈 디렉터리)으로 이동 |
| `mkdir ~/devops` | 나의 작업 공간 만들기 |
| `cd ~/devops` |  |
| `pwd` | 현재 위치 확인 |
| `sudo apt update` | 패키지 목록을 최신 상태로 갱신 |
| `sudo apt upgrade -y` | 패키지 업그레이드 (선택, -y: 중간 yes/no 질문에 자동으로 yes) |
| `sudo apt install <패키지이름>` | 패키지 설치 (apt: advanced package tool) |
| `sudo apt remove <패키지이름>` | 패키지 제거 |

학교 PC를 쓸 때는 다른 사람 작업과 섞이지 않도록 내 계정을 따로 만든다.

| 명령어 | 하는 일 |
|---|---|
| `sudo adduser <계정이름>` | 계정 추가 (sudo: root 권한으로 뒤 명령 실행) |
| `wsl -d Ubuntu-24.04 -u kam` | (파워셸) 만든 계정으로 로그인, kam은 교안 예시 계정 |
| `whoami` | 접속한 계정 확인 |
| `cat /etc/passwd` | 전체 사용자 확인 |
| `su - <계정이름>` | Ubuntu를 종료하지 않고 계정 변경 |

맥은 Homebrew를 쓴다 (`xcode-select --install` 후 brew.sh 안내대로 설치, `brew install <패키지이름>`, `brew update`, `brew upgrade`).

### 3. 기본 리눅스 명령어

| 명령어 | 하는 일 |
|---|---|
| `pwd` | 현재 위치 (print working directory) |
| `ls` | 파일/폴더 목록 (list) |
| `ls -l` | 권한, 링크, 소유자, 그룹, 크기, 수정 시간, 파일명까지 출력 (long listing) |
| `ls -a` | 숨김 파일까지 모두 (이름이 .으로 시작하면 숨김 파일) |
| `cd ~` | 홈 디렉터리로 |
| `cd ..` | 상위 디렉터리로 |
| `cd .` | 현재 디렉터리 |
| `cd -` | 직전에 작업하던 디렉터리로 |
| `mkdir <디렉터리>` | 디렉터리 생성 (make directory) |
| `rmdir <디렉터리>` | 빈 디렉터리 삭제 (remove directory) |

파일 다루기 실습

| 명령어 | 하는 일 |
|---|---|
| `mkdir test` |  |
| `cd test` |  |
| `touch devops.txt` | 빈 파일 만들기 |
| `ls` |  |
| `echo "Hello devops" > devops.txt` | 파일에 내용 쓰기 |
| `cat devops.txt` | 내용 확인 (cat: concatenate) |
| `echo "Hello, " > 1.txt` |  |
| `echo "DevOps" > 2.txt` |  |
| `cat 1.txt 2.txt > s.txt` | 두 파일 내용을 합쳐서 s.txt에 기록 (>: 덮어쓰기) |
| `cat s.txt` |  |
| `echo "Hi!" > 3.txt` |  |
| `cat 3.txt >> s.txt` | s.txt 끝에 추가 (>>: 이어 쓰기) |
| `cat s.txt` |  |
| `cat 1.txt 2.txt >> s.txt` |  |
| `cat s.txt` |  |
| `cp devops.txt hi.txt` | 복사 |
| `mv hi.txt hello.txt` | 이동 (같은 디렉터리면 이름 변경과 같은 효과) |
| `rm s.txt` | 삭제 |
| `rm 1.txt 2.txt 3.txt` |  |
| `rm hello.txt` |  |
| `cd ..` |  |
| `rmdir test` | 안에 devops.txt가 남아 있어서 삭제 시도만 |
| `pwd` |  |
| `rm test/devops.txt` |  |
| `rmdir test` | 비었으니 삭제 가능 |

권한 수정

| 명령어 | 하는 일 |
|---|---|
| `chmod +x s.txt` | 실행 권한 추가 (chmod: change mode) |
| `chmod -x s.txt` | 실행 권한 제거 |
| `chmod u+r s.txt` | 소유자(u)에게 읽기 권한 추가 |
| `chmod g-w s.txt` | 그룹(g)의 쓰기 권한 제거 |
| `chmod 755 s.txt` | 소유자 rwx / 그룹 r-x / 기타 r-x |
| `chmod 750 *.sh` | .sh 파일 전부 소유자 rwx / 그룹 r-x / 기타 권한 없음 |
| `chmod 755 a.txt b.txt c.txt` | 여러 파일 한 번에 |

기타 정보 확인

| 명령어 | 하는 일 |
|---|---|
| `whoami` | 현재 사용자 |
| `who` | 지금 로그인 중인 사용자 |
| `id` | 내 UID, GID, 그룹 정보 |
| `uname -a` | 리눅스 커널 정보 |
| `cat /etc/os-release` | Ubuntu 버전 (맥은 sw_vers) |
| `df -h` | 디스크 사용량 (df: disk free, -h: 사람이 읽기 쉽게) |
| `free -h` | 메모리 상태 (Swap: 메모리가 부족할 때 디스크로 옮겨 쓰는 영역) |
| `clear` | 화면 정리 |
| `history` | 지금까지 입력한 명령어 |
| `!103` | history의 103번째 명령 실행 |
| `!103:p` | 103번째 명령을 실행하지 않고 출력만 |
| `!!` | 바로 직전 명령 다시 실행 |
| `!ls` | 가장 최근에 ls로 시작한 명령 다시 실행 |
| `sudo !!` | 직전 명령을 sudo 붙여서 다시 실행 (예: apt update 다음에) |
| `less <파일이름>` | 긴 파일 내용 보기 |
| `head <파일이름>` | 앞부분만 |
| `tail <파일이름>` | 뒷부분만 |
| `tail -f <로그파일>` | 계속 따라가며 보기 (f: follow, 종료는 Ctrl + C) |

### 4. Git

| 명령어 | 하는 일 |
|---|---|
| `sudo apt install git -y` | 설치 (맥: brew install git) |
| `git --version` |  |
| `git config --global user.name "이름"` |  |
| `git config --global user.email "이메일"` |  |
| `git config --global init.defaultBranch main` | 기본 브랜치 이름을 main으로 |
| `git config --list` | 설정 확인 |

저장소 만들고 첫 커밋

| 명령어 | 하는 일 |
|---|---|
| `cd ~/devops` |  |
| `mkdir week02` | 2주차 학습 저장 |
| `cd ~/devops` | 초기화할 프로젝트 홈으로 이동 (전체 홈 ~ 아님) |
| `pwd` | 위치 꼭 확인 |
| `git init` | 이 디렉터리를 Git이 버전 관리하도록 초기화 |
| `ls -a` | 숨겨진 .git 디렉터리 확인 |
| `git status` | 상태 보기 |
| `cd ~/devops/week02` |  |
| `echo "Hello, DevOps!" > text.txt` |  |
| `git status` | Untracked files에 text.txt가 보임 |
| `git add text.txt` | 다음 커밋에 넣을 변경사항 선택 (staging area에 넣기) |
| `git status` | Changes to be committed로 바뀜 |
| `git commit -m "first commit"` | 준비된 변경사항을 하나의 버전(스냅샷)으로 기록 |
| `git log` | 커밋 기록 확인 |

버전 이동과 비교

| 명령어 | 하는 일 |
|---|---|
| `echo "Inha tech college" >> text.txt` |  |
| `cat text.txt` |  |
| `git add .` | 수정한 모든 파일 선택 |
| `git commit -m "second commit"` |  |
| `git log --oneline` | 커밋 해시 앞부분과 메시지를 한 줄씩 |
| `git switch -d 7c5bdda` | 해당 커밋 버전으로 이동 (-d: detach, 해시는 구분될 만큼 앞 7자리) |
| `cat text.txt` | first commit 시점의 내용 확인 |
| `git diff 01d4 7c5b` | 두 커밋 비교 |

교안의 `git log --oneline` 예시 출력

```text
01d4f81 (HEAD -> main) second commit
7c5bdda first commit
```

브랜치

| 명령어 | 하는 일 |
|---|---|
| `echo "hello" > hello.txt` |  |
| `git add .` |  |
| `git commit -m "hello"` |  |
| `git switch -c hi` | hi 브랜치를 만들고 이동 (-c: create) |
| `echo "hi" > hello.txt` |  |
| `git add .` |  |
| `git commit -m "hello -> hi"` |  |
| `git switch main` | main으로 이동 |
| `cat hello.txt` | main 쪽 내용 확인 |
| `git switch hi` |  |
| `cat hello.txt` | hi 쪽 내용 확인 |
| `git diff main hi` | 두 브랜치 비교 |
| `git branch` | 현재 브랜치 확인 |
| `git log --oneline --all --graph` | 브랜치를 포함한 상태를 그래프로 |

### 5. GitHub

| 명령어 | 하는 일 |
|---|---|
| `sudo apt update` |  |
| `sudo apt install gh -y` | GitHub CLI 설치 (맥: brew install gh) |
| `gh --version` |  |
| `gh auth login` | GitHub.com → HTTPS → Yes → Login with a web browser, 표시된 one-time code 입력 |
| `sudo apt install wslu -y` | 브라우저가 안 열리면 설치 (또는 https://github.com/login/device 접속) |
| `pwd` | [중요] 현재 디렉터리 위치 확인 |
| `gh repo create <레포이름> --public --source=. --remote=origin --push` | 저장소 생성 + 연결 + 푸시 |
| `gh repo view --web` | 웹에서 보기 |
| `gh browse --no-browser` | 링크만 보기 |
| `git commit -m "메시지"` |  |
| `git push` | [중요] 커밋 후 반드시 푸시 |
| `gh auth status` | (학교 PC) 로그인 상태 확인 |
| `gh auth logout` | (학교 PC) 반드시 로그아웃 |
| `git clone https://github.com/<아이디>/<레포이름>.git` | 다른 PC로 작업물 가져오기 |
| `cd <레포이름>` |  |

README.md는 터미널 편집기 nano로 작성한다 (`nano README.md`, `^O` 저장, `^X` 종료, `^K` 현재 줄 잘라내기, `^U` 붙여넣기, `^`는 Ctrl 키).

## 핵심 개념 정리

서버 운영 방식 비교

| 구분 | 베어메탈 | 하이퍼바이저 가상화 | 컨테이너 가상화 |
|---|---|---|---|
| 구조 | 하드웨어 위에 OS를 직접 설치하고 여러 소프트웨어 운영 | 하이퍼바이저 위에 VM마다 Guest OS | 호스트 OS 커널을 공유, 컨테이너 런타임 위에 여러 컨테이너 |
| 좋은 점 | 구조 단순, 성능 우수, 하나의 OS에서 관리 쉬움 | 격리 강함 | 가볍고 빠름, 배포 용이 |
| 아쉬운 점 | 프로그램 하나가 해킹되면 다른 프로그램도 위험, 하나가 자원을 많이 쓰면 나머지가 비정상 작동 가능 | 호스트 OS와 게스트 OS 커널이 따로 있어서 오버헤드가 큼 | 호스트 OS와 다른 종류의 OS는 실행할 수 없음 |

- 가상화: 물리적인 컴퓨팅 환경 안에 여러 개의 논리적인 컴퓨팅 환경을 만드는 기술. 컨테이너는 서버를 효율적으로 쓰기 위한 가상화 기술이다.
- 커널: 프로그램의 요청을 받아 하드웨어 리소스를 안전하게 관리하고 연결해 주는 역할. 프로세스는 시스템 콜로 리소스를 요청한다.
- 리눅스 컨테이너의 핵심 기술: 네임스페이스(프로세스, 파일 시스템, 네트워크 등 격리), cgroups(리소스 사용량 제어).
- 높은 사양의 컴퓨터 한 대에 가상화를 쓰는 편이 낮은 사양 여러 대보다 비용, 공간, 인력 면에서 경제적이다.

`ls -l` 권한 읽는 법 (`-rwxr-xr--`)

| 자리 | 의미 | 예시 값 |
|---|---|---|
| 1번째 | 파일 종류 (`-` 파일, `d` 디렉터리, `l` 심볼릭 링크) | `-` |
| 2~4번째 | 소유자(user) | `rwx` 읽기+쓰기+실행 |
| 5~7번째 | 그룹(group) | `r-x` 읽기+실행 |
| 8~10번째 | 기타 사용자(others) | `r--` 읽기만 |

- 숫자 표기: r=4, w=2, x=1. `750`이면 소유자 7(4+2+1), 그룹 5(4+1), 기타 0.

Git / GitHub 용어

| 용어 | 뜻 |
|---|---|
| 버전 관리 시스템 | 파일의 변경 이력을 기록하고 관리하는 도구. 이전 버전 복원, 비교, 브랜치 작업 가능. 인터넷 없이 로컬에서도 사용 |
| `git add` | 파일을 저장하는 게 아니라 다음 커밋에 포함할 변경사항을 고르는 것 (staging area에 넣기) |
| 커밋 | 준비된 변경사항을 하나의 버전(스냅샷)으로 기록. 게임의 세이브 포인트와 비슷 |
| 브랜치 | 특정 커밋을 가리키는 이름. 서로 다른 작업을 독립적으로 진행 |
| `.git` | 커밋 기록, 브랜치 정보, 설정 같은 핵심 정보가 저장되는 숨김 디렉터리 |
| GitHub | Git 저장소를 온라인에 공유하고 협업하는 공간 (Pull Request, Issue, Code Review, GitHub Actions 등) |
| `--source=.` | 현재 디렉터리의 Git 저장소를 GitHub에 연결 |
| `--remote=origin` | 원격 저장소 이름 지정. origin은 관례적으로 쓰는 이름 |
| `--push` | 로컬 커밋을 원격 저장소에 업로드 |
