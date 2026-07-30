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

## 아직 미확인 (추가 조사 필요)

- 분기형 대화(선택지 메뉴) 구현 패턴 — 공식 예제 없음, 직접 설계 필요.
- 퀘스트 시스템 내장 여부/컴포넌트명.
- 몬스터 스폰(`_SpawnService`로 추정), 전투/스탯 컴포넌트명.
- 인벤토리/아이템 시스템 컴포넌트명.

## ArgonMS ↔ MSW 개념 매핑 (잠정)

| ArgonMS | MSW |
|---|---|
| NPC 자바스크립트(Rhino, continuation), 선형 대사 | UI(TalkPanel/Name/Text/Portrait) + `_DataService` 데이터 테이블(name/portrait/text 컬럼) + `count` 프로퍼티로 행 진행 |
| NPC 자바스크립트, `askMenu()`/`askYesNo()` 분기 | 대응하는 공식 패턴 없음 — 선택지 버튼 UI + 분기 로직 직접 설계 필요 (아직 미해결) |
| 서버 프로세스 분리(login/game/shop) | 없음 — MSW가 서버 인프라 전체를 대신 처리, `[server only]`/`[client only]`로만 구분 |
| MySQL 테이블(캐릭터/인벤토리 등) | `_DataService:GetTable()` / `GetCell()` 기반 데이터 테이블로 대체 가능 (정적 데이터에 한함) |
