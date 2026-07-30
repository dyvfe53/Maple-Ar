--[[
NpcLinearTalk — 재사용 가능한 "선형 대사 진행" NPC 대화 컴포넌트.

검증 출처:
  - 대사 진행 로직(OnBeginPlay/ShowNextText 본체): MSW 공식 튜토리얼
    "NPC 대화창 만들기" (postId=74) 원문 그대로. 유일한 차이는 데이터 테이블 이름을
    하드코딩된 "NPCTalk" 대신 Property(talkTableName)로 받아 NPC마다 재사용 가능하게 한 것.
  - 상호작용 트리거(HandleInteractionEvent): MSW 공식 API Reference "InteractionComponent"
    예제의 이벤트 핸들러 문법을 그대로 사용. 원본 튜토리얼은 전역 KeyDownEvent였으나,
    NPC별로 정확히 동작하려면 이 엔티티에 부착된 InteractionComponent의 InteractionEvent를
    쓰는 것이 맞다고 판단해 교체함 (두 공식 문서를 그대로 결합 — docs/msw_lua_notes.md 참고).
  - count 재시작(대사가 끝나면 count=1로 되돌리는 부분)은 재상호작용 시 처음부터 다시
    보여주기 위해 추가한 부분으로, 원본 튜토리얼에는 없음(원본은 1회성 데모라 불필요했음).
    → MSW 에디터에서 실제로 재상호작용했을 때 의도대로 동작하는지 확인 필요.

사용 방법 (MSW 에디터에서, 아직 미실행/미검증):
  1. NPC 엔티티에 이 스크립트 컴포넌트를 추가.
  2. 같은 NPC 엔티티에 InteractionComponent를 추가하고 ActionKey/ActionName/콜라이더 범위 설정.
  3. talkTableName 프로퍼티에 이 NPC의 데이터 테이블 이름을 지정 (예: "Talk_2001000_Cliff").
  4. /ui/UIGroup/TalkPanel(+Name/Text/Portrait 자식)이 미리 한 번만 만들어져 있어야 함
     (공식 튜토리얼과 동일한 공용 UI를 모든 NPC가 공유).

전제: /ui/UIGroup/TalkPanel UI가 튜토리얼(postId=74)대로 이미 구성되어 있어야 동작.
--]]

Property: string talkTableName = ""

Property: any npcTalkData = nil
Property: number count = 0
Property: Entity uiNameEntity = nil
Property: Entity uiMessageEntity = nil
Property: Entity uiTalkPanel = nil
Property: Entity uiPortraitEntity = nil

[Client only] void OnBeginPlay() {
  self.count = 1
  self.npcTalkData = _DataService:GetTable(self.talkTableName)
  self.uiNameEntity = _EntityService:GetEntityByPath("/ui/UIGroup/TalkPanel/Name")
  self.uiMessageEntity = _EntityService:GetEntityByPath("/ui/UIGroup/TalkPanel/Text")
  self.uiTalkPanel = _EntityService:GetEntityByPath("/ui/UIGroup/TalkPanel")
  self.uiPortraitEntity = _EntityService:GetEntityByPath("/ui/UIGroup/TalkPanel/Portrait")
}

-- Event Handler: [client only] [self] HandleInteractionEvent(InteractionEvent event)
-- (같은 엔티티의 InteractionComponent가 발생시키는 이벤트. 서버에서는 무시.)
void HandleInteractionEvent(InteractionEvent event) {
  if self:IsServer() then return end
  self:ShowNextText()
}

void ShowNextText() {
  local isNameEnable = false
  local isPortraitEnable = false
  local message = self.npcTalkData:GetCell(self.count, "text")
  if message == nil then
    self.uiTalkPanel.Enable = false
    self.count = 1 -- 다음 상호작용 시 처음부터 다시 보여주기 위한 리셋 (원본 튜토리얼엔 없던 추가 로직)
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
