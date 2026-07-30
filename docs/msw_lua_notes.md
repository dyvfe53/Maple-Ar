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

## 아직 미확인 (추가 조사 필요)

- NPC 상호작용/대화창 관련 전용 컴포넌트·이벤트 (ArgonMS의 `NpcScriptManager`/대화 continuation에 대응하는 것) — 계속 조사 예정.
- 퀘스트 시스템 내장 여부/컴포넌트명.
- 몬스터 스폰(`_SpawnService`로 추정), 전투/스탯 컴포넌트명.
- 인벤토리/아이템 시스템 컴포넌트명.

## ArgonMS ↔ MSW 개념 매핑 (잠정)

| ArgonMS | MSW |
|---|---|
| NPC 자바스크립트(Rhino, continuation) | NPC 엔티티 + 스크립트 컴포넌트, 이벤트 핸들러 기반 (continuation 없이 상태를 Property에 저장하는 방식으로 재설계 필요) |
| 서버 프로세스 분리(login/game/shop) | 없음 — MSW가 서버 인프라 전체를 대신 처리, `[server only]`/`[client only]`로만 구분 |
| MySQL 테이블(캐릭터/인벤토리 등) | MSW 자체 데이터 서비스(추가 조사 필요) 또는 Property/Sync로 대체 |
