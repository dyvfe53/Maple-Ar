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
