--[[
SinglePlayerChallengeInstance — 1인용 시간제한 인스턴스 챌린지 공통 패턴.

ArgonMS scripts/events/ 11개 중 6개(change_job.js, cloneFight.js, ninjaAmbush.js, iceDemon.js,
kairinT.js, pigFarm.js)가 전부 동일한 뼈대를 공유함:
  입장 시 격리된 인스턴스(또는 공유 맵)로 이동 -> 시간제한 타이머 시작 -> 시간 초과 또는 유저가
  나가면/접속종료하면 정리(다른 맵으로 킥 + 인스턴스 파괴).
이 컴포넌트 하나로 6개를 표현할 수 있음(맵/시간/킥 목적지만 다름 — 개별 값은 각 인스턴스 시작 로직에서
프로퍼티로 채워 넣음).

검증 출처:
  - _RoomService:CreateInstanceRoom(key, mapNames, firstUserWaitSeconds)/GetOrCreateInstanceRoom(key):
    API Reference 확인. mapNames를 지정하면 그 맵들로만 룸 생성, 비우면 MapComponent.InstanceMap=true인
    맵들 사용.
  - _RoomService:MoveUserToInstanceRoom(key, userId, mapName)/MoveUserToStaticRoom(userId, mapName):
    API Reference 확인.
  - _TimerService: SetTimerOnce/SetTimerRepeat/ClearTimer 존재 확인(다른 컴포넌트 예제에서 이미 사용).

**미검증(이 패턴 전체가 아직 MSW 에디터에서 실행된 적 없음)**:
  - 유저의 접속종료/맵이탈을 정확히 어떤 이벤트로 감지하는지 (`UserDisconnectEvent`, `UserLeaveEvent`,
    `EntityMapChangedEvent` 등이 전체 이벤트 목록에 존재하는 건 확인했으나, 인스턴스 룸 맥락에서 이걸
    어디에 연결해야 하는지는 확인 못함 — 아래는 `RoomEndEvent`/`UserLeaveEvent`로 추정만 해둠).
  - 원본의 `map.showTimer(...)` (화면에 남은 시간 카운트다운 UI 표시)에 대응하는 MSW 기능 — 미확인,
    필요하면 직접 UI(TextComponent + 매 프레임 갱신)로 구현해야 할 수 있음.

원본 대비 이 컴포넌트가 못 담는 것: change_job.js/cloneFight.js는 `event.makeMap`으로 매번 새
인스턴스를 만들지만, iceDemon.js/pigFarm.js는 `event.getMap`으로 고정된 하나의 공유 맵을 재사용함
(동시에 두 명이 도전하면 서로 방해가 될 수 있는 원본의 알려진 한계 — 그대로 옮김). MSW의
`CreateInstanceRoom`은 유저마다 독립된 인스턴스를 만드는 게 자연스러워서, 오히려 원본의 "공유 맵"
케이스보다 "격리된 인스턴스" 케이스가 재현하기 쉬움 — 반대로 공유 맵 재현은 별도 설계 필요.
--]]

Property: string instanceKeyPrefix = "challenge_"
Property: string destinationMapName = ""
Property: number timeLimitSeconds = 300
Property: string kickBackMapName = ""

void StartChallenge(string userId) {
  local key = self.instanceKeyPrefix .. userId
  local room = _RoomService:GetOrCreateInstanceRoom(key)
  if room == nil then return end

  _RoomService:MoveUserToInstanceRoom(key, userId, self.destinationMapName)

  -- TODO(미검증): 룸 안에서 실행되는 스크립트에서 타이머를 걸어야 하는지, 이 스크립트에서 걸어도 되는지 확인 필요.
  _TimerService:SetTimerOnce(function()
    self:EndChallenge(userId, key)
  end, self.timeLimitSeconds)
}

void EndChallenge(string userId, string roomKey) {
  _RoomService:MoveUserToStaticRoom({userId}, self.kickBackMapName)
  -- TODO(미검증): 인스턴스 룸을 명시적으로 파괴하는 함수명 확인 필요 (RoomService API에 명시적
  -- DestroyInstanceRoom이 안 보였음 — 유저가 다 빠지면 자동 정리되는 것으로 추정).
}
