# Maple-Ar

ArgonMS(오픈소스 MapleStory v62 사설서버 에뮬레이터) 소스를 참고하여, 넥슨 공식 UGC 플랫폼
**메이플스토리 월드(MapleStory Worlds, MSW)**용 Lua 콘텐츠로 재작성하는 프로젝트입니다.

## 배경

- 원본: [ArgonMS](https://github.com/kimkangmin0826/argonms-server) — Java 기반, JS(Rhino)로 NPC/퀘스트/포탈/리액터 스크립트 작성
- 대상: MSW — 자체 엔진 + Lua 스크립팅 (Component/Event/Service/Logic API)
- ArgonMS의 Java/네트워킹/DB 코드는 이식 대상이 아닙니다 (MSW가 서버/네트워킹을 전부 대신 처리).
  이식 대상은 **게임 로직과 데이터**뿐입니다: NPC 대화, 퀘스트 흐름, 몬스터/아이템 스탯, 드롭 테이블.
- 맵/그래픽(WZ) 에셋은 원본에 포함되어 있지 않으며, MSW 자체 에디터로 별도 제작해야 합니다.

## 폴더 구조

```
scripts/
  npcs/      - ArgonMS scripts/npcs/*.js → Lua로 변환한 NPC 대화 스크립트
  quests/    - 퀘스트 진행 로직
  portals/   - 포탈 발동 로직
  reactors/  - 리액터(오브젝트 상호작용) 로직
  events/    - 이벤트 스크립트
data/        - 몬스터/아이템/드롭/상점 등 정적 데이터 (SQL → 변환)
```

## 상태

- [ ] MSW 프로젝트 환경 준비 (사용자 PC에서 에디터로 신규 프로젝트 생성 예정)
- [ ] 실제 MSW Lua API 문서 기준 검증
- [ ] NPC 스크립트 변환 (0 / 202)
- [ ] 퀘스트 스크립트 변환 (0 / 7)
- [ ] 포탈 스크립트 변환 (0 / 27)
- [ ] 리액터 스크립트 변환 (0 / 3)
- [ ] 이벤트 스크립트 변환 (0 / 11)
- [ ] 정적 데이터(SQL) 변환

이 저장소는 MSW 에디터가 만드는 실제 프로젝트 껍데기(매니페스트/씬/에셋 GUID)를 대신하지 않습니다.
MSW 환경이 준비된 PC에서 새 프로젝트를 만든 뒤, 여기 코드를 해당 프로젝트 폴더에 옮겨 넣어 사용합니다.
