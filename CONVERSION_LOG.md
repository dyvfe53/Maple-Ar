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

---

## #3~. 선형 대사 나머지 82개 — 배치 변환 (병렬 서브에이전트 5개 + 코디네이터 검수/수정)

5개 배치로 나눠 병렬 변환 후, 코디네이터가 전체를 자동 스캔(다중 say + 조건문 조합 탐지)하여
재검수함. 그 결과 batch5의 4개 파일이 '순차 진행'이 아닌 '상태 조건부 배타적 분기'였음을 발견하고
정정(CSV 삭제 + 재분류), batch2의 bush1/bush2는 반대로 과도하게 스킵됐던 것을 발견하고 변환으로
뒤집음. 아래는 각 배치의 최종(수정 반영) 로그.


이 파일은 CONVERSION_LOG.md와의 병렬 작업 충돌을 피하기 위해 별도로 유지하는 배치 전용 로그.
패턴은 `NpcLinearTalk.lua` + `data/npc_dialogues/*.csv`(CONVERSION_LOG.md #1 Cliff 사례)와 동일.

---

## Bringback.js — Maple Administrator (NPC 9010000)

- 결과: `data/npc_dialogues/9010000_MapleAdministrator.csv`
- `npc.say()` 1줄. 색상/플레이스홀더 태그 없음. 수정 없이 그대로 옮김.

## Event02.js — Pietro (NPC 9000002)

- **스킵**: `npc.say`/`npc.sayNext` 없음. `player.changeMap(100000000)`만 있는 순수 워프 스크립트.

## Event03.js — Vikan/Vikon/Vikone/Vikoon (NPC 9000003~9000006)

- **스킵**: 본문이 `//TODO: GMS-like conversation` 주석뿐, 실제 대사 없음.

## Event03_1.js — Vikin (NPC 9000009)

- 결과: `data/npc_dialogues/9000009_Vikin.csv`
- `npc.say()` 1줄. `#t4031018#` → `[Item 4031018]`로 치환 (Pirate's Map 관련 아이템, Quest 3814).
- **후속 확인 필요 없음** (아이템 ID 태그는 그대로 노출된 형식이라 별도 이름 조회 불필요, 단 실제 아이템명은 MSW 쪽에서 확인 권장).

## Event04.js — Chun Ji (NPC 9000007)

- **스킵**: `//TODO: GMS-like conversation`뿐, 대사 없음.

## Event05.js — Mr. Pickall: Master of Lock-Picking (NPC 9000008)

- **스킵**: `//TODO: GMS-like conversation`뿐, 대사 없음.

## Event06.js — Pietra (NPC 9000010)

- **스킵**: `npc.say`/`npc.sayNext` 없음. `player.changeMap(109050000)`만 있는 순수 워프 스크립트.

## Event07.js — Tia/Mia/Ria (NPC 9010001~9010003)

- **스킵**: `//TODO: GMS-like conversation`뿐, 대사 없음.

## Event09.js — Harry: Event Assistant (NPC 9000012)

- **스킵**: `//TODO: GMS-like conversation`뿐, 대사 없음.

## Lost_Trans1.js — Lita Lawless (NPC 9201054)

- **스킵**: `//TODO: GMS-like conversation`뿐, 대사 없음.

## Lost_Trans2.js — The Glimmer Man (NPC 9201083)

- **스킵**: `//TODO: GMS-like conversation`뿐, 대사 없음.

## Moonstone.js — Moonstone Grave (NPC 9201072)

- 결과: `data/npc_dialogues/9201072_MoonstoneGrave.csv`
- `npc.say()` 1줄 ("30, 101, Hidden."). 태그/색상코드 없음.

## ProofElli.js — Nana(E): Love Fairy (NPC 9201024)

- 결과: `data/npc_dialogues/9201024_NanaELoveFairy.csv`
- `npc.sayNext()` 1줄. 태그/색상코드 없음. name 컬럼은 헤더 주석 원문 그대로 `Nana(E): Love Fairy` 사용 (콤마 없어 CSV 이스케이프 이슈 없음, `(`/`:` 포함이라 name 필드도 따옴표 처리).

## ProofHene.js — Nana(H): Love Fairy (NPC 9201001)

- 결과: `data/npc_dialogues/9201001_NanaHLoveFairy.csv`
- `npc.sayNext()` 1줄. 태그/색상코드 없음. 원문에 "Amoria to head to Amoria If you are interested"처럼 마침표 누락된 오탈자가 있으나 원문 그대로 보존.

## ProofKern.js — Nana(K): Love Fairy (NPC 9201023)

- 결과: `data/npc_dialogues/9201023_NanaKLoveFairy.csv`
- `npc.sayNext()` 1줄. 태그/색상코드 없음.

## ProofOrbi.js — Nana(O): Love Fairy (NPC 9201025)

- 결과: `data/npc_dialogues/9201025_NanaOLoveFairy.csv`
- `npc.sayNext()` 1줄. 태그/색상코드 없음. ProofHene.js와 동일하게 "Amoria If" 오탈자 있음, 원문 보존.

## ProofPeri.js — Nana(P): Love Fairy (NPC 9201027)

- 결과: `data/npc_dialogues/9201027_NanaPLoveFairy.csv`
- `npc.sayNext()` 1줄. 태그/색상코드 없음.

## Sunstone.js — Sunstone Grave (NPC 9201071)

- 결과: `data/npc_dialogues/9201071_SunstoneGrave.csv`
- `npc.say()` 1줄 ("Tempt Fate. Discover the path."). 태그/색상코드 없음.

---


이 배치는 순수 `npc.say`/`npc.sayNext`만 쓰는 선형 대사 NPC 17개 대상.
공유 파일 충돌을 피하기 위해 `CONVERSION_LOG.md`와 분리된 파일.

---

## Tombstone.js — Tombstone (NPC 9201073)

- **결과**: `data/npc_dialogues/9201073_Tombstone.csv`
- 대사 1줄, 색상 코드/플레이스홀더 태그 없음. 그대로 변환.

---

## begin_jp2.js — Peter (NPC 9101001)

- **결과**: `data/npc_dialogues/9101001_Peter.csv`
- 대사 2줄 (`npc.sayNext` x2). 색상 코드/플레이스홀더 없음.
- 스크립트 마지막에 `player.changeMap(40000)` 부수효과가 있으나 대사가 아니므로 CSV에는 미포함
  (원본 동작 참고용으로만 여기 기록).

---

## claws_present.js — Maple Claws (NPC 9201030)

- **결과**: `data/npc_dialogues/9201030_MapleClaws.csv`
- 원본 헤더 주석은 "Maple Claws: Furrious Santa - Maplemas (NPC 9201030)". 콜론 뒤
  "Furrious Santa - Maplemas"는 이벤트/역할 설명으로 판단해 표시명에서 제외하고
  "Maple Claws"만 사용 (Cliff/Cody 등 기존 파일들의 단순 이름 패턴과 통일).
  **정확한 표시명 확인 필요 시 원본 주석 참고**.
- 대사 1줄 (`npc.sayNext`), 플레이스홀더 없음.

---

## cny.js — Mr. Moneybags (NPC 9300010)

- **결과**: `data/npc_dialogues/9300010_MrMoneybags.csv`
- 대사 1줄, 플레이스홀더 없음.

---

## easter.js — Mad Bunny (NPC 9102101)

- **결과**: `data/npc_dialogues/9102101_MadBunny.csv`
- 원본 헤더 주석은 "Mad Bunny: Easter Event (NPC 9102101)". claws_present.js와 동일한
  이유로 "Easter Event" 부분을 제외하고 "Mad Bunny"만 표시명으로 사용.
- 대사 1줄 (`npc.sayNext`), 콤마 다수 포함되어 CSV 인용 처리함. 플레이스홀더 없음.

---

## SKIP — TCG3.js (Corine: Taru Spirit, NPC 9201094)

- `npc.say`/`sayNext` 호출이 전혀 없음 (`//TODO: GMS-like conversation` 주석만 존재).

## SKIP — TCG5.js (Adonis, NPC 9201106)

- `npc.say`/`sayNext` 호출이 전혀 없음 (`//TODO: GMS-like conversation` 주석만 존재).

## SKIP — bookPrize.js (Chef, NPC 1002006)

- `npc.say`/`sayNext` 호출이 전혀 없음 (`//TODO: GMS-like conversation` 주석만 존재).

## 정정: bush1.js (a pile of flowers, NPC 1043000) — 변환함 (최초 SKIP 판단을 코디네이터가 뒤집음)

- **결과**: `data/npc_dialogues/1043000_APileOfFlowers.csv` (1줄)
- 배치 에이전트는 조건부 로직이 있다고 스킵했으나, 코디네이터 재검토 결과 `npc.say(...)`가
  **딱 하나뿐**이고(인벤토리 꽉 찼을 때만 나오는 안내문), 그 앞의 아이템 지급 로직은 대사가 아니라
  단순 보상 처리라 배타적 "여러 대사 중 선택" 문제가 없음 — `subway_get1.js`(배치5, 동일 패턴)와
  같은 방식으로 안전하게 1줄 변환 가능하다고 판단해 변환함.

## 정정: bush2.js (a pile of herbs, NPC 1043001) — 변환함 (최초 SKIP 판단을 코디네이터가 뒤집음)

- **결과**: `data/npc_dialogues/1043001_APileOfHerbs.csv` (1줄)
- bush1.js와 동일한 이유로 변환.

## SKIP — crack.js (Door of Dimension, NPC 1061009)

- `switch (player.getJob())` 분기 및 `player.isQuestStarted(7501)`, `npc.makeEvent(...)`
  조건부 로직 포함 — 필터 예시에 명시된 `switch` 키워드에 해당하는 명백한 분기 스크립트.
  스킵.

## SKIP — elizaHarp1.js ~ elizaHarp7.js (Harp String <C>~<B>, NPC 2012027~2012033)

- 7개 파일 모두 `npc.say`/`sayNext` 호출이 전혀 없음. `map.soundEffect(...)` 한 줄만 존재하는
  사운드 재생 전용 스크립트 (대사 없음). 전부 스킵.

---


다른 배치와의 병합 충돌을 피하기 위해 CONVERSION_LOG.md와 별도로 기록.

---

## guildquest1_board.js — Bulletin Board (NPC 9040011)

- **원본**: `argonms-server/scripts/npcs/guildquest1_board.js`
- **결과**: `data/npc_dialogues/9040011_BulletinBoard.csv`
- `npc.say(...)` 1건(문자열 연결로 구성된 단일 호출) → CSV 1행으로 변환.
- `#bTo Participate :#k` → `To Participate :` : `#b`/`#k` 인라인 색상 코드 제거(Cliff 사례와 동일 처리).
- 원문 내부의 `\r\n` 줄바꿈은 실제 개행으로 보존하여 CSV의 따옴표 처리된 한 셀 안에 그대로 유지(표준 CSV는 따옴표 필드 내 개행 허용).
- 치환이 필요한 `#p...#`/`#t...#`/`#m...#` 태그 없음.

---

## levelup_open.js — Cody: Wizet Wizard (NPC 9200000)

- **원본**: `argonms-server/scripts/npcs/levelup_open.js`
- **결과**: `data/npc_dialogues/9200000_Cody.csv`
- `npc.say(...)` 1건 → CSV 1행. 색상 코드나 `#p...#` 등 치환 필요 태그 없음.
- 헤더 주석 형식이 "Cody: Wizet Wizard"로 콜론 뒤에 부제(직함)가 붙는 다른 ArgonMS NPC들과 동일한 패턴이라
  판단, 표시 이름(name 컬럼)은 콜론 앞부분인 "Cody"만 사용. 파일명도 `Cody` 사용.

---

## 스킵한 파일 (0건, 실제 대사 없는 스텁 스크립트)

아래 13개 파일은 모두 라이선스 헤더 + NPC 설명 주석뿐이고 `npc.say`/`npc.sayNext` 호출이 전혀 없음
(`//TODO: implement gachapon` 또는 `//TODO: GMS-like conversation` 주석만 존재) — 규칙에 따라 스킵.

- `gachapon1.js` — Gachapon (NPC 9100100), Henesys Market
- `gachapon2.js` — Gachapon (NPC 9100101), Ellinia
- `gachapon3.js` — Gachapon (NPC 9100102), Perion
- `gachapon4.js` — Gachapon (NPC 9100103), Kerning City
- `gachapon5.js` — Gachapon (NPC 9100104), Sleepywood
- `gachapon10.js` — Gachapon (NPC 9100109), New Leaf City
- `gachapon13.js` — EXP Gachapon (NPC 9100112) / Gachapon (NPC 9110012), Southperry / Lith Harbor
- `gachapon18.js` — Gachapon (NPC 9100117), The Nautilus
- `go_tree1.js` — Branch Snowman (NPC 2001001), Happyville
- `go_tree2.js` — Metal Bucket Snowman (NPC 2001002), Happyville
- `go_tree3.js` — Straw Hat Snowman (NPC 2001003), Happyville
- `go_victoria.js` — Rupi (NPC 2002000), Happyville
- `halloweenTrick.js` — Malady: Witch at Large - Halloween (NPC 9201028), Kerning City

---


이 배치는 아래 15개 파일을 검토. 대부분이 `npc.say`/`sayNext` 0건(TODO 스텁)이거나
if/else·switch 분기(퀘스트 상태 기반)를 포함해 순수 선형이 아니었음. 실제 변환은 2건.

---

## 변환됨

### nautil_cow.js — Tangyoon (NPC 1092000)
- **원본**: `argonms-server/scripts/npcs/nautil_cow.js`
- **결과**: `data/npc_dialogues/1092000_Tangyoon.csv`
- `npc.say()` 1줄뿐, 조건문 없음. 색상 코드/플레이스홀더 태그 없음. 그대로 변환.

### rein.js — Rain (NPC 12101)
- **원본**: `argonms-server/scripts/npcs/rein.js`
- **결과**: `data/npc_dialogues/12101_Rain.csv`
- `npc.sayNext()` x2 + `npc.say()` x1, 조건문 없음(순수 선형).
- `#b`/`#k` 색상 코드 제거.
- `#m1010000#` → `[Map 1010000]`, `#m60000#` → `[Map 60000]`, `#m102000000#` → `[Map 102000000]`
  (맵 이름 태그 — MSW 쪽에서 실제 맵 이름으로 수동 치환 필요, `#p...#` 아니지만 동일하게 플레이스홀더 처리).

---

## 스킵됨 — say/sayNext 0건 (TODO 스텁, 대사 내용 없음)

- **mike.js** — Mike (NPC 1040001): `//TODO: GMS-like conversation` 주석만 존재.
- **naomi.js** — John Barricade (NPC 9201051): 동일하게 TODO 스텁만 존재.
- **nautil_stone.js** — Shiny Stone (NPC 1092016): TODO 주석만 존재 (미구현 스크립트).
- **oldBook2.js** — Lisa (NPC 2012012): TODO 스텁만 존재.
- **party3_enter.js** — Wonky the Fairy (NPC 2013000): TODO 스텁만 존재.
- **party3_minerva.js** — Minerva the Goddess (NPC 2013002): TODO 스텁만 존재.
- **party3_play.js** — Chamberlain Eak (NPC 2013001): TODO 스텁만 존재.
- **refine_TCG1.js** — Professor Foxwit (NPC 9201052): TODO 스텁만 존재.

## 스킵됨 — 분기 로직 존재 (필터에서 걸러지지 않은 케이스, 강제 변환 안 함)

- **nautil_Abel1.js** — Bush (NPC 1094002/1094003/1094004/1094005/1094006): `player.isQuestStarted(2186)`
  체크 + `switch (Math.floor(Math.random()*2))` + `player.gainItem` 성공/실패 분기. 결과에 따라 서로 다른
  대사가 나오는 조건부 구조라 순수 선형이 아님 — 스킵.
- **nautil_black.js** — Muirhat (NPC 1092007): `if (!player.isQuestStarted(2175))` 기준으로 완전히
  다른 두 대사 경로(단일 대사 vs 2줄 대사+`player.changeMap`) — 스킵.
- **nautil_letter.js** — Trash Can (NPC 1092018): `player.hasItem`/`player.gainItem` 결과에 따라
  3갈래 대사 분기 — 스킵.
- **party1_enter.js** — Lakelis (NPC 9020000): `if/else if` 체인으로 파티 상태(인원수/레벨/이벤트 중복)에
  따라 서로 다른 단일 대사 중 하나만 출력되는 조건부 게이트 — 스킵.
- **pet_letter.js** — Trainer Frod (NPC 1012007): `player.hasItem`/`player.getPetCount` 기준 중첩
  if/else 분기 — 스킵.

## 미해결 플레이스홀더 (수동 확인 필요)

- `12101_Rain.csv`: `[Map 1010000]`, `[Map 60000]`, `[Map 102000000]` — 실제 맵 이름으로 교체 필요
  (원본 `#m<id>#` 태그, MSW에는 대응 자동 치환 문법 없음).

---


이 배치는 `CONVERSION_LOG.md`와 병행 작업 중인 병렬 배치라 충돌 방지를 위해 별도 파일로 기록.
각 항목: 원본 경로, 결과 CSV 경로, NPC id/이름, 특이사항.

---

## s4common1_out.js — Tylus (NPC 2022004) — **정정: SKIPPED (검수 중 오류 발견)**

- 이 배치 에이전트가 최초에 `data/npc_dialogues/2022004_Tylus.csv`(2줄)로 변환했으나,
  코디네이터가 원본을 재확인한 결과 두 `say` 호출이 **상호 배타적** 조건(`player.hasItem`으로 인벤토리
  꽉 찼는지)에 따른 서로 다른 결과이지 순차 진행이 아님을 확인 — CSV로 이어붙이면 "항상 두 메시지가
  순서대로 뜬다"는 잘못된 동작이 됨. **CSV 삭제함.** 상태 조건부 분기 NPC로 재분류(아래 "상태 조건부
  분기 — 후속 처리 필요" 목록 참고).
- 배치 지시("askMenu/askYesNo/switch가 없으면 선형으로 취급")가 이 케이스(if/else 조건부 분기)를
  못 걸러냈다는 게 이번에 드러난 프로세스 허점.

---

## s4freeze_item.js — Ancient Icy Stone (NPC 2030014) — **정정: SKIPPED (검수 중 오류 발견)**

- 최초 변환(`2030014_AncientIcyStone.csv`, 3줄)도 위와 동일한 이유로 잘못됨 — `if/else if/else` 셋 중
  실제로는 매번 하나만 보임(아이템 소지 여부에 따라 배타적). **CSV 삭제함.** 상태 조건부 분기로 재분류.

---

## s4mind_in.js — Shulynch (NPC 1092008) — SKIPPED

- 본문이 `//TODO: GMS-like conversation` 주석뿐, `npc.say`/`sayNext` 0줄. 변환 대상 없음.

---

## s4snipe.js — Insignificant Being (NPC 1061012) — **정정: SKIPPED (검수 중 오류 발견)**

- 최초 변환(`1061012_InsignificantBeing.csv`, 7줄)도 동일한 이유로 잘못됨 — 파티 유무/인원수/레벨/직업
  조합에 따른 다단계 `if/else`로, 7개 메시지 중 매번 정확히 하나만 나옴(파티 상태에 따른 배타적 결과).
  **CSV 삭제함.** 이 중에서도 특히 가장 복잡한 사례(4중 중첩 조건 + 반복문으로 파티원 순회) — 상태
  조건부 분기로 재분류.

---

## s4strike.js — Lord Jonathan (NPC 1092019)

- **결과**: `data/npc_dialogues/1092019_LordJonathan.csv`
- 1줄, `npc.say` 단일 호출. 조건문 없음.
- 태그 없음.

---

## s4tornado.js — Maple Leaf Marble (NPC 2012023) — **정정: SKIPPED (검수 중 오류 발견)**

- 최초 변환(`2012023_MapleLeafMarble.csv`, 2줄)도 동일한 이유로 잘못됨 — `if (!gainItem) say / else say`는
  아이템 획득 성공/실패 중 하나만 보여주는 배타적 결과. **CSV 삭제함.** 상태 조건부 분기로 재분류.

---

## subway_get1.js — Treasure Chest (NPC 1052008)

- **결과**: `data/npc_dialogues/1052008_TreasureChest.csv`
- 1줄, `npc.say`(아이템 획득 실패 시 안내문). 조건부 보상 로직(`isQuestActive`/랜덤 보상)은
  대사가 아니므로 CSV에는 반영 안 함.
- 태그 없음.

---

## subway_get2.js — Treasure Chest (NPC 1052009)

- **결과**: `data/npc_dialogues/1052009_TreasureChest.csv`
- subway_get1.js와 동일 패턴, 1줄. NPC id만 다름(파일명이 id로 구분되어 이름 충돌 없음).
- 태그 없음.

---

## subway_get3.js — Treasure Chest (NPC 1052010)

- **결과**: `data/npc_dialogues/1052010_TreasureChest.csv`
- 위 두 파일과 동일 패턴, 1줄.
- 태그 없음.

---

## tcg4_7.js — T-1337 (NPC 9201101) — SKIPPED

- `//TODO: GMS-like conversation` 주석뿐, say/sayNext 0줄.

---

## tcg4_8.js — Stirgeman (NPC 9201102) — SKIPPED

- `//TODO: GMS-like conversation` 주석뿐, say/sayNext 0줄.

---

## viola_blue.js — a pile of blue flowers (NPC 1063001)

- **결과**: `data/npc_dialogues/1063001_APileOfBlueFlowers.csv`
- 1줄, `npc.say`(아이템 획득 실패 시 안내문). subway_get 계열과 동일한 패턴(퀘스트 보상 실패 안내).
- 태그 없음.

---

## viola_pink.js — a pile of pink flowers (NPC 1063000)

- **결과**: `data/npc_dialogues/1063000_APileOfPinkFlowers.csv`
- 1줄, 위와 동일 패턴.
- 태그 없음.

---

## viola_white.js — a pile of white flowers (NPC 1063002)

- **결과**: `data/npc_dialogues/1063002_APileOfWhiteFlowers.csv`
- 1줄, 위와 동일 패턴.
- 태그 없음.

---

## wxmasA.js — Roodolph: Reindeer (NPC 9220005) — SKIPPED

- `//TODO: GMS-like conversation` 주석뿐, say/sayNext 0줄.

---

## wxmasB.js — Happy: Snow Fairy (NPC 9220004) — SKIPPED

- `//TODO: GMS-like conversation` 주석뿐, say/sayNext 0줄.

---

## 요약 (코디네이터 검수 후 정정됨)

- **변환 확정: 7개** (1092019_LordJonathan, 1052008/1052009/1052010_TreasureChest,
  1063000/1063001/1063002_APileOf*Flowers)
- **정정: 상태 조건부 분기로 재분류(4개)** — s4common1_out.js, s4freeze_item.js, s4snipe.js, s4tornado.js.
  배치 에이전트가 처음엔 "askMenu/askYesNo/switch 없으면 선형"이라는 지시를 따라 변환했으나, 코디네이터가
  원본을 재확인한 결과 전부 `if/else`로 갈리는 **상호 배타적** 결과였음(항상 여러 줄이 순서대로 뜨는 게
  아니라 조건에 따라 그중 하나만 뜸). 잘못된 CSV는 삭제함. 이건 "메뉴 선택형 분기"(NpcBranchTalk.lua
  대상)와도 다른 **제3의 카테고리**(상태 조건부 분기)로, docs/msw_lua_notes.md에 새로 기록하고 별도
  Task로 분리함.
- 스킵(대사 없음): 5개 (s4mind_in.js, tcg4_7.js, tcg4_8.js, wxmasA.js, wxmasB.js) — 전부
  `//TODO: GMS-like conversation` 주석만 있고 실제 say/sayNext 대사가 0줄.
- 태그(`#p`/`#h`/`#t`/`#m`/`#b`/`#k` 등) 관련 수동 확인 필요 항목: 없음.
