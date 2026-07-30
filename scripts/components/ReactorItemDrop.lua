--[[
ReactorItemDrop — 재사용 가능한 "피격 시 아이템 드랍" 리액터 컴포넌트.
ArgonMS의 mBoxItem0.js(고정 확률 여러 종류 중 하나), moonItem0.js(확률적으로 아예 안 뜨기도 함) 대응.

검증 출처:
  - HitComponent/HitEvent: API Reference 확인 (엔티티가 공격을 받으면 HitEvent 발생, HP 개념은
    직접 Property로 관리하는 예제 확인).
  - _ItemService:CreateItem(itemType, name, inventory): 이전 조사(InventoryComponent 절)에서 확인.
  - **미검증**: 여기서는 "인벤토리에 바로 지급"으로 단순화함. 실제 메이플스토리의 "바닥에 아이템이
    떨어지고 걸어가서 주워야 하는" 연출은 재현 안 함 — MSW에 그런 "월드 드랍 아이템" 전용 시스템이
    있는지 조사 못 함(Task 미완료). 필요하면 이 부분만 나중에 교체.

데이터 테이블 스키마 (Drop_<reactorId>_<name>.csv): itemId, weight
  - weight는 상대 가중치(원본 ArgonMS의 dropItems 두 번째 인자와 동일한 의미로 사용).

사용 방법 (MSW 에디터에서, 미실행/미검증):
  1. 리액터 엔티티에 HitComponent + 이 스크립트 추가.
  2. dropTableName 프로퍼티에 이 리액터의 드랍 테이블 이름 지정.
  3. triggerChance(0~1)로 "아예 안 뜰 확률"을 표현 (moonItem0.js의 50% 케이스 — mBoxItem0.js처럼
     항상 뜨는 경우는 1로 설정).
--]]

Property: string dropTableName = ""
Property: number triggerChance = 1
Property: any dropTable = nil

[Server only] void OnBeginPlay() {
  self.dropTable = _DataService:GetTable(self.dropTableName)
}

void HandleHitEvent(HitEvent event) {
  if self:IsClient() then return end
  if math.random() > self.triggerChance then return end

  local totalWeight = 0
  local rowCount = self.dropTable:GetRowCount()
  for i = 1, rowCount do
    totalWeight = totalWeight + tonumber(self.dropTable:GetCell(i, "weight"))
  end

  local roll = math.random() * totalWeight
  local acc = 0
  for i = 1, rowCount do
    local w = tonumber(self.dropTable:GetCell(i, "weight"))
    acc = acc + w
    if roll <= acc then
      local itemId = self.dropTable:GetCell(i, "itemId")
      local attacker = event.AttackerEntity
      if attacker ~= nil and attacker.InventoryComponent ~= nil then
        -- TODO(미검증): itemId(ArgonMS 숫자 ID)를 MSW의 실제 itemType 자산으로 매핑하는 방법 확인 필요.
        _ItemService:CreateItem(itemId, itemId, attacker.InventoryComponent)
      end
      break
    end
  end
}
