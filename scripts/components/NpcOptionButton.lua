--[[
NpcOptionButton — NpcBranchTalk.lua의 OptionsPanel 안에 있는 버튼(Option1~6) 각각에 부착하는
작은 연결용 스크립트. 이 버튼이 어떤 NPC 엔티티 소속인지(npcEntity), 클릭 시 어느 행으로
점프할지(targetRow, NpcBranchTalk가 매번 채워 넣음)를 들고 있다가 클릭 시 NPC 쪽에 통지한다.

검증 출처:
  - ButtonClickEvent 문법: ButtonComponent API Reference 예제 그대로.
  - entity.ComponentName으로 형제/타 엔티티의 스크립트 컴포넌트 인스턴스에 접근해 프로퍼티를
    읽고 메서드를 호출하는 것: "엔티티와 컴포넌트 참조"(postId=164) 문서의 "컴포넌트 접근" 절에서
    확인된 entity.컴포넌트명 접근 패턴의 응용. **다만 "다른 엔티티의 컴포넌트에 값을 쓴 뒤 그
    메서드를 호출하는" 이 정확한 조합의 공식 예제는 없음 — 합리적 추론, MSW 에디터에서 재검증 필요.**

사용 방법 (MSW 에디터에서, 미실행/미검증):
  1. OptionsPanel/Option1(~6) 각 버튼 엔티티에 이 스크립트 + ButtonComponent 추가.
  2. npcEntity 프로퍼티를 이 버튼이 속한 NPC 엔티티로 수동 지정(에디터에서 드래그 또는 경로 지정).
  3. targetRow는 코드가 아니라 NpcBranchTalk.ShowOptions()가 실행 중에 채워 넣음 — 초기값은 비워둠.
--]]

Property: Entity npcEntity = nil
Property: string targetRow = ""

void HandleButtonClickEvent(ButtonClickEvent event) {
  if self:IsServer() then return end
  if self.npcEntity == nil then return end
  self.npcEntity.NpcBranchTalk:OnOptionChosen(self.targetRow)
end
