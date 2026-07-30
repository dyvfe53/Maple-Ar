--[[
FreeMarketEntrance — ArgonMS의 market01.js~market17.js(16개, 자유시장 "입구" 포탈) 대응.
원본 16개 스크립트는 전부 본문이 동일함(portal.rememberMap("FREE_MARKET") + 고정 목적지로 워프) —
배치된 맵만 다르고 로직은 하나. MSW에서는:
  1. 실제 워프(마을 -> 자유시장)는 PortalComponent의 PortalEntityRef로 디자인타임에 직접 연결
     (스크립트 불필요 — enter_nautil.js와 동일한 케이스).
  2. 이 스크립트는 "돌아올 위치 기억"만 담당 — PortalUseEvent 시점에 플레이어의 현재 맵/좌표를
     UserDataStorage에 저장. 자유시장 입구 포탈 16개 전부에 동일하게 부착.

검증 출처:
  - PortalComponent.PortalUseEvent, event.PortalUser: API Reference 확인.
  - PlayerComponent.UserId: API Reference 확인.
  - Entity.CurrentMap, Entity.CurrentMap.Name: "엔티티와 컴포넌트 참조" 문서 확인.
  - _DataStorageService:GetUserDataStorage(userId):SetAndWait(key, value): API Reference 확인
    (SetAndWait(string key, string value) -> int32 에러코드).
  - **미검증**: TransformComponent.Position의 실제 타입/필드명(x/y vs X/Y), Vector3 생성자 시그니처.
    좌표 직렬화 부분은 MSW 에디터에서 반드시 재확인 필요.

원본 ArgonMS는 맵ID(정수)로 위치를 식별하지만, MSW는 자체 제작 맵이라 맵 이름(문자열)로 식별함 —
그래서 "돌아올 위치"도 ArgonMS 맵ID가 아니라 MSW 맵 이름 기준으로 저장함.
--]]

Event Handler: [server only] [self] HandlePortalUseEvent(PortalUseEvent event) {
  local player = event.PortalUser
  if player == nil then return end
  local playerComp = player.PlayerComponent
  if playerComp == nil then return end

  local userId = playerComp.UserId
  local mapName = ""
  if player.CurrentMap ~= nil then
    mapName = player.CurrentMap.Name
  end

  -- TODO(미검증): TransformComponent 필드명이 다르면 아래 두 줄만 고치면 됨.
  local pos = player.TransformComponent.Position
  local value = mapName .. "|" .. tostring(pos.x) .. "|" .. tostring(pos.y)

  local storage = _DataStorageService:GetUserDataStorage(userId)
  storage:SetAndWait("FreeMarketReturn", value)
}
