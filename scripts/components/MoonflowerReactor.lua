--[[
MoonflowerReactor — ArgonMS의 moonflower.js(Reactor 9108000~9108005, 헤네시스 파티퀘스트 "달맞이꽃") 대응.
6개의 리액터(꽃) 각각에 이 스크립트를 부착. 올바른 색의 씨앗이 뿌려져 맞았을 때(원본은 reactor가
활성화될 조건 자체는 엔진이 판정) 공유 카운터를 1 증가시키고, 6이 되면 달토끼 몬스터를 스폰함.

검증 출처:
  - HitComponent/HitEvent: API Reference 확인.
  - _RoomService:GetSharedMemory(name) -> (errorCode, RoomSharedMemory): API Reference 확인.
    ArgonMS의 reactor.getEvent("moonrabbit")(파티퀘스트 공유 이벤트 객체)에 대응.
  - RoomSharedMemory:GetVariableAndWait(name)/SetVariableAndWait(name, value): API Reference 확인.
  - _SpawnService:SpawnByModelId(modelId, name, position, parent): API Reference 확인
    (map.spawnMob(9300061, x, y, true) 대응).
  - **미검증**: SharedVariableResult 객체에서 실제 값을 어떻게 꺼내는지(어떤 필드명인지) 정확한 구조를
    못 봤음 — 아래 `result.Value`는 추정. GetVariableAndWait가 변수가 아직 없을 때 어떻게 동작하는지도
    미확인(에러 코드로 판별 예상). MSW 에디터에서 반드시 재확인 필요.
  - 몬스터 스폰 좌표(x=-180,y=-196)는 ArgonMS 원본 좌표 그대로 옮겼으나, MSW 맵은 새로 제작하는 것이라
    실제 좌표는 그 맵 레이아웃에 맞게 다시 잡아야 함.
--]]

Property: string sharedMemoryName = "moonrabbit"
Property: string monsterModelId = "" -- MSW 쪽 달토끼 몬스터 모델 ID로 채워야 함

void HandleHitEvent(HitEvent event) {
  if self:IsClient() then return end

  local errorCode, memory = _RoomService:GetSharedMemory(self.sharedMemoryName)
  if errorCode ~= 0 or memory == nil then return end

  -- TODO(미검증): 변수가 없을 때 GetVariableAndWait 반환값 형태 확인 필요. 우선 실패 시 0으로 간주.
  local getResult = memory:GetVariableAndWait("flowers")
  local currentCount = 0
  if getResult ~= nil and getResult.Value ~= nil then
    currentCount = tonumber(getResult.Value) or 0
  end

  local newCount = currentCount + 1
  memory:SetVariableAndWait("flowers", tostring(newCount))

  if newCount == 6 then
    local mapEntity = self.Entity.CurrentMap
    -- TODO(미검증): Vector3 생성자, 실제 스폰 좌표는 MSW 맵 레이아웃에 맞게 재설정 필요.
    _SpawnService:SpawnByModelId(self.monsterModelId, "MoonBunny", Vector3(-180, -196, 0), mapEntity)
  end
}
