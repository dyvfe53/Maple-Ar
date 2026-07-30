# 변환 로그

각 변환 건마다: 원본 경로, 변환 결과 경로, 적용한 판단/수정 사항을 남긴다.
나중에 문제가 생기면 "왜 이렇게 옮겼는지" 추적하기 위함.

---

## #1. Cliff (NPC 2001000) — desc_tree.js

- **원본**: `argonms-server/scripts/npcs/desc_tree.js`
- **결과**:
  - `scripts/components/NpcLinearTalk.lua` (재사용 컴포넌트, 이 NPC 전용 아님)
  - `data/npc_dialogues/2001000_Cliff.csv` (이 NPC 전용 데이터)
- **선택 이유**: `npc.say`/`npc.sayNext`만 사용하는 순수 선형 대사(분기 없음) — 검증된 MSW 패턴과
  1:1로 대응되는 가장 단순한 사례라 첫 변환 대상으로 선택.
- **원문 → 텍스트 변환 시 적용한 수정**:
  1. `#btrade or open a store#k` → `trade or open a store` : `#b`/`#k`는 ArgonMS/메이플 클라이언트의
     인라인 텍스트 색상 코드(파란색 시작/리셋)이며 MSW에는 대응 문법이 없어 제거하고 일반 텍스트로 남김.
  2. `#p2002001#` → `the ornament seller` : ArgonMS에서 `#p숫자#`는 클라이언트가 해당 NPC ID의
     이름으로 자동 치환해주는 태그. NPC 2002001의 실제 이름을 이 저장소에서 확인하지 못해
     (별도 NPC 이름 테이블 미탐색) 문맥상 대체 표현으로 바꿔둠. **정확한 NPC명 확인 후 교체 필요**.
  3. name 컬럼은 원본에 없는 값 — NPC 설명 주석의 "Cliff"를 사용 (공식 튜토리얼 패턴상 각 행에 이름 필요).
  4. portrait 컬럼은 비워둠 — ArgonMS 저장소에 초상화 이미지 자체가 없음(WZ 자산 미포함).
     MSW 에디터에서 NPC 초상화 이미지를 직접 업로드한 뒤 그 RUID를 채워야 함.
- **미검증 상태**: 아래는 모두 실제 MSW 에디터에서 아직 실행/확인되지 않음.
  - `NpcLinearTalk.lua`가 실제로 파싱/컴파일되는지 (문법 확장 표기를 손으로 따라 썼을 뿐, MSW 스크립트
    에디터에서 검증된 적 없음)
  - InteractionComponent + 이 스크립트의 실제 연동 동작
  - 데이터 테이블 CSV를 MSW `_DataService` 테이블로 가져오는 방법(수동 재입력 vs import 기능 존재 여부 미확인)

---

## #2. Mong from Kong (NPC 1052012) — go_pc.js

- **원본**: `argonms-server/scripts/npcs/go_pc.js`
- **결과**:
  - `scripts/components/NpcBranchTalk.lua` (재사용, 분기형 대화 컴포넌트 — 이번에 첫 작성)
  - `scripts/components/NpcOptionButton.lua` (재사용, 선택지 버튼 연결용 — 이번에 첫 작성)
  - `data/npc_dialogues/1052012_MongFromKong_Talk.csv`
  - `data/npc_dialogues/1052012_MongFromKong_Choice.csv`
- **선택 이유**: `askYesNo` 하나만 쓰는 가장 단순한 분기(2지선다) — 분기형 대화의 첫 사례로 적합.
- **원문의 `askYesNo` 반환값 해석에 대한 불확실성**: ArgonMS Java 소스(`ScriptNpc.askYesNo`)를 확인했지만
  0/1이 Yes/No 중 무엇인지 코드 자체에서는 확정할 수 없었음. 다른 MapleStory 서버 에뮬레이터들의
  통상적 관례(0=Yes, 1=No, 클라이언트 버튼 순서 기준)를 따라 `targetRow`를 매핑함 (Choice CSV의
  `optionIndex=0`→"Yes"→2행, `optionIndex=1`→"No"→3행). **이 관례가 실제로 맞는지 확인 안 됨** —
  틀렸다면 두 응답이 서로 바뀌는 정도의 문제이므로 나중에 쉽게 고칠 수 있음.
- **설계 도중 발견/수정한 오류**:
  1. 처음에는 "선택지 행을 임의의 `id`로 검색"하는 설계였는데, `_DataService` API Reference를 확인해보니
     `GetCell(row, col)`은 행 **번호**로만 접근 가능하고 값으로 검색하는 함수가 없음을 확인.
     → 별도 id/검색 없이 "행 번호 자체를 id로 취급"하는 방식으로 단순화 (docs/msw_lua_notes.md 참고).
  2. 버튼 클릭 시 "어느 행으로 점프할지"를 버튼에 임시 저장하는 방법으로 처음엔 `TagComponent.Tag`를
     썼는데, TagComponent API Reference를 확인해보니 그런 속성이 없음(`Tags`라는 리스트+AddTag/RemoveTag만
     존재)을 발견. → 버튼마다 붙는 전용 스크립트(`NpcOptionButton.lua`)의 `targetRow` 프로퍼티에 저장하는
     방식으로 수정.
- **미검증 상태**: `NpcLinearTalk.lua`와 동일한 항목들에 더해, 버튼→NPC 컴포넌트 간 교차 참조
  (`btn.NpcOptionButton.targetRow = ...`, `self.npcEntity.NpcBranchTalk:OnOptionChosen(...)`)가
  실제로 동작하는지가 가장 큰 미검증 리스크.
