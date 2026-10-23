# DevOps

2026-2 인하공업전문대학 컴퓨터정보공학과 DevOps 수업에서 리눅스, Git, 네트워크, 도커를 실습한 내용을 주차별로 정리한 저장소.

## 주차별 내용

| 주차 | 주제 | 링크 |
|---|---|---|
| 1주차 | 강의 오리엔테이션 | 없음 |
| 2주차 | 실습 환경 구축과 버전 관리 기초 (가상화, WSL2, 리눅스 명령어, Git, GitHub) | [week02](./week02/) |
| 3주차 | 셸 스크립팅 (Qwen + Ollama 로컬 AI 서비스, start.sh) | [week03](./week03/) |
| 4주차 | 자동화와 협업, 네트워크 (백업 스크립트, 브랜치/PR/Conflict, IP·포트·DNS) | [week04](./week04/) |
| 5주차 | 도커 w/ GitHub Issue (이미지와 컨테이너, nginx, Issue → PR → Merge) | [week05](./week05/) |
| 6주차 | 도커파일 (Dockerfile, 레이어 캐시, ghcr.io 배포) | [week06](./week06/) |
| 7주차 | 도커 컴포즈 (Redis, 볼륨, .env, healthcheck, scale, nginx) | [week07](./week07/) |

## 실습 환경

2주차 교안 기준

- 윈도우: WSL2 + Ubuntu (`wsl --install`, 특정 버전은 `wsl --install -d Ubuntu-24.04`), Ubuntu 터미널에서 작업
- 맥: 터미널 + Homebrew
- 작업 디렉터리: 리눅스 전용 공간의 `~/devops`
- Git (`git config --global init.defaultBranch main`), GitHub CLI `gh` (`gh auth login`, HTTPS)
- 편집기: nano

이후 주차에서 추가한 것: Ollama(3주차), tree·jq·htop·dnsutils(4주차), Docker Desktop + WSL Integration(5주차).
