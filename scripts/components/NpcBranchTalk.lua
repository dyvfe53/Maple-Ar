--[[
NpcBranchTalk — 선택지 분기가 있는 NPC 대화 컴포넌트.
NpcLinearTalk.lua(선형 전용)의 상위 호환. 분기 없는 대사도 그대로 처리 가능하지만,
분기가 없다면 더 단순한 NpcLinearTalk.lua를 쓰는 쪽이 낫다 (이 스크립트는 OptionsPanel UI가
추가로 필요해서 구성이 더 무거움).

검증 출처:
  - 대사 표시 로직 본체: MSW 공식 튜토리얼 "NPC 대화창 만들기"(postId=74)와 동일한 GetCell/count 패턴.
  - 상호작용 트리거: InteractionComponent API Reference의 InteractionEvent 예제.
  - 선택지 버튼 클릭: ButtonComponent API Reference의 ButtonClickEvent 예제.
  - _DataService: GetCell(row, col)/GetRowCount()가 "행 번호로만" 접근 가능하다는 것을 API Reference로 확인.
    → 별도 id 컬럼/검색 없이 "행 번호 = id"로 취급, count 프로퍼티에 임의의 행 번호를 대입해 점프.
  - **이 스크립트 자체의 조합은 미검증** — 두 데이터 테이블(Talk/Choice)과의 실제 연동은
    MSW 에디터에서 아직 실행해본 적 없음. docs/msw_lua_notes.md 참고.

데이터 테이블 스키마:
  Talk_<npcId>_<name>:   name, portrait, text, isChoice, nextRow
  Choice_<npcId>_<name>: fromRow, optionIndex, label, targetRow

사용 방법 (MSW 에디터에서, 미실행/미검증):
  1. NPC 엔티티에 이 스크립트 + InteractionComponent 추가.
  2. talkTableName / choiceTableName 프로퍼티에 이 NPC의 테이블 이름 지정.
  3. /ui/UIGroup/TalkPanel(공용, NpcLinearTalk과 동일)에 더해
     /ui/UIGroup/OptionsPanel 하위에 고정 슬롯 버튼 6개(Option1..Option6, 각각 ButtonComponent +
     자식 TextComponent)를 미리 만들어둬야 함. 평소 Enable=false.
--]]

Property: string talkTableName = ""
Property: string choiceTableName = ""

Property: any talkData = nil
Property: any choiceData = nil
Property: number count = 0
Property: Entity uiNameEntity = nil
Property: Entity uiMessageEntity = nil
Property: Entity uiTalkPanel = nil
Property: Entity uiPortraitEntity = nil
Property: Entity uiOptionsPanel = nil

-- OptionsPanel 하위 고정 버튼 슬롯 (최대 6개 — 6개 넘는 선택지는 별도 설계 필요, notes 참고)
Property: Entity optionButton1 = nil
Property: Entity optionButton2 = nil
Property: Entity optionButton3 = nil
Property: Entity optionButton4 = nil
Property: Entity optionButton5 = nil
Property: Entity optionButton6 = nil

[Client only] void OnBeginPlay() {
  self.count = 1
  self.talkData = _DataService:GetTable(self.talkTableName)
  self.choiceData = _DataService:GetTable(self.choiceTableName)
  self.uiNameEntity = _EntityService:GetEntityByPath("/ui/UIGroup/TalkPanel/Name")
  self.uiMessageEntity = _EntityService:GetEntityByPath("/ui/UIGroup/TalkPanel/Text")
  self.uiTalkPanel = _EntityService:GetEntityByPath("/ui/UIGroup/TalkPanel")
  self.uiPortraitEntity = _EntityService:GetEntityByPath("/ui/UIGroup/TalkPanel/Portrait")
  self.uiOptionsPanel = _EntityService:GetEntityByPath("/ui/UIGroup/OptionsPanel")
  self.optionButton1 = _EntityService:GetEntityByPath("/ui/UIGroup/OptionsPanel/Option1")
  self.optionButton2 = _EntityService:GetEntityByPath("/ui/UIGroup/OptionsPanel/Option2")
  self.optionButton3 = _EntityService:GetEntityByPath("/ui/UIGroup/OptionsPanel/Option3")
  self.optionButton4 = _EntityService:GetEntityByPath("/ui/UIGroup/OptionsPanel/Option4")
  self.optionButton5 = _EntityService:GetEntityByPath("/ui/UIGroup/OptionsPanel/Option5")
  self.optionButton6 = _EntityService:GetEntityByPath("/ui/UIGroup/OptionsPanel/Option6")
}

void HandleInteractionEvent(InteractionEvent event) {
  if self:IsServer() then return end
  self:ShowLine()
}

void ShowLine() {
  local isNameEnable = false
  local isPortraitEnable = false
  local message = self.talkData:GetCell(self.count, "text")
  if message == nil then
    self.uiTalkPanel.Enable = false
    self.uiOptionsPanel.Enable = false
    self.count = 1 -- 다음 상호작용 시 처음부터 (NpcLinearTalk와 동일한 이유로 추가한 로직)
    return
  end

  self.uiTalkPanel.Enable = true
  self.uiMessageEntity.TextComponent.Text = message

  local name = self.talkData:GetCell(self.count, "name")
  local portrait = self.talkData:GetCell(self.count, "portrait")
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

  local isChoice = self.talkData:GetCell(self.count, "isChoice")
  if isChoice == "true" or isChoice == true then
    self:ShowOptions()
  else
    self.uiOptionsPanel.Enable = false
    -- 다음 상호작용 시 nextRow로 이동하도록 count를 미리 바꿔둠
    -- (튜토리얼처럼 무조건 +1이 아니라, 데이터가 지정한 행으로 이동)
    local nextRow = self.talkData:GetCell(self.count, "nextRow")
    if nextRow ~= nil and nextRow ~= "" then
      self.count = tonumber(nextRow)
    else
      self.count = 0 -- 다음 GetCell(0,...)은 존재하지 않는 행 -> 다음 상호작용 시 대화 종료로 처리됨
    end
  end
}

void ShowOptions() {
  self.uiOptionsPanel.Enable = true
  local buttons = {self.optionButton1, self.optionButton2, self.optionButton3,
                    self.optionButton4, self.optionButton5, self.optionButton6}
  for i = 1, 6 do
    buttons[i].Enable = false
  end

  local slot = 1
  local rowCount = self.choiceData:GetRowCount()
  for i = 1, rowCount do
    local fromRow = tonumber(self.choiceData:GetCell(i, "fromRow"))
    if fromRow == self.count then
      local btn = buttons[slot]
      if btn ~= nil then
        btn.Enable = true
        btn.TextComponent.Text = self.choiceData:GetCell(i, "label")
        -- targetRow를 버튼 쪽 NpcOptionButton.lua 스크립트의 프로퍼티에 채워 넣음.
        -- (entity.컴포넌트명으로 다른 엔티티의 스크립트 컴포넌트 프로퍼티에 쓰는 것 —
        --  "엔티티와 컴포넌트 참조" 문서의 접근 패턴 응용, 이 정확한 조합은 미검증)
        btn.NpcOptionButton.targetRow = self.choiceData:GetCell(i, "targetRow")
        slot = slot + 1
      end
    end
  end
}

-- optionButton1~6에 부착된 NpcOptionButton.lua가 클릭 시 호출하는 콜백.
-- (NpcOptionButton.lua 참고: self.npcEntity.NpcBranchTalk:OnOptionChosen(...) 형태로 호출됨)
void OnOptionChosen(string targetRowStr) {
  if targetRowStr ~= nil and targetRowStr ~= "" then
    self.count = tonumber(targetRowStr)
  else
    self.count = 0
  end
  self.uiOptionsPanel.Enable = false
  self:ShowLine()
}
