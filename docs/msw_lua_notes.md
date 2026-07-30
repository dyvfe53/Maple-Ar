# MSW Lua/스크립팅 확인된 사실 (공식 문서 기준, 2026-07-30 확인)

출처: https://maplestoryworlds-creators.nexon.com/ko (Docs, API Reference)

## 문법 구조

- 순수 Lua가 아니라 **타입 어노테이션이 붙은 확장 문법**을 씀. 함수는 아래 형태로 선언:
  ```
  Method: [server only] void OnBeginPlay() {
    log(self.testP)
  }
  ```
  `{ }` 블록, `[server only]` / `[client only]` 접두, `void`/`integer`/`string` 등 반환 타입 명시가 실제 Lua 문법을 감싼 확장 표기.
- `Property : [Sync] integer testP = 0` 형태로 컴포넌트 프로퍼티(=전역변수 대체) 선언. **전역 변수 사용은 권장 안 함.**
- 콘솔 출력은 `print()`가 아니라 `log()`.
- 그 외 변수/테이블/연산자는 표준 Lua 5.x와 동일 (배열 인덱스 1부터 시작, `#`=길이, `..`=문자열 결합, `and/or/not`).
- 메서드 호출은 `entity:Method()` (콜론), 프로퍼티 접근은 `entity.Property` (점).

## 엔티티/컴포넌트 모델 (Roblox의 Instance/Script와 유사)

- 모든 게임 객체 = **Entity**(계층 구조, Parent/Children) + 그 위에 붙는 **Component**들(네이티브 or 스크립트 컴포넌트).
- `self.Entity` — 이 스크립트가 붙은 엔티티.
- `Entity.Parent`, `Entity.Children`(테이블), `Entity:GetChildByName(name, recursive?)`.
- `Entity.CurrentMap`, `Entity.CurrentWorld` — 유일 엔티티(맵/월드) 참조.
- `_EntityService:GetEntityByPath("/maps/map01/...")`, `GetEntitiesByPath(...)`, `GetEntity(id)` — 경로/ID로 전역 조회.
- `_UserService.UserEntities`(접속 유저 전체 dict), `_UserService.LocalPlayer`(클라이언트 전용, 서버에서는 nil), `_UserService:GetUserEntityByUserID(id)`.
- 컴포넌트 접근: `entity.ComponentName` (네이티브: `RigidbodyComponent` 등, 커스텀 스크립트 컴포넌트도 생성 시 이름으로 동일하게 접근).
- `Entity:GetChildComponentsByTypeName(typename, recursive?)` → 배열, `Entity:GetFirstChildComponentByTypeName(typename, recursive?)` → 단일.
- 이벤트 핸들러 패턴: `Entity Event Handler: service UserService HandleUserEnterEventType(UserEnterEventType event) { local UserId = event.UserId ... }`.

## 서버/클라이언트 분리

- 함수 앞에 `[server only]` / `[client only]` 어노테이션으로 실행 위치 구분 (ArgonMS의 game/login 서버 분리와는 다른 개념 — MSW는 한 프로젝트 안에서 서버·클라이언트 코드가 같이 있고 어노테이션으로만 나뉨).

## NPC 대화창 — 공식 튜토리얼 확인 (postId=74 "NPC 대화창 만들기")

MSW에는 ArgonMS의 `NpcScriptManager`(continuation) 같은 **전용 대화 시스템이 내장되어 있지 않음**.
대신 크리에이터가 직접 "UI + 데이터 테이블 + 스크립트"로 구성하는 것이 공식 권장 패턴:

1. **UI**: `UIGroup` 하위에 `TalkPanel`(배경 이미지) → 그 자식으로 `Portrait`(초상화 이미지), `Name`(이름 텍스트), `Text`(대사 텍스트) 엔티티 배치. 평소엔 `TalkPanel.Enable = false`.
2. **데이터 테이블**: `_DataService` 자산으로 `NPCTalk`이라는 테이블 생성, 컬럼 `name / portrait / text`. 대사를 행(row) 단위로 순서대로 나열 (portrait는 이미지 리소스 RUID 문자열).
3. **스크립트**: 컴포넌트 프로퍼티로 `count`(현재 읽는 행 번호), `npcTalkData`(테이블 참조), UI 엔티티 참조들을 보관.

검증된 실제 코드 (원문 그대로):
```
[Client only] void OnBeginPlay() {
  self.count = 1
  self.npcTalkData = _DataService:GetTable("NPCTalk")
  self.uiNameEntity = _EntityService:GetEntityByPath("/ui/UIGroup/TalkPanel/Name")
  self.uiMessageEntity = _EntityService:GetEntityByPath("/ui/UIGroup/TalkPanel/Text")
  self.uiTalkPanel = _EntityService:GetEntityByPath("/ui/UIGroup/TalkPanel")
  self.uiPortraitEntity = _EntityService:GetEntityByPath("/ui/UIGroup/TalkPanel/Portrait")
}

-- Entity Event Handler: KeyDownEvent
local key = event.key
if key == KeyboardKey.Z then
  self:ShowNextText()
end

void ShowNextText() {
  local isNameEnable = false
  local isPortraitEnable = false
  local message = self.npcTalkData:GetCell(self.count, "text")
  if message == nil then
    self.uiTalkPanel.Enable = false
    return
  else
    self.uiTalkPanel.Enable = true
    self.uiMessageEntity.TextComponent.Text = message
  end
  local name = self.npcTalkData:GetCell(self.count, "name")
  local portrait = self.npcTalkData:GetCell(self.count, "portrait")
  if name ~= "" then
    isNameEnable = true
    self.uiNameEntity.TextComponent.Text = name
  end
  if portrait ~= "" then
    isPortraitEnable = true
    self.uiPortraitEntity.SpriteGUIRendererComponent.ImageRUID = portrait
  end
  self.uiNameEntity.Enable = isNameEnable
  self.uiPortraitEntity.Enable = isPortraitEnable
  self.count = self.count + 1
}
```

**중요한 제약**: 이 공식 예제는 **선형(linear) 대사 진행**만 다룸 (키 입력마다 다음 줄로). ArgonMS NPC 스크립트들은
`npc.askMenu()`/`askYesNo()`처럼 **분기형 대화**(선택지에 따라 다른 대사/퀘스트/상점으로 진행)가 많음 —
이건 이 튜토리얼에 없는 내용이라, 선택지 UI(버튼 여러 개) + 분기 로직을 직접 얹어서 확장해야 함.
NPC 스크립트를 변환할 때 "선형 대사"와 "분기(메뉴 선택)"를 구분해서, 분기가 있는 스크립트는 별도 설계가 필요하다는 걸 미리 인지하고 진행.

## 상호작용 — InteractionComponent (API Reference 확인, NPC 대화 트리거로 확정)

정확히 "플레이어가 NPC에게 다가가 상호작용"하는 용도의 **내장 컴포넌트**가 있음. `TriggerComponent`(범용 충돌 감지)보다
이쪽이 NPC 상호작용의 정답.

- **Properties**: `ActionKey`(KeyboardKey, 상호작용 키), `ActionName`(string, 말풍선에 뜨는 문구 예: "대화하기"),
  `ShowActionInfo`(bool, true면 플레이어가 접근했을 때 ActionName+ActionKey를 말풍선으로 자동 표시 — 이때 `ChatBalloonComponent`가
  플레이 중 자동으로 붙음), `InteractionType`(Enum `InteractType`, 키 입력 방식 — 탭/누르고 있기 등), `HoldingDuration`(초 단위,
  누르고 있어야 하는 시간, `KeyHoldingDuration`/`KeyUpAfterHoldingDuration` 타입일 때), Box/Circle/Polygon 콜라이더 설정(범위).
- **Events**: `InteractionEnterEvent`(범위 진입), `InteractionEvent`(**실제 상호작용 키를 눌렀을 때 발생 — 이게 "대화 시작" 트리거**),
  `InteractionLeaveEvent`(범위 이탈). (`OnEnter/OnInteraction/OnLeave` 메서드 오버라이드 방식은 deprecated, 이벤트 방식 사용 권장)
- 공식 예제(원문 그대로, 상호작용 시 플레이어 이동속도 변경):
  ```
  Event Handler: [self] HandleInteractionEnterEvent(InteractionEnterEvent event) {
    local InteractionEntity = event.InteractionEntity
    if self:IsClient() then return end
    local effectRoot = _EntityService:GetEntityByPath(EntityPath)
    effectRoot.Enable = true
  }
  [self] HandleInteractionLeaveEvent(InteractionLeaveEvent event) {
    local InteractionEntity = event.InteractionEntity
    if self:IsClient() then return end
    local effectRoot = _EntityService:GetEntityByPath(EntityPath)
    effectRoot.Enable = false
  }
  [self] HandleInteractionEvent(InteractionEvent event) {
    local InteractionEntity = event.InteractionEntity
    if self:IsServer() then return end
    InteractionEntity.MovementComponent.InputSpeed = 3
  }
  ```
  `event.InteractionEntity` = 상호작용을 건 플레이어 엔티티. `Event Handler:` 선언에 `[self]`만 있고 `[server only]`/`[client only]`가
  없는 경우, 핸들러 내부에서 `self:IsClient()`/`self:IsServer()`로 직접 분기하는 것도 확인됨 (두 방식 다 가능한 것으로 보임).

**NPC 대화 트리거 확정 설계**: NPC 엔티티에 `InteractionComponent` 부착 (`ActionKey`=Z, `ActionName`="대화하기", `ShowActionInfo`=true)
→ `InteractionEvent` 핸들러에서 클라이언트 쪽에 한해 `self:ShowNextText()` 호출. NPCTalk 튜토리얼(postId=74)의 전역 `KeyDownEvent`
방식보다 이쪽이 NPC별로 정확히 동작하는 올바른 방식이며, 두 공식 문서(NPCTalk 튜토리얼 + InteractionComponent 레퍼런스)를
그대로 결합한 것이라 신뢰도 높음.

## 분기형 대화(선택지 메뉴) — 직접 설계 (공식 예제 없음, ButtonComponent 검증 조각으로 조립)

ArgonMS의 202개 NPC 중 119개가 `askMenu()`/`askYesNo()`(선택지 분기)를 씀 — 다수파. 공식 튜토리얼은 선형 진행만
다루므로, 검증된 `ButtonComponent`(Properties/Events)를 이용해 직접 설계함. **이 섹션 전체는 미검증 설계**이며,
개별 조각(ButtonClickEvent 문법, DataService:GetTable/GetCell)만 검증됨.

- `ButtonComponent`의 `ButtonClickEvent` 확인된 문법:
  ```
  Event Handler: [self] HandleButtonClickEvent(ButtonClickEvent event) {
    local Entity = event.Entity
    ...
  }
  ```
- **`_DataService`/데이터 테이블 API 정확한 사실 확인** (postId 없음, API Reference `Services/DataService` 직접 확인):
  `GetCell(name, row, col)` / `dataSet:GetCell(row, col)`, `GetRowCount(name)` / `dataSet:GetRowCount()`, `GetTable(name)`
  뿐이며, **"컬럼 값으로 행을 검색"하는 내장 함수는 없음** — row는 항상 1부터 시작하는 정수 위치로만 접근 가능.
  → 애초에 계획했던 "임의의 `id` 컬럼 값으로 검색" 설계는 불가능하거나 직접 순회(`for i=1,GetRowCount() do ... end`)가
  필요했는데, **더 간단한 방법이 있음**: 행 번호 자체를 id로 취급하면 됨. 즉 "3번 줄로 점프"는 그냥 `GetCell(3, ...)`.
  별도 `id` 컬럼도, 검색 로직도 필요 없음 — 아래 설계는 이 방식으로 단순화함.
- **데이터 모델**: 튜토리얼의 `count = count + 1`(항상 다음 줄)을 "`count`를 임의의 행 번호로 바꿔치기 가능"하게만
  확장. 컬럼 자체는 튜토리얼과 동일(`name, portrait, text`)에 `isChoice`만 추가:
  - `Talk_<npcId>_<name>` 테이블: 컬럼 `name, portrait, text, isChoice, nextRow` — `isChoice=true`면 다음 줄로
    자동 진행하지 않고 선택지를 띄움. `isChoice=false`면 상호작용 시 `nextRow`(행 번호, 빈 값=대화 종료)로 이동.
  - `Choice_<npcId>_<name>` 테이블: 컬럼 `fromRow, optionIndex, label, targetRow` — `fromRow` 행에서 보여줄
    선택지들. `targetRow`가 빈 값이면 그 선택 시 대화 종료.
- **스크립트 설계** (`NpcBranchTalk.lua`, 아직 미검증):
  - `count` 프로퍼티(튜토리얼과 동일한 이름/역할)로 현재 행 번호를 추적하되, 분기 시 임의의 행 번호를 대입 가능.
  - 행을 보여줄 때 `isChoice`가 true면: 공용 `OptionsPanel`(고정 슬롯 최대 N개, 예: 6개의 미리 만들어둔 버튼+텍스트
    엔티티) 활성화. `Choice` 테이블 전체를 `GetRowCount()`만큼 순회하며 `fromRow == count`인 행만 골라 각 버튼에
    `label`을 채움 (여기서만 순회가 필요 — Choice 테이블은 보통 작아서 성능 문제 없음).
  - 각 버튼의 `ButtonClickEvent` 핸들러에서: 그 옵션의 `targetRow`를 읽어 `count`에 대입하고 다시 표시(재귀 호출) —
    `targetRow`가 비어있으면 대화 종료(원본 `npc.say()`로 끝나는 것과 대응).
  - **한계**: 고정 슬롯 방식이라 선택지가 슬롯 수(예: 6개)를 넘는 NPC(예: `About_NLC.js`의 11개 선택지 FAQ 메뉴)는
    슬롯 수를 늘리거나 스크롤형 UI(`ScrollLayoutGroupComponent` 확인됨, 상세 미조사)로 별도 설계 필요.
  - **한계 2**: ArgonMS 분기 중 `player.getLevel()`, `player.startQuest()`, `player.isQuestCompleted()`처럼 플레이어
    상태/퀘스트를 참조하는 조건문은, MSW의 퀘스트/레벨 시스템이 아직 미확인이라 이 설계에 포함 안 됨 — 일단
    `action` 같은 확장 컬럼에 원본 조건을 텍스트로 남겨두고, 퀘스트 시스템 조사 후(Task) 재작업 예정.

## 제3의 카테고리 — 상태 조건부 분기 (플레이어 선택 아님, 서버 상태에 따른 배타적 대사)

선형 대사 82개를 일괄 변환하던 중(배치 5) 실제 사례를 검수하다가 발견: ArgonMS NPC 스크립트 중 상당수가
`askMenu`/`askYesNo`/`switch` 없이 그냥 `if (player.hasItem(...))`, `if (player.isQuestActive(...))`,
`if (party == null)` 같은 조건문으로 **여러 `npc.say()` 중 정확히 하나만** 보여준다. 이건 "플레이어가
고르는 메뉴"가 아니라 "서버가 상태를 보고 대신 골라주는" 분기라서, 처음 설계한 두 카테고리(선형 /
메뉴선택 분기) 어디에도 안 맞음 — 별도의 세 번째 카테고리로 다뤄야 함.

- 예: `s4snipe.js`는 파티 유무·인원수·레벨·직업 조합에 따라 7개 메시지 중 하나만 보여줌 (4중 중첩 `if`).
  `s4freeze_item.js`는 아이템 소지 여부로 3개 중 하나. `s4tornado.js`/`s4common1_out.js`는 아이템
  획득 성공/실패로 2개 중 하나.
- **처음에 실수함**: 배치 변환 지시를 "askMenu/askYesNo/switch가 없으면 선형으로 취급"이라고 내렸는데,
  이 `if/else` 조건부 케이스를 걸러내지 못해서 서브에이전트가 상호 배타적인 메시지들을 순서대로 이어붙인
  CSV를 만드는 오류가 발생함 (예: "인벤토리 꽉 참" 메시지와 "성공" 메시지가 항상 둘 다 뜨는 것처럼
  잘못 표현됨). 코디네이터가 원본 재확인 후 해당 CSV들을 삭제하고 이 카테고리로 재분류함
  (CONVERSION_LOG_batch5.md 참고). **앞으로 이 세 카테고리를 구분할 때 `if`/`switch` 자체의 유무가 아니라
  "그 조건문이 여러 `npc.say`/`sayNext` 중 어느 것을 보여줄지 가르는가"를 기준으로 판단해야 함.**
- **설계 방향(잠정)**: 메뉴 분기(`NpcBranchTalk.lua`)보다는 단순함 — 버튼 UI 자체가 필요 없고, 상호작용
  시점에 조건을 검사해서 어느 텍스트를 보여줄지 스크립트가 직접 고르면 됨. 다만 이 조건들(퀘스트 진행
  여부, 아이템 소지, 파티 상태)을 MSW에서 읽는 API가 전부 미확인 상태라 — 퀘스트/인벤토리/파티 시스템
  조사가 선행되어야 실제 설계가 가능함.

## 아직 미확인 (추가 조사 필요)

- `ScrollLayoutGroupComponent`(선택지 많은 메뉴에 필요할 수 있음) 상세.
- 퀘스트 시스템 내장 여부/컴포넌트명.
- 몬스터 스폰(`_SpawnService`로 추정), 전투/스탯 컴포넌트명.
- 인벤토리/아이템 시스템 컴포넌트명(`InventoryComponent` 존재 확인, 상세 미확인).

## ArgonMS ↔ MSW 개념 매핑 (잠정)

| ArgonMS | MSW |
|---|---|
| NPC 자바스크립트(Rhino, continuation), 선형 대사 | UI(TalkPanel/Name/Text/Portrait) + `_DataService` 데이터 테이블(name/portrait/text 컬럼) + `count` 프로퍼티로 행 진행 |
| NPC 자바스크립트, `askMenu()`/`askYesNo()` 분기 | `ButtonComponent`(ButtonClickEvent) + id 기반 `Talk_`/`Choice_` 데이터 테이블 2종 조합 (직접 설계, 미검증) |
| 서버 프로세스 분리(login/game/shop) | 없음 — MSW가 서버 인프라 전체를 대신 처리, `[server only]`/`[client only]`로만 구분 |
| MySQL 테이블(캐릭터/인벤토리 등) | `_DataService:GetTable()` / `GetCell()` 기반 데이터 테이블로 대체 가능 (정적 데이터에 한함) |
