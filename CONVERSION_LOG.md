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
- **원문의 `askYesNo` 반환값 해석에 대한 불확실성 → 나중에 정정됨**: 처음엔 ArgonMS Java 소스만으로는
  0/1이 Yes/No 중 무엇인지 확정할 수 없어서, 다른 MapleStory 서버 에뮬레이터들의 통상적 관례
  (0=Yes, 1=No)를 가정해 `optionIndex=0`→"Yes", `optionIndex=1`→"No"로 라벨을 붙였었음.
  **이후(분기형 배치 A 변환 도중) `herb_out.js`/`friend00.js` 등 여러 파일의 스크립트 로직을 직접
  대조해보니 실제로는 정반대(`selection==1`이 "예", `selection==0`(else)이 "아니오")임이 명확히
  확인됨** — 예: `friend00.js`는 `if (selection==1)`일 때 "좋아요, 하겠습니다" 흐름으로 이어지고
  `else`(0)일 때 거절 대사가 나옴. `herb_out.js`는 `askYesNo(...) == 1`일 때만 실제로 맵 이동(수락)이
  일어남. 이 저장소의 모든 Choice CSV에서 `optionIndex=0`↔`optionIndex=1`의 **라벨(Yes/No)을
  스왑**하여 정정함 (targetRow는 원래도 코드의 `if(selection==1)/else` 분기를 그대로 반영해 정확했으므로
  건드리지 않음 — 라벨만 틀려 있었음). 영향받은 파일: 이 파일(Mong from Kong)과 분기형 배치 A의
  askYesNo 12건 전부.
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

---

## #4~. 분기형 대화 배치 A (askMenu/askYesNo, 순수 메뉴형 21개 중 11개)

**중요 정정**: 아래 로그의 'askYesNo 0/1 매핑 공통 가정' 절은 서브에이전트가 go_pc.js 선례를 따라
0=Yes/1=No로 가정한 원본 기록이나, 이는 틀렸음이 이후 확인됨 (herb_out.js/friend00.js 등에서
selection==1이 명백히 '예' branch). **실제로는 1=Yes, 0=No이며, 아래 로그에 나열된 모든 Choice CSV의
Yes/No 라벨은 코디네이터가 이미 스왑하여 정정 완료함** (targetRow는 원래도 정확했으므로 유지).
이 로그 본문은 변환 당시의 원래 판단 근거(구조 파악, STATE-DEPENDENT 탐지 등)를 보존하기 위해
그대로 남기되, Yes/No 매핑 부분만 위와 같이 정정되었다는 점을 참고할 것.


11개 파일 전부 변환함(스킵 없음). 패턴: `docs/msw_lua_notes.md`의 "분기형 대화(선택지 메뉴)" 설계,
`CONVERSION_LOG.md` #2 Mong from Kong(go_pc.js) 사례와 동일. 컴포넌트는 기존
`scripts/components/NpcBranchTalk.lua` / `NpcOptionButton.lua` 재사용(신규 작성 없음).

## askYesNo 0/1 매핑 공통 가정 (전 파일 동일 적용)

go_pc.js 선례(CONVERSION_LOG.md #2)를 그대로 따름: **`selection == 0` → optionIndex0/"Yes",
`selection == 1` → optionIndex1/"No"**. ArgonMS 소스만으로는 실제 클라이언트 버튼 순서를 확정할 수
없어 다른 서버 에뮬레이터 관례를 차용한 가정이며, **미검증**. 이 배치의 모든 Choice CSV가 이 규칙을
기계적으로 일관되게 적용함 — 일부 파일(herb_out.js, out_tree.js 등)은 이 매핑이 대사 내용과 직관적으로
안 맞아 보일 수 있으나(예: "Yes"가 questionable 쪽에 매핑되는 것처럼 보임), go_pc.js 사례와의 일관성을
우선함. 틀렸다면 각 Choice CSV의 optionIndex 0/1 레이블만 맞바꾸면 되는 정도의 문제.

---

## herb_out.js — Louis (NPC 1032004)

- **결과**: `Talk_1032004_Louis.csv`, `Choice_1032004_Louis.csv`
- 구조: `askYesNo` 1개, 양쪽 다 후속 대사 없음. `selection==1`일 때만 `player.changeMap(101000000)`
  (순수 부수효과, 대사 없음) — targetRow 비움, 부수효과는 여기 기록만 하고 구현 안 함(TeleportService 미검증).
  `selection==0`(암묵적)은 아무 동작 없음(대화 종료).
- 태그/색상코드 없음. STATE-DEPENDENT 없음.

## begin_jp3.js — Heena (NPC 2101)

- **결과**: `Talk_2101_Heena.csv`, `Choice_2101_Heena.csv`
- 구조: `askYesNo` 1개, 양쪽 다 후속 대사 1줄씩(3행 구성). `result==1`→"Then, I will send you out..."(row2,
  부수효과 `player.changeMap(3)` 동반, 기록만 함) / else→"Haven't you finish..."(row3).
- 태그/색상코드 없음.

## flower_out.js — Crumbling Statue (NPC 1061007)

- **결과**: `Talk_1061007_CrumblingStatue.csv`, `Choice_1061007_CrumblingStatue.csv`
- 구조: 고정 인사말(`sayNext`, row1) → `askYesNo`(row2). `selection==1`이면 `player.changeMap(105040300)`
  부수효과만(대사 없음, targetRow 비움). `selection==0`은 아무 동작 없음.
- 태그/색상코드 없음.

## subway_out.js — Exit (NPC 1052011)

- **결과**: `Talk_1052011_Exit.csv`, `Choice_1052011_Exit.csv`
- 구조: `askYesNo` 1개, 양쪽 다 후속 대사 없음. `selection==1`→`player.changeMap(103000100)` 부수효과만.
- 태그/색상코드 없음.

## florina1.js — Pison: Tour Guide (NPC 1081001)

- **결과**: `Talk_1081001_Pison.csv`, `Choice_1081001_Pison.csv`
- **가장 복잡한 사례** — 몇 가지 특이사항:
  1. `npc.askMenu(...)`가 호출되지만 **반환값이 전혀 검사되지 않음**(원본 코드가 `let selection =`으로
     받지 않고 바로 버림) — 메뉴 자체가 옵션 1개짜리(`#L0#`)뿐이라 사실상 "확인" 버튼 역할. 선택 후
     코드는 무조건 다음 `askYesNo`로 진행하므로, `targetRow`를 다음 질문(row2)으로 연결해 그대로 반영함.
  2. `returnMap`/`spawnPoint`는 `npc.getRememberedMap("FLORINA")`가 반환하는 **런타임 동적 값**이라
     `#m<id>#` 같은 정적 태그 치환이 불가능함. `[Map <dynamic:returnMap>]`이라는 플레이스홀더로 표시함
     (일반 `#m<id>#` 정적 치환과 다른 종류의 미해결 항목 — MSW 쪽에서 "기억된 맵" 개념을 별도 프로퍼티로
     구현한 뒤 텍스트 바인딩 필요).
  3. `#m110000000#`(정적) → `[Map 110000000]`로 치환.
  4. `#b`/`#k` 색상 코드 제거. `#L0#` 뒤 텍스트("I would like to go back now.")는 Choice의 label로 분리.
  5. `selection==1`(row2 askYesNo) → `player.changeMap(returnMap, spawnPoint)` + `npc.resetRememberedMap(...)`
     부수효과만(대사 없음, targetRow 비움). `selection==0` → row3(고정 텍스트, 대화 종료).
- **후속 확인 필요**: `[Map <dynamic:returnMap>]` 플레이스홀더 3곳(row1 1개, row2 2개) — 사람이 MSW의
  "기억된 맵" 저장/조회 방식을 설계한 뒤 실제 텍스트 바인딩으로 교체해야 함.

## friend00.js — Mr. Goldstein: Buddy List Admin (NPC 1002003)

- **결과**: `Talk_1002003_MrGoldstein.csv`, `Choice_1002003_MrGoldstein.csv`
- **STATE-DEPENDENT placeholder 1건 발생** — 지시문의 우려 사례와 정확히 일치하는 패턴 발견:
  중첩 구조 `askYesNo(Q1) → [Yes] askYesNo(Q2) → [Yes] if(player.hasMesos(250000) && player.getBuddyCapacity() < 50) {...} else {...}`.
  Q1/Q2는 정상적인 메뉴 분기(row1, row3)로 변환했으나, Q2에서 "No"(관례상 `selection==1`) 선택 시의
  결과가 다시 플레이어 상태(소지금/버디 목록 용량)에 따라 갈리므로, 이 지점(row5)은 규칙대로
  실제 조건을 모델링하지 않고 플레이스홀더로 남김:
  `"[STATE-DEPENDENT: checks player.hasMesos(250000) && player.getBuddyCapacity() < 50 -- ...]"`.
- 5행 구성: row1(Q1, choice) / row2(outer No 결과, leaf) / row3(Q2, choice) / row4(Q2 Yes 결과, leaf,
  대사만 있고 부수효과 없음) / row5(Q2 No 결과, STATE-DEPENDENT placeholder).
- `#b...#k` 색상 코드 제거(원문 "250,000 mesos and I'll add 5 more slots..." 부분 등).
- **후속 확인 필요**: row5 — 퀘스트/인벤토리 시스템 조사 후 실제 조건부 로직으로 재작업 필요
  (msw_lua_notes.md "아직 미확인" 섹션 참고). 성공 시 `player.loseMesos`/`player.gainBuddySlots`에 대응하는
  MSW API도 미확인.

## Thomas.js — Thomas Swift: Amoria Ambassador (NPC 9201022)

- **결과**: `Talk_9201022_ThomasSwift_Henesys.csv` + `Choice_9201022_ThomasSwift_Henesys.csv`,
  `Talk_9201022_ThomasSwift_Amoria.csv` + `Choice_9201022_ThomasSwift_Amoria.csv` (**한 NPC에 2쌍**)
- 최상위 분기가 `askMenu`/`askYesNo`가 아니라 **`map.getId() == 100000000` vs `== 680000000`**(현재
  맵 위치)라서, 지시문의 "quest/item/level/party 상태" 필터에는 안 걸리지만 본질적으로는
  msw_lua_notes.md의 "제3의 카테고리"(상태 조건부 배타적 분기)와 같은 모양의 최상위 게이트임.
  다만 이 경우는 **퀘스트/아이템처럼 조회 API가 필요한 상태가 아니라 "NPC가 어느 맵에 있는가"**라서,
  MSW에서는 애초에 이 NPC를 헤네시스와 아모리아 두 곳에 **별개의 엔티티로 배치**하면 자연스럽게
  해결되는 문제로 판단 — 코드 하나를 조건부로 두는 대신 맵별로 독립된 Talk/Choice 테이블 쌍 2개로
  분리해 변환함(각 배치는 그 자체로 정상적인 askYesNo 메뉴 분기).
  각 쌍 내부: `selection==1`→"I hope you had a great time..." + `player.changeMap` 부수효과(row2),
  `selection==0`→"Ok, feel free to hang around..."(row3). 두 맵 버전이 텍스트까지 거의 동일함(원문 그대로 반영).
- 태그/색상코드 없음.

## out_tree.js — Scarf Snowman (NPC 2001004)

- **결과**: `Talk_2001004_ScarfSnowman.csv`, `Choice_2001004_ScarfSnowman.csv`
- 구조: `askYesNo` 1개. `selection==1`→`player.changeMap(209000000)` 부수효과만(대사 없음).
  `selection==0`(else)→row2("You need more time decorating trees...").
- 태그/색상코드 없음.

## begin_jp1.js — Sera (NPC 2100)

- **결과**: `Talk_2100_Sera_TrainingEntrance.csv` + `Choice_2100_Sera_TrainingEntrance.csv` (map 0/3 진입 시),
  `Talk_2100_Sera_UpperLevel.csv`만(map 1 진입 시, **Choice 파일 없음** — 선택지가 전혀 없는 순수 선형
  2줄이라 `NpcLinearTalk.lua` 패턴과 동일한 형태이지만, 파일명 일관성을 위해 이 배치 명명 규칙을 유지함).
- Thomas.js와 동일한 이유로 최상위 `map.getId()` 위치 게이트를 두 맵(입구/상급 훈련실)의 별개 엔티티
  배치로 해석해 2쌍으로 분리함.
- TrainingEntrance 쪽: 진짜 메뉴 분기 2단계(중첩 `askYesNo`) — `enterCamp` 질문(row1) → Yes/No,
  No 쪽에서 다시 `confirm` 질문(row3) → Yes/No. 이 중첩은 플레이어/퀘스트 상태 조건이 아니라 **둘 다
  실제 플레이어 선택**(연속된 두 번째 메뉴)이라 STATE-DEPENDENT 대상 아님 — 정상 변환함.
  row2/row4는 각각 `player.changeMap(1)`/`player.changeMap(40000)` 부수효과 동반(기록만 함).
- 태그/색상코드 없음.

## rank_user.js — (헤더에 NPC ID 명시 안 됨, "레벨 200 도플갱어 NPC")

- **결과**: `Talk_rank_user_LevelUpNPC_Stranger.csv`(Choice 없음, 1줄),
  `Talk_rank_user_LevelUpNPC_Namesake.csv` + `Choice_rank_user_LevelUpNPC_Namesake.csv`
- **주의**: 이 배치의 다른 10개 파일과 달리 헤더 주석에 숫자 NPC ID가 없음("Victoria Road: Bowman
  Instructional School (Map 100000201), ... 첫 전직 맵들에 나타나는 레벨 200 NPC"라고만 설명, 실제로는
  4개 맵에 각각 다른 이름의 NPC로 등장하는 공용 스크립트로 추정). 저장소 내 스크립트↔NPC ID 매핑 테이블을
  찾지 못해 파일명(`rank_user`)을 식별자로 사용함 — **실제 NPC ID(들) 확인 후 파일명 교체 필요**.
- 최상위 분기가 `player.getName() != npc.getNpcName()`(플레이어 자신의 이름과 NPC 이름이 같은지, 즉
  "이 NPC가 플레이어 자신의 도플갱어인가") — quest/item/level/party 키워드는 아니지만 정체성 상태 체크이므로
  Thomas.js/begin_jp1.js와 같은 방식(최상위 게이트 → 별도 플로우 2개)으로 처리함. 단, 이건 위치가 아니라
  "같은 NPC를 서로 다른 플레이어가 봤을 때" 다른 결과라 실제로는 엔티티 분리로 해결 불가 — **인게임 로직으로
  플레이어명/NPC명 비교가 필요**하며 이 비교 API가 MSW에서 확인되지 않음(별도 조사 필요, msw_lua_notes.md에
  미확인 항목 추가 권장).
- Stranger 플로우(row1)의 텍스트 `"Hello, I am [NPC name], and I am LEVEL [NPC level]."`은 원문이
  `npc.getNpcName()`/`npc.getNpcLevel()`을 그대로 삽입하는 동적 문자열이라 하드코딩 불가 — `[NPC name]`/
  `[NPC level]` 토큰으로 남김(정적 치환 태그가 아니라 매 NPC 인스턴스마다 실제 이름/레벨로 바인딩 필요).
- Namesake 플로우: `askYesNo` 1개. `selection==0`→"It's okay to take your time..."(row2). `selection==1`→
  `npc.refreshAppearance()` 부수효과 + "Your other self has been transformed..."(row3). 원본에 주석 처리된
  "하루 1회 제한" 로직(`/*...*/`)은 죽은 코드라 변환 대상에서 제외(원본에도 미구현 상태로 존재).
- `#b`/`#k` 색상 코드 제거("Hello, I am #b...#k" 부분).

## 3jobExit.js — Sparkling Crystal (NPC 1061010)

- **결과**: `Talk_1061010_SparklingCrystal.csv`, `Choice_1061010_SparklingCrystal.csv`
- 구조: `askYesNo` 1개. 내부에 `switch (map.getId())`가 있지만 이건 **대사를 가르는 조건이 아니라
  `player.changeMap`의 목적지 맵 ID를 계산하는 순수 부수효과 로직**(5개 출발맵 → 5개 도착맵 매핑,
  `npc.say`/`sayNext` 전혀 없음) — msw_lua_notes.md의 "제3의 카테고리"(대사를 가르는 조건) 정의에
  해당하지 않으므로 STATE-DEPENDENT 처리 대상 아님. `selection==1`→switch+`changeMap` 부수효과만(대사 없음).
  `selection==0`은 아무 동작 없음.
- 태그/색상코드 없음.

---

## 요약

- **변환**: 11/11개 전부 변환 (스킵 없음).
- **STATE-DEPENDENT placeholder**: 1건 — `Talk_1002003_MrGoldstein.csv` row5 (friend00.js, 소지금/버디
  목록 용량 조건).
- **최상위 위치/정체성 게이트로 인해 NPC 1개당 CSV 2쌍으로 분리한 경우**: 3건 — Thomas.js(맵 위치),
  begin_jp1.js(맵 위치, 그중 UpperLevel은 순수 선형이라 Choice 파일 없음), rank_user.js(플레이어명=NPC명
  여부, 후자는 진짜 위치 분리로 해결 안 되고 인게임 이름 비교 로직 필요 — 별도 미확인 항목).
- **미해결 플레이스홀더**: `[Map <dynamic:returnMap>]`(florina1.js, 3곳, 동적 맵 값 — 정적 `#m<id>#`
  치환과 다른 종류), `[NPC name]`/`[NPC level]`(rank_user.js Stranger 플로우, 동적 자기참조 값).
- **NPC ID 미확인**: rank_user.js — 헤더에 숫자 ID 없음, 파일명(`rank_user`)을 임시 식별자로 사용.
- **askYesNo 0/1 매핑 가정**: 전 파일 공통, go_pc.js 선례 그대로 적용(`selection==0`→"Yes",
  `selection==1`→"No") — 미검증, 틀렸다면 Choice CSV의 라벨만 바꾸면 됨.
- **`#p`/`#t`/`#m`(정적) 태그**: florina1.js의 `#m110000000#` 1건만 존재, `[Map 110000000]`로 치환 완료.

---

## #4~. 분기형 대화 배치 B (askMenu/askYesNo, 순수 메뉴형 21개 중 나머지 10개)

**정정**: 이 로그의 askYesNo 관련 Yes/No 라벨도 배치 A와 동일한 이유로 코디네이터가 스왑 정정함
(1=Yes, 0=No가 맞음 — CONVERSION_LOG.md #2 참고). targetRow는 원래도 정확했음.


이 배치는 `askMenu`/`askYesNo` 선택지 분기가 있는 NPC 10개 대상. `NpcBranchTalk.lua`/`NpcOptionButton.lua`
(CONVERSION_LOG.md #2 Mong from Kong 사례)와 동일한 패턴 사용. `CONVERSION_LOG.md`/`CONVERSION_LOG_branchA.md`와의
병합 충돌을 피하기 위해 별도 파일로 기록.

**공통 규칙**: `askYesNo`의 0/1 반환값은 CONVERSION_LOG.md #2(Mong from Kong)와 동일한 관례를 그대로 따름 —
`optionIndex`를 원본의 `selection` 숫자값과 동일하게 매칭하고(`selection==0` 분기 → `optionIndex=0`/label="Yes",
`selection==1` 분기 → `optionIndex=1`/label="No"), 어느 쪽이 실제 "예"/"아니오"에 해당하는지는 **텍스트 내용과 무관하게
기계적으로** 매핑함. 이 관례가 실제로 맞는지 확인 안 됨 — 여러 파일에서 "Yes" 버튼이 오히려 거절 텍스트로,
"No" 버튼이 오히려 진행 텍스트로 연결되는 것처럼 보이는 경우가 있는데, 이는 원본 코드 자체가 그렇게 되어
있어서 그대로 반영한 것(Mong from Kong 사례와 동일한 이슈).

---

## 1. NLC_Taxi.js — NLC Taxi (NPC 9201056)

- **결과**: `Talk_9201056_NLCTaxi.csv`, `Choice_9201056_NLCTaxi.csv`
- **구조**: `switch (map.getId())`로 두 개의 완전히 독립된 대화 트리(New Leaf City 쪽 / Phantom Forest 쪽)를 가짐.
  이건 상태 조건부 분기가 아니라 "이 NPC가 물리적으로 배치된 맵이 어디냐"에 따라 아예 다른 대화가 실행되는
  구조라, 하나의 Talk 테이블에 **두 개의 entry row**(row1: New Leaf City 출발, row6: Phantom Forest 출발)를
  두는 방식으로 표현함. MSW 쪽 스크립트는 `Entity.CurrentMap`으로 시작 행을 골라야 함(원본의
  `switch(map.getId())`를 그대로 반영).
- row3(New Leaf City)과 row6(Phantom Forest) 모두 `askYesNo`. 각각 Yes/No에 따라 `player.changeMap` 부수효과
  (682000000 / 600000000)와 단순 텍스트로 갈림 — state 의존 없음, 완전히 변환 가능.
- 색상 코드 `#b`/`#k` 제거(Phantom Forest, Prendergast Mansion, New Leaf City). `#p`/`#t`/`#m` 태그 없음.

## 2. guildquest1_comment.js — Shawn (NPC 9040002)

- **결과**: `Talk_9040002_Shawn.csv`, `Choice_9040002_Shawn.csv`
- **구조**: `while(loop)` 안에서 `askMenu` 4지선다 반복 FAQ. option0/1/2는 답변 후 다시 메뉴로 루프백(row1),
  option3은 `loop=false`로 대화 종료.
- **단순화 노트**: 원본은 최초 프롬프트(`str`)와 재질문(`"Do you have any other questions?"`)의 텍스트가
  다른데, 우리 CSV 모델은 루프백 시 항상 동일한 row1 텍스트(최초 전체 설명문)를 다시 보여줌 — 매 회차마다
  "Do you have any other questions?"로 축약되지 않는 사소한 콘텐츠 차이 있음(state-dependent 이슈 아님, 단순
  반복 텍스트 변형을 CSV 모델이 지원 안 하는 것뿐).
- `#t4001024#` → `[Item 4001024]` 치환 (row1, row4, row6). `#b` 색상 코드 제거.

## 3. hotel1.js — Hotel Receptionist (NPC 1061100)

- **결과**: `Talk_1061100_HotelReceptionist.csv`, `Choice_1061100_HotelReceptionist.csv`
- **구조**: 인트로 → `askMenu`(Regular/VIP 사우나) → 각 선택마다 `askYesNo` 확인 → **그 Yes/No 결과가 다시
  `player.hasMesos(price)` 체크로 갈림(인벤토리/재화 상태 의존)**. 이 중첩 상태 체크는 지침의 "중첩 조건이
  더 있으면 그 지점에서 멈추고 STATE-DEPENDENT 자리표시자만 남긴다" 규칙 적용 대상.
- **STATE-DEPENDENT 자리표시자 2개**: row5(Regular, 499메소 체크), row7(VIP, 999메소 체크). 각각
  `player.hasMesos` 성공/실패 시 원문 텍스트를 placeholder 안에 그대로 남겨둠.
- Yes/No 관례상 "No" 옵션이 오히려 메소 체크(STATE-DEPENDENT) 쪽으로, "Yes" 옵션이 "다른 서비스도 있으니
  잘 생각해보라"는 거절성 텍스트로 연결됨 — 위 공통 규칙의 기계적 매핑 결과.
- 태그/색상코드 없음.

## 4. getAboard.js — Platform Usher: Station Info (NPC 2012006)

- **결과**: `Talk_2012006_PlatformUsher.csv`, `Choice_2012006_PlatformUsher.csv`
- 표시 이름은 원본 "Platform Usher: Station Info"에서 부제 제외하고 "Platform Usher"만 사용(Cody/MapleClaws
  선례와 동일한 처리).
- **구조**: `askMenu`(플랫폼 5택) → 선택한 목적지에 따라 다른 `askYesNo` 확인문 → Yes/No 결과는 `player.changeMap`
  부수효과 또는 단순 텍스트로 갈림. 중첩된 state 체크 없음(맵 선택에 따른 문구 차이는 이미 플레이어의 메뉴
  선택으로 결정되는 것이라 상태 조건부가 아님) — **완전히 변환 가능**.
- 5개 목적지 중 3개(엘리니아/루디브리엄/레아프레)는 "No" 응답 텍스트에 "정해진 시간표가 있으니 놓치지 마라"
  문장이 추가로 붙음 — row7/row8로 분리해서 반영.
- 원문 자체 오탈자: case2("레아프레") 확인 문구가 "the ship that heads to Leafre"라고 되어 있는데 메뉴
  라벨은 "The platform to **Hak** that heads to Leafre"임(Hak vs ship 불일치) — 원문 그대로 보존, 수정 안 함.
  case4(아리안트) 문구는 원문에 물음표가 아예 빠져있음 — 이것도 원문 그대로 보존.
  Yes/No 옵션 텍스트만 있고, 실제 `player.changeMap(map, "west00")` 부수효과는 "No"(optionIndex=1) 쪽에
  연결됨(공통 규칙에 따른 기계적 매핑 결과) — targetRow 빈 값으로 처리하고 로그에 남김.
- 색상코드 `#b`/`#k` 제거. `#p`/`#t`/`#m` 태그 없음.

## 5. guild_mark.js — Lea: Guild Emblem Creator (NPC 2010008)

- **결과**: `Talk_2010008_Lea.csv`, `Choice_2010008_Lea.csv`
- **구조**: 이 파일은 최상위부터 `if (player.getGuildRank() != 1)`라는 플레이어 상태 게이트로 시작함(메뉴에
  진입하기도 전에 상태 조건부터 있음 — 배치 지시의 "top level은 필터링되어 있다"는 전제가 완전히는 성립하지
  않는 사례). 그 아래 `askMenu`(등록/삭제)의 각 옵션도 진입하자마자 바로 `player.hasGuildEmblem()` 상태
  체크로 갈림.
- **STATE-DEPENDENT 자리표시자 3개**:
  - row1: 최상위 길드 마스터 여부 게이트(길드 마스터 아니면 단일 거절 메시지로 끝, 맞으면 메뉴 진행).
  - row3(등록 옵션): `player.hasGuildEmblem()` 체크 이후 `askYesNo`(500만 메소) + 그 안에서 다시
    `player.hasMesos(5000000)` 체크 + `npc.askGuildEmblem()`(엠블럼 패턴 피커) — 중첩이 深해서 이 지점에서
    멈추고 placeholder로 남김.
  - row4(삭제 옵션): `player.hasGuildEmblem()` 체크 이후 `askYesNo`(100만 메소) + `player.hasMesos(1000000)`
    체크 — 동일하게 placeholder 처리.
- 이 3개 모두 "퀘스트/인벤토리/파티 상태" 범주는 아니고 "길드" 시스템 상태(길드 랭크, 엠블럼 보유 여부,
  메소)인데, msw_lua_notes.md의 미확인 목록에 길드 시스템이 명시되어 있지 않으므로 별도 확인 필요 항목으로
  추가해야 함.
- `#r`/`#b`/`#k` 색상 코드 제거.

## 6. goOutWaitingRoom.js — Crewmember (NPC 1032009/2012002/2012022/2012024/2041001/2082002/2102001)

- **결과**: `Talk_1032009_Crewmember.csv`, `Choice_1032009_Crewmember.csv` (첫 NPC ID로 파일명 대표, 7개 NPC ID
  모두 동일 스크립트 공유)
- **구조**: 단순 `askYesNo` 1개. Yes/No에 따라 `player.changeMap(toMap)` 부수효과 또는 단순 텍스트로 갈림.
  State 의존 없음, 완전 변환.
- `toMap`은 현재 맵(`map.getId()`)에 따라 결정되는 8-way 매핑 테이블(101000301→101000300,
  200000112/122/132/152→200000100, 220000111→220000100, 240000111→240000100, 260000110→260000100) —
  플레이어 상태가 아니라 "이 NPC 인스턴스가 물리적으로 어느 맵에 배치됐는지"에 따른 것이라 7개 NPC 인스턴스
  전부 각자의 고정 목적지를 갖는 구조. 실제 MSW 구현 시 인스턴스별로 이 표를 참고해 수동 설정 필요(부수효과라
  CSV의 targetRow는 공통으로 빈 값 처리).
- 태그/색상코드 없음.

## 7. levelUP.js — KIN (NPC 9900000)

- **결과**: `Talk_9900000_KIN.csv`, `Choice_9900000_KIN.csv`
- **특이 케이스**: GM 전용 외형 변경 디버그 NPC. `askMenu`(Skin/Hair/Hair Color/Eyes/Eyes Color/Random New
  Look) 6지선다이지만, 어떤 옵션도 **대사 텍스트가 전혀 없음** — 전부 `npc.askAvatar()`(별도 아바타 피커
  UI 호출) 또는 `player.setSkin/setFace/setHair` 같은 순수 부수효과로 끝남.
- 규칙 5(순수 부수효과, 대사 없음)에 해당 — STATE-DEPENDENT가 아니라 그냥 "이 옵션엔 대사가 없다"는
  케이스. 6개 옵션 전부 `targetRow` 빈 값 처리, 각각의 실제 동작(아바타 피커 종류, 어떤 스타일 배열을
  넘기는지)을 로그에 남김:
  - Skin → `npc.askAvatar` with `getAllSkinColors()` → `player.setSkin`
  - Hair → `getAllHairStyles()` → `player.setHair`
  - Hair Color → `getAllHairColors()` → `player.setHair`
  - Eyes → `getAllEyeStyles()` → `player.setFace`
  - Eyes Color → `getAllEyeColors()` → `player.setFace`
  - Random New Look → 위 4개 배열에서 무작위로 하나씩 골라 즉시 적용(확인 UI 없음)
- 아바타 피커(색상/스타일 그리드 선택 UI) 자체가 MSW에 대응 컴포넌트 있는지 미확인 — 별도 조사 필요 항목.
- `#b`/`#k` 색상 코드 제거(메뉴 라벨).

## 8. crane.js — Hak: Warp Assistant (NPC 2090005)

- **결과**: `Talk_2090005_Hak.csv`, `Choice_2090005_Hak.csv`
- **원본 소스에 실제 JavaScript 문법 오류 발견**: `argonms-server/scripts/npcs/crane.js`가 그대로는 파싱이
  안 되는 상태임.
  1. 66번째 줄: `player.changeMap(info[2];` — 닫는 괄호 누락.
  2. 79번째 줄: `selectWarp([["Orbis", 6000, 200090310, 200000141], ["Herb Town", 1500, 251000000], "Mu Lung", "Orbis");`
     — 바깥 배열 리터럴이 "Mu Lung"/"Orbis" 인자 앞에서 닫히지 않음(대괄호 누락), 원래 의도는 아마
     `selectWarp([[...],[...]], "Mu Lung", "Orbis")`였을 것으로 추정되나 확신할 수 없음.
- **맵별로 3개의 독립 entry**(NLC_Taxi와 동일하게 `Entity.CurrentMap` 기준 시작 행 분기 필요):
  - row1 (Map 200000141, Orbis→Mu Lung): 정상 파싱 가능. `askMenu`(1개 옵션뿐이지만 배열이라 메뉴 UI를
    타는 구조) → 선택 후 **STATE-DEPENDENT**(row2): 크레인 이벤트 도킹 상태 + 6000메소 체크. placeholder 처리.
  - row3 (Map 251000000, Herb Town→Mu Lung): 정상 파싱 가능하지만, `selectWarp(["Mu Lung", 1500, 250000100],
    "Orbis", "Mu Lung")` 호출의 `src="Orbis"`가 물리적으로 이 NPC가 있는 맵(Herb Town)과 안 맞음 — 아마
    Mu Lung Temple 케이스에서 복붙하며 생긴 원본 버그로 추정, 텍스트는 원문 그대로("Orbis"로) 보존.
    `askYesNo` 이후 **STATE-DEPENDENT**(row4): 1500메소 체크. 게다가 이 체크의 성공/실패 분기 자체가
    코드상 뒤집혀 있는 것처럼 보임(메소 차감 **실패** 시 `changeMap` 호출, **성공** 시 "메소 충분하냐"는
    경고 문구 표시) — 원본 버그로 추정, placeholder 텍스트에 그대로 명시.
  - row6 (Map 250000100, Mu Lung Temple): 위 문법 오류 때문에 **재구성 불가** — `[UNRESOLVED: ...]` 텍스트로
    남기고 원본 스크립트 수정 후 재변환 필요하다고 명시.
- **후속 조치 필요**: 이 파일은 원본 저장소(argonms-server) 자체의 버그 가능성이 있음 — 변환보다 원본 확인이
  선행되어야 함.

## 9. Event00.js — Paul/Jean/Martin/Tony: Event Assistant (NPC 9000000/9000001/9000011/9000013)

- **결과**: `Talk_9000000_EventAssistants.csv`, `Choice_9000000_EventAssistants.csv` (대표 ID 9000000 사용,
  4개 NPC ID 전부 파일명에 표기하지 않고 로그에 기록)
- **구조**: `switch(npc.getNpcId())`로 4개 NPC 각각 다른 인트로 대사(1~2줄) + 각기 다른 멘트로 이어지는
  동일한 3지선다 `askMenu`(이벤트가 뭔지 / 게임 설명 / 같이 가기)로 수렴. option1은 다시 6지선다 서브메뉴
  (게임별 설명, 전부 순수 정보성 텍스트)로 갈라짐. **state 의존 조건 없음** — `#p<id>#` 태그와 이벤트 설명
  텍스트만 있는 순수 정적 분기라 완전히 변환 가능.
- 4개 NPC가 하나의 Talk 테이블에 4개의 독립 entry(row1=Paul, row3=Jean, row6=Martin, row9=Tony)로 들어가고,
  이후 공용 서브 콘텐츠(row12~20)로 수렴하는 구조 — NLC_Taxi/crane.js와 같은 다중 entry 패턴.
- `#p9000000#`/`#p9000001#`/`#p9000011#`/`#p9000013#` → `[NPC 9000000]` 등으로 치환.
  `#e1. #n`/`#e2. #n`/`#e3. #n` 형태의 `#e`/`#n` 색상 코드 및 `#b`/`#r`/`#k` 색상 코드 전부 제거.
  case2(마지막 옵션) 텍스트의 `#t4031019#` → `[Item 4031019]` 치환.
- 서브메뉴의 [Vikin] 언급은 원문 그대로 두었음(별도 NPC 이름, 치환 태그 아님).

## 10. begin5.js — Robin (NPC 2003)

- **결과**: `Talk_2003_Robin.csv`, `Choice_2003_Robin.csv`
- **구조**: `while(true)` 무한 루프 안에서 18지선다 `askMenu`(초보자 FAQ). 모든 옵션이 순수 정적 텍스트
  (일부는 2~4줄의 연속 `npc.sayNext`), state 의존 조건 전혀 없음 — 완전히 변환 가능. **탈출 옵션 자체가
  없음**(guildquest1_comment.js와 달리 "됐어요" 같은 종료 선택지가 없어서, 모든 옵션이 답변 후 항상
  row1으로 루프백함 — 원본 동작 그대로).
- **규칙 6 해당 사례(대형 FAQ 메뉴)**: 18개 옵션은 msw_lua_notes.md에 언급된 고정 슬롯 UI(예: 6개) 한계를
  크게 초과함 — `ScrollLayoutGroupComponent` 기반의 스크롤형 선택지 UI 설계가 별도로 필요함(아직 미조사
  상태, msw_lua_notes.md "아직 미확인" 목록에 이미 존재하는 항목).
- `#m60000#` → `[Map 60000]` 치환(옵션5 "이 섬에 대해 더 알려줘" 답변 중). `#b`/`#k` 색상 코드 제거.
  옵션11/15 라벨의 "(S)"/"(K)" 표기는 원문 그대로 보존(태그가 아니라 원문 텍스트의 일부로 판단).

---

## 요약

- **변환 완료: 10/10 파일** (모두 최소한 메뉴 골격까지는 변환함, 규칙 6에 따라 스킵 없이 전부 처리).
- **STATE-DEPENDENT 자리표시자가 필요했던 파일: 3개**
  - `hotel1.js` (Hotel Receptionist, 1061100) — 2개 placeholder (Regular/VIP 사우나 메소 체크).
  - `guild_mark.js` (Lea, 2010008) — 3개 placeholder (최상위 길드마스터 게이트 + 등록/삭제 각각의
    엠블럼 보유 여부 체크).
  - `crane.js` (Hak, 2090005) — 2개 placeholder (크레인 이벤트/메소 체크) + 문법 오류로 인한 UNRESOLVED
    1개(별도 카테고리, state-dependent라기보다 원본 소스 버그).
- **원본 소스 버그 발견**: `crane.js` — 문법 오류 2건(괄호/대괄호 누락), 확인 필요.
- **미해결 태그**: 없음(모든 `#p`/`#t`/`#m` 태그는 `[NPC <id>]`/`[Item <id>]`/`[Map <id>]`로 치환 완료,
  단 실제 이름으로의 최종 치환은 여전히 수동 확인 권장 — 기존 배치들과 동일한 수준).
- **askYesNo Yes/No 매핑 가정**: 전체 10개 파일 공통으로 Mong from Kong(CONVERSION_LOG.md #2) 관례를
  기계적으로 적용함. 실제로 맞는지는 미확인 — 틀렸다면 각 파일의 Choice CSV에서 두 옵션의 targetRow를
  맞바꾸면 됨.
- **다중 entry 구조를 쓴 파일 3개** (NPC 배치 맵/ID에 따라 오프닝이 갈리는 경우): `NLC_Taxi.js`(맵 2종),
  `crane.js`(맵 3종), `Event00.js`(NPC ID 4종) — 전부 "row1이 항상 entry"라는 기본 스펙에서 벗어나
  `Entity.CurrentMap`/NPC ID로 시작 행을 고르는 방식이 필요함을 로그에 명시함.

---

## #6 (일부). 포탈 스크립트 27개 — 사전조사 + 자유시장 출입구 19개 변환

`argonms-server/scripts/portals/*.js` 27개를 전수 분류(자세한 근거는 `docs/msw_lua_notes.md` "포탈(Portal)"
절 참고):

- **2개 (enter_nautil.js, ninjaAmbush.js)**: 조건 없는 단순 워프 — **변환 결과물 없음**(의도적).
  MSW 에디터에서 포탈 두 개를 배치하고 `PortalComponent.PortalEntityRef`로 서로 연결하면 스크립트 없이
  동일하게 동작함.
- **17개 (market00~17.js, 자유시장 출입구)**: 처음엔 전부 "출구"로 잘못 분류했다가 재확인 후 정정 —
  **market00.js 1개만 출구**(귀속 위치로 복귀), **market01~17.js 16개는 입구**(마을→자유시장, 스크립트
  본문이 16개 전부 동일). 아래 2개 재사용 스크립트로 변환:
  - `scripts/components/FreeMarketEntrance.lua` — 16개 입구 포탈에 동일하게 부착. 실제 워프는
    `PortalEntityRef`로 디자인타임 연결(스크립트 불필요), 이 스크립트는 "돌아올 위치 기억"만 담당
    (`PortalUseEvent` 시점에 `_DataStorageService:GetUserDataStorage(userId):SetAndWait(...)`로
    현재 맵 이름+좌표 저장).
  - `scripts/components/FreeMarketExit.lua` — market00.js 1개에 대응. 저장된 위치를 읽어(`GetAndWait`)
    `_TeleportService:TeleportToMapPosition(...)`로 동적 텔레포트. 목적지가 플레이어마다 달라 정적
    `PortalEntityRef` 연결로는 불가능해서 스크립트가 필요한 유일한 케이스.
  - ArgonMS는 맵을 정수 ID로 식별하지만 MSW는 자체 제작 맵이라 이름(문자열) 기준으로 재설계 — 원본의
    "Perion/spawnPoint 28" 같은 기본값은 MSW 쪽 실제 맵 이름/좌표로 사람이 다시 채워야 함
    (`defaultMapName`/`defaultX`/`defaultY` 프로퍼티로 노출해둠).
  - **미검증**: `TransformComponent.Position`의 실제 필드명(x/y 대소문자 등), `Vector3(...)` 생성자
    시그니처, `TeleportToMapPosition`이 다른 맵으로의 순간이동까지 실제로 지원하는지(설명상 지원하는
    것으로 보이나 실행 예제를 직접 보지 못함).
- **5개 (advice00/04/06/07/08.js)**: `portal.showHint`+`portal.abortWarp` — 워프 없는 튜토리얼 힌트.
  MSW의 대응 UI 미확인 — **미변환**, 추가 조사 필요.
- **2개 (q2073.js, party1.js)**: 퀘스트/이벤트 인스턴스 상태 의존 — task #5/#10과 동일한 사유로 **미변환**,
  퀘스트 시스템 조사 후 처리 예정.

**요약**: 27개 중 19개(2 스크립트없음 + 17 자유시장) 처리, 7개(힌트 5 + 퀘스트의존 2) 보류.

---

## #5. 퀘스트 스크립트 7개 — 6개 변환, 1개 스킵

`argonms-server/scripts/quests/*.js`. 이 스크립트들은 (NPC 대화와 달리) `npc.startQuest()`/
`npc.completeQuest()`, `player.gainExp/gainItem/loseItem/loseMesos/evolveBossPet` 같은 **게임플레이
부수효과가 대사보다 중요한 비중을 차지**함. 사전조사에서 확인한 대로 MSW는 퀘스트 전용 시스템이 없으므로
(`UserDataStorage`로 직접 구현) 및 인벤토리는 있음(`InventoryComponent`/`_ItemService`)을 전제로 변환.

- **q1021s.js (Roger's Apple, Quest 1021, 시작)** → `Talk_1021_RogersApple_Start.csv` +
  `Choice_1021_RogersApple_Start.csv`. `askAccept`(1=수락/0=거절 — askYesNo와 동일 관례로 추정, 라벨은
  "Accept"/"Decline"으로 구분해 표기) 분기. 수락 시 행에 `[ACTION: ...]` 접두로 아이템 지급
  (2010007 x1)+퀘스트 시작+HP 25 설정을 표시(원본에 있던 "인벤토리 꽉 차면 실패" 가드는 CSV에 넣지 않고
  여기 기록만 함 — subway_get류와 같은 처리 방식).
- **q1021e.js (Roger's Apple, 종료)** → `Talk_1021_RogersApple_End.csv` (순수 선형, 2행). 마지막 행에
  `[ACTION: exp 10 지급, 아이템 2010000 x3 + 2010009 x3 지급, 퀘스트 완료 처리]` 표시.
- **q2127e.js — 스킵**: `//TODO: GMS-like conversation` 뿐, 대사도 부수효과도 없음.
- **q2186e.js (Help Me Find My Glasses, Quest 2186, 종료) — CSV 없음, 로그만**: 원본 자체가
  `//TODO: GMS-like conversation` 뿐이라 대사 텍스트가 없음(ArgonMS 저장소에도 미작성 상태). 부수효과만
  존재: exp 1700 지급, 아이템 2030019 x10 지급, 퀘스트 완료. 사람이 실제 대사를 새로 써야 하는 항목으로 표시.
- **q4659e.js (Robo Upgrade!, Quest 4659, 종료)** → `Talk_4659_RoboUpgrade_End.csv` (1행, 아이템 부족
  시 안내문만 — subway_get1.js와 동일 패턴). 성공 시(아이템 4000111 50개 보유) 부수효과: 펫 진화
  (`player.evolveBossPet()`), 아이템 5380000 x1 및 4000111 x50 차감, 퀘스트 완료 — **대사 없이 진행**이라
  CSV에는 실패 메시지만 있고 성공 부수효과는 로그 기록만.
- **q8185e.js (Pet Evolution2, Quest 8185, 종료)**, **q8189e.js (Pet Re-Evolution, Quest 8189, 종료)** →
  각각 `Talk_8185_PetEvolution2_End.csv`, `Talk_8189_PetReEvolution_End.csv` (원문까지 완전히 동일한
  구조/메시지, 메소 10000 부족 시 안내문). 성공 시 부수효과: 펫 진화, 아이템 5380000 x1 차감, 메소 10000
  차감, 퀘스트 완료.
- **NPC 표시명 미확인 3건**: q4659e/q8185e/q8189e 전부 NPC 9102001인데, 이 저장소 내에서 실제 이름을
  찾지 못해(다른 스크립트에서도 이 ID로 이름이 등장하지 않음) `NPC 9102001`을 임시 표시명으로 사용 —
  **실제 이름 확인 후 교체 필요**.

**새로 확인된 미해결 시스템(퀘스트 변환 중 발견, msw_lua_notes.md에도 기록)**:
- **경험치/레벨 시스템**(`player.gainExp`) — MSW 대응 API 미확인.
- **메소(화폐) 시스템**(`player.hasMesos`/`loseMesos`) — 아이템과 별개 화폐 개념이 MSW에 있는지 미확인
  (재화 시스템 자체가 없다면 인벤토리 아이템처럼 취급해 자체 구현 필요할 수 있음).
- **펫 진화 시스템**(`player.evolveBossPet`) — 메이플스토리 전용 기능이라 MSW에 대응 개념 자체가 없을
  가능성 높음 — 있다면 완전히 커스텀으로 구현해야 함.
