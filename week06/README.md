# 6주차 · 도커파일

## 배운 내용 정리

- 컨테이너를 지우면 수정한 내용(쓰기 계층)이 사라진다. 답은 두 가지로, 변경 사항을 이미지에 굽거나(Dockerfile, 이번 주) 데이터를 컨테이너 밖에 보관하는 것(Volume, 다음 주)이다.
- Dockerfile은 이미지를 만드는 레시피다. 실행 환경을 코드로 정의하는 Infrastructure as Code 사고방식과 이어진다. `FROM`, `WORKDIR`, `COPY`, `RUN`, `ENV`, `EXPOSE`, `CMD`를 배웠다.
- 레이어 캐시: 한 레이어가 바뀌면 그 아래 레이어는 전부 다시 만들어지므로, 자주 바뀌는 것을 뒤에 둔다 (`requirements.txt`를 먼저 복사).
- 방명록(guestbook) 앱을 직접 빌드하고, ghcr.io와 Docker Hub에 tag → push, 친구 이미지를 pull → run 하는 배포 흐름을 배웠다. 애플 실리콘 맥과 x86-64 PC를 둘 다 지원하려면 `buildx`로 멀티 플랫폼 이미지를 만든다.
- 설정 우선순위는 코드 기본값 < Dockerfile `ENV` < `docker run -e`. 6주차 시점은 `git tag week06`으로 표시해 둔다.

## 실습한 명령어와 코드

### 1. 이미지 주소 읽기

| 명령어 | 하는 일 |
|---|---|
| `docker run -d -p 8080:5000 --name pull-fail ghcr.io/makyraen/inhatc-devops-guestbook` | 태그 생략 → latest 요청 → 없어서 실패 |
| `docker run -d -p 8081:5000 --name guestbook-ghcr ghcr.io/makyraen/inhatc-devops-guestbook:v1` | ghcr.io |
| `docker run -d -p 8082:5000 --name guestbook-dh nearykam/inhatc-devops-guestbook:v1` | Docker Hub (레지스트리 생략) |

```text
ghcr.io / makyraen / inhatc-devops-guestbook : v1
레지스트리   사용자(계정)   이미지 이름            태그
```

### 2. 실습 1 - 이미지 사용하기

| 명령어 | 하는 일 |
|---|---|
| `docker pull ghcr.io/makyraen/inhatc-devops-guestbook:v1` |  |
| `docker run -d -p 8080:5000 --name demo ghcr.io/makyraen/inhatc-devops-guestbook:v1` | 제목 "InhaTC DevOps 방명록", 파란색 테마 |
| `docker rm -f demo` |  |

```bash
docker run -d -p 8080:5000 --name demo \
  -e APP_TITLE="<본인 이름>의 방명록" \
  -e THEME_COLOR="#16a34a" \
  ghcr.io/makyraen/inhatc-devops-guestbook:v1     # 이미지는 그대로, 설정만 바깥에서 주입
```

| 명령어 | 하는 일 |
|---|---|
| `docker logs demo` | 시작 로그 확인 |
| `docker rm -f demo` | 실습 후 정리 |

템플릿 앱 받기 (주차별로 복사하지 않고 `guestbook/` 하나를 계속 고쳐 나간다, 변화는 Git이 기록)

| 명령어 | 하는 일 |
|---|---|
| `cd ~/devops` |  |
| `unzip /mnt/c/Users/<윈도우계정>/Downloads/guestbook.zip` | Mac: unzip ~/Downloads/guestbook.zip |
| `cd guestbook` |  |
| `ls -la` |  |
| `python3 app.py` | ModuleNotFoundError: No module named 'flask' |

```text
guestbook/
├── app.py
├── requirements.txt      # Flask, redis
├── templates/index.html
├── Dockerfile
├── Dockerfile.multistage
├── .dockerignore
└── README.md
```

컨테이너 없이 실행하면 Flask가 없어서 안 된다. 친구 컴퓨터나 서버에서도 매번 `pip install flask`를 할 수는 없으니 Dockerfile로 포장한다.

`guestbook/Dockerfile` 한 줄씩 읽기

```dockerfile
FROM python:3.12-slim                                # 기반 이미지 (slim: 가벼운 버전)
WORKDIR /app                                         # 작업 디렉터리, 없으면 만들고 cd처럼 이동
COPY requirements.txt .                              # 라이브러리 목록만 먼저 이미지 안으로
RUN pip install --no-cache-dir -r requirements.txt   # 빌드할 때 라이브러리 설치, 결과가 이미지에 남음
COPY . .                                             # 나머지 코드 복사 (자주 바뀌니까 뒤에)
RUN useradd -m appuser                               # 일반 사용자 만들기
USER appuser                                         # root가 아닌 사용자로 실행
ENV APP_TITLE="InhaTC DevOps 방명록" \
    THEME_COLOR="#0054A6"                            # 환경 변수 기본값을 이미지에 굽기
EXPOSE 5000                                          # 5000번 포트를 쓴다는 문서화 (실제로 열리지는 않음)
CMD ["python", "app.py"]                             # 컨테이너가 시작할 때마다 실행할 명령
```

app.py 기본값 확인

```bash
grep -E "APP_TITLE|THEME_COLOR" app.py
```

```text
APP_TITLE = os.environ.get("APP_TITLE", "DevOps 방명록")
THEME_COLOR = os.environ.get("THEME_COLOR", "#DC143C")
```

코드 기본값은 "DevOps 방명록"/빨간색인데 앞에서 실행한 이미지 화면은 "InhaTC DevOps 방명록"/파란색이다. Dockerfile의 `ENV`가 코드 기본값보다 우선이기 때문이다.

빌드하고 실행

| 명령어 | 하는 일 |
|---|---|
| `docker build -t guestbook:v1 .` | .: 현재 디렉터리를 빌드 컨텍스트로 (없으면 에러) |
| `docker images \| grep guestbook` |  |
| `docker run -d -p 8081:5000 --name gb guestbook:v1` | http://localhost:8081, 나의 첫 이미지 |
| `docker logs gb` |  |

캐시 체감하기

| 명령어 | 하는 일 |
|---|---|
| `docker build -t guestbook:v1.1 .` | 아무것도 안 고치고 다시 빌드 → 대부분 CACHED |
| `sed -i 's/아직 방명록이 비어 있습니다./첫 글의 주인공이 되어주세요!/' templates/index.html` | Mac은 sed -i '' ... |
| `docker build -t guestbook:v1.2 .` | 코드 한 줄 고치고 빌드 |

교안 빌드 로그 (requirements.txt와 pip install은 캐시 재사용, `COPY . .`부터 다시)

```text
=> CACHED [3/6] COPY requirements.txt .
=> CACHED [4/6] RUN pip install --no-cache-dir -r requirements.txt
=> [5/6] COPY . .
=> [6/6] RUN useradd -m appuser
```

좋지 않은 Dockerfile과 비교

```bash
cat > Dockerfile.bad << 'EOF'
FROM python:3.12-slim
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
CMD ["python", "app.py"]
EOF
```

| 명령어 | 하는 일 |
|---|---|
| `docker build -f Dockerfile.bad -t guestbook:bad .` | -f: 사용할 Dockerfile 지정 |
| `echo "# 테스트" >> app.py` |  |
| `docker build -f Dockerfile.bad -t guestbook:bad .` | 코드만 바꿨는데 pip install 또 실행 |
| `docker rmi guestbook:bad` | 이미지 삭제 (rmi: remove image) |

### 3. 실습 2 - 이미지 공유하기 (ghcr.io)

| 명령어 | 하는 일 |
|---|---|
| `gh auth token \| docker login ghcr.io -u GitHub아이디 --password-stdin` | GitHub CLI 토큰으로 로그인 → Login Succeeded |
| `gh auth refresh -h github.com -s write:packages,read:packages` | 권한 부족 에러 시 |
| `docker logout ghcr.io` |  |
| `gh auth token \| docker login ghcr.io -u GitHub아이디 --password-stdin` |  |
| `docker tag guestbook:v1 ghcr.io/아이디/guestbook:v1` | ghcr.io/사용자명/이미지명:태그 형식으로 이름 붙이기 |
| `docker images \| grep guestbook` |  |
| `docker push ghcr.io/아이디/guestbook:v1` | 업로드, https://github.com/아이디?tab=packages 에서 확인 |

친구가 받을 수 있게 패키지 페이지 > Package settings > Danger Zone > Change visibility > Public 선택 > 패키지 이름 입력 > change package visibility.

| 명령어 | 하는 일 |
|---|---|
| `docker rm -f gb` | 내 컨테이너 정리 |
| `docker run -d -p 9090:5000 --name friend ghcr.io/친구아이디/guestbook:v1` | 친구 이미지 실행, http://localhost:9090 |

친구의 소스 코드도 없고 Flask도 설치하지 않았고 파이썬 버전도 신경 쓰지 않았는데 내 컴퓨터에서 돌아간다.

멀티 아키텍처 (애플 실리콘 맥 arm64 ↔ x86-64 PC amd64)

| 명령어 | 하는 일 |
|---|---|
| `docker image inspect ghcr.io/내아이디/guestbook:v1 --format '{{.Architecture}}'` | 맥에서 그냥 빌드하면 arm64 |
| `docker buildx build --platform linux/amd64,linux/arm64 -t ghcr.io/내아이디/guestbook:v1 --push .` |  |

### 4. 실습 3 - Docker Hub

```bash
docker login -u 도커허브아이디
docker build -t 도커허브아이디/guestbook:v1 .
docker push 도커허브아이디/guestbook:v1
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ghcr.io/깃허브아이디/inhatc-devops-guestbook:v1 \
  -t 도커허브아이디/inhatc-devops-guestbook:v1 \
  --push .                                   # 두 레지스트리에 양쪽 아키텍처로 한 번에
```

### 5. 혼자 해보기

다시 pull 받아서 실행

| 명령어 | 하는 일 |
|---|---|
| `docker rmi ghcr.io/아이디/guestbook:v1` | 해당 컨테이너 정리 여부 확인 후 |
| `docker pull ghcr.io/아이디/guestbook:v1` |  |
| `docker run -d -p 8080:5000 --name check ghcr.io/아이디/guestbook:v1` |  |
| `docker exec check ls /app` | app 디렉터리 확인 |
| `docker rm -f check` |  |

1) 나만의 방명록 v2: Dockerfile `ENV`(제목, 테마)와 `templates/index.html`(문구, 레이아웃)을 고쳐서 `guestbook:v2`로 빌드하고 `ghcr.io/본인아이디/guestbook:v2`로 푸시한 다음 환경 변수를 주입해서 실행

```bash
docker run -d -p 8081:5000 --name gbv2 \
  -e THEME_COLOR="#C6A15B" \
  ghcr.io/본인아이디/guestbook:v2
```

2) 친구 이미지를 `FROM`으로 받아 내 설정 굽기

| 명령어 | 하는 일 |
|---|---|
| `docker rm -f gb` | 해당 컨테이너가 있으면 제거 |

```bash
cat > Dockerfile.custom << 'EOF'
FROM ghcr.io/친구아이디/inhatc-devops-guestbook:v1
ENV APP_TITLE="방명록" \
    THEME_COLOR="#7C9A82"
EOF
```

| 명령어 | 하는 일 |
|---|---|
| `docker build -f Dockerfile.custom -t guestbook:custom .` |  |
| `docker run -d -p 8082:5000 --name custom guestbook:custom` |  |
| `docker history guestbook:custom` | 기존 이미지 레이어 위에 ENV 레이어가 추가된 것 확인 |

3) 누가 우선? 구운 이미지에 `-e`를 주면 어느 색이 반영되는지 확인

```bash
docker rm -f custom
docker run -d -p 8083:5000 --name custom -e THEME_COLOR="#16a34a" guestbook:custom
```

4) 기록하고 태그 달기

| 명령어 | 하는 일 |
|---|---|
| `cd ~/devops` |  |
| `git add guestbook week06` |  |
| `git status` | guestbook/과 week06/이 담겼는지 확인 |
| `git commit -m "week06: Dockerfile & ghcr.io 배포"` |  |
| `git push` |  |
| `git tag week06` | 6주차 시점 표시 |
| `git push origin week06` | 태그를 원격 저장소에 올리기 |
| `git diff week06 -- guestbook/` | 나중에 guestbook/을 고치다 문제가 생기면 week06 시점과 비교 |
| `git restore --source=week06 guestbook/` | 필요하면 6주차 상태로 되돌리기 |

### 6. [참고] 이미지 줄이기와 생각해보기

| 명령어 | 하는 일 |
|---|---|
| `docker build -t gb:fat .` |  |
| `docker build -f Dockerfile.multistage -t gb:slim .` | 멀티스테이지: 빌드 도구는 버리고 결과물만 |
| `docker images \| grep gb` | 교안 예시 212MB vs 210MB, 이 앱은 극적인 변화는 없음 |
| `docker restart custom` | 방명록 글을 남긴 뒤 재시작해 보기 |

재시작하면 색은 그대로인데 글은 사라진다. 방명록 글이 애플리케이션 프로세스 메모리에 저장되기 때문이다.

## 핵심 개념 정리

Dockerfile 명령어

| 명령어 | 의미 | 주의점 |
|---|---|---|
| `FROM` | 기반 이미지 | 각 빌드 스테이지는 FROM부터 시작, `-slim`/`-alpine`은 가벼운 버전 |
| `WORKDIR` | 작업 디렉터리 (없으면 생성) | cd와 유사 |
| `COPY 원본 대상` | 호스트 파일 → 이미지 | 원본은 빌드 컨텍스트 기준 상대 경로 |
| `RUN` | 빌드할 때 실행 | 이미지에 결과가 남음 |
| `ENV 이름=값` | 환경 변수 기본값을 이미지에 | `docker run -e`로 덮어쓰기 가능 |
| `EXPOSE` | 포트 번호 문서화 | 실제로 열리지 않음 |
| `CMD` | 컨테이너 시작할 때 실행 | 마지막 것만 효력, 배열 형태 권장 |

- RUN = 이미지를 만들 때 한 번 실행 (예: 라이브러리 설치) / CMD = 컨테이너를 실행할 때마다 실행 (예: 앱 실행)
- 붕어빵 비유: Dockerfile은 틀을 만드는 설명서, `docker build`는 틀 만들기, RUN은 틀을 만드는 과정의 작업, CMD는 붕어빵(컨테이너)을 시작할 때 할 일
- 레이어: RUN/COPY는 파일 시스템 변경, CMD/ENV/EXPOSE/USER 등은 이미지 설정(메타데이터). 한 단계의 캐시가 무효화되면 이후 단계도 다시 처리한다.

설정을 넣는 세 가지 방법 (이 앱의 우선순위: 코드 기본값 < Dockerfile ENV < docker run -e)

| 방법 | 언제 확정 | 바꾸려면 |
|---|---|---|
| app.py 기본값 수정 | 코드 | 코드 수정 후 재빌드 |
| Dockerfile의 ENV | 이미지 빌드 시점 | 재빌드 |
| docker run -e | 컨테이너 실행 시점 | 컨테이너만 다시 실행 |

배포 흐름: build → tag → push → (친구) pull → run, 멀티 아키텍처는 `buildx --platform`

스테이징 영역

```text
[작업 디렉터리] --git add--> [스테이징 영역] --git commit--> [저장소]
 (수정한 파일)  <--git restore --staged--  (장바구니)           (확정된 기록)
```

- `git add`는 장바구니에 담기(도로 뺄 수 있음), `git commit`은 결제(확정), `git status`는 장바구니에 뭐가 담겼는지 보기.
