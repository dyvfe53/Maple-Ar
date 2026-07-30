--[[
FreeMarketExit — ArgonMS의 market00.js(자유시장 "출구" 포탈, 1개) 대응.
원본: portal.resetRememberedMap("FREE_MARKET")로 저장된 위치를 읽어 복귀, 없으면
Perion(맵 102000000)/spawnPoint 28로 대체.

MSW에서는 FreeMarketEntrance.lua가 UserDataStorage에 저장해 둔 "FreeMarketReturn" 값을 읽어
TeleportService로 그 위치에 직접 텔레포트. 목적지가 플레이어마다 달라서 PortalComponent의
정적 PortalEntityRef 연결(디자인타임 고정)로는 표현 불가 — 이 스크립트가 동적으로 처리.

검증 출처:
  - _DataStorageService:GetUserDataStorage(userId):GetAndWait(key) -> (int32 에러코드, string 값):
    API Reference 확인.
  - _TeleportService:TeleportToMapPosition(targetEntity, destinationPosition, destinationMapName):
    API Reference 확인 (Services/TeleportService).
  - **미검증**: Vector3(x, y, z) 생성자 문법, 이 함수가 "다른 맵으로" 순간이동까지 지원하는지
    (설명상 지원하는 것으로 보이나 실제 실행 예제는 못 봄) — MSW 에디터에서 재확인 필요.
--]]

Property: string defaultMapName = ""
Property: float defaultX = 0
Property: float defaultY = 0

Event Handler: [server only] [self] HandlePortalUseEvent(PortalUseEvent event) {
  local player = event.PortalUser
  if player == nil then return end
  local playerComp = player.PlayerComponent
  if playerComp == nil then return end

  local userId = playerComp.UserId
  local storage = _DataStorageService:GetUserDataStorage(userId)
  local errorCode, value = storage:GetAndWait("FreeMarketReturn")

  local mapName = self.defaultMapName
  local x = self.defaultX
  local y = self.defaultY

  if errorCode == 0 and value ~= nil and value ~= "" then
    local parts = {}
    for part in string.gmatch(value, "([^|]+)") do
      table.insert(parts, part)
    end
    if #parts == 3 then
      mapName = parts[1]
      x = tonumber(parts[2])
      y = tonumber(parts[3])
    end
  end

  -- TODO(미검증): Vector3 생성자 시그니처 확인 필요.
  _TeleportService:TeleportToMapPosition(player, Vector3(x, y, 0), mapName)
}
