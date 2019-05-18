
-- Luciole
-- Joueur d'échecs artificiel
-- Interface UCI pour le joueur d'échecs artificiel

require('chess960')

local LPos = EncodePosition()

function OnNewGame()
  LPos = EncodePosition()
end

function OnStartPos()
  LPos = EncodePosition()
end

function OnFen(AFen)
  LPos = EncodePosition(AFen)
end

function OnMove(AMove)
  DoMove(LPos, StrToMove(AMove))
end

function OnGo(AWTime, ABTime, AMovesToGo)
  local LTime = os.clock()
  local LMove = BestMove(LPos)
  local LTime = os.clock() - LTime
  LLog.debug(string.format("Temps écoulé : %.2f s", LTime))
  io.write(string.format("bestmove %s\n", LMove))
  io.flush()
end

function OnSetOption(AValue)
  LLog.debug("UCI_Chess960", AValue)
end

local LValue = ""

while true do
  local LInput = io.read()
  LLog.debug(">> " .. LInput)
  
  if LInput == "uci" then
    io.write(string.format("id name %s\nid author %s\noption name UCI_Chess960 type check default false\nuciok\n", "Luciole 0.0.2", "R. Chastain"))
    io.flush()
  end
  if LInput == "isready" then
    io.write(string.format("readyok\n"))
    io.flush()
  end
  LValue = string.match(LInput, "setoption name UCI_Chess960 value (%w+)")
  if LValue then
    OnSetOption(LValue == "true")
  end
  if LInput == "ucinewgame" then
    OnNewGame()
  end
  if LInput == "quit" then
    break
  end
  if LInput == "show" then
    io.write(BoardToText(LPos.piecePlacement) .. '\n')
    io.flush()
  end
  if string.sub(LInput, 1, 8) == "position" then
    if string.sub(LInput, 10, 17) == "startpos" then
      OnStartPos()
    elseif string.sub(LInput, 10, 12) == "fen" then
      local LFEN = string.match(LInput, "%w+/%w+/%w+/%w+/%w+/%w+/%w+/%w+ [wb] [%w-]+ [%w-]+ %d+ %d+")
      if LFEN ~= nil then
        OnFen(LFEN)
      end
    end
    if string.find(LInput, "moves") then
      for LMove in string.gmatch(LInput, "[%w][%d][%w][%d][%w]?") do
        OnMove(LMove)
      end
    end
  end
  if string.sub(LInput, 1, 2) == "go" then
    local LWTime, LBTime, LMovesToGo = string.match(LInput, "go wtime (%d+) btime (%d+) movestogo (%d+)")
    if LWTime == nil then
      OnGo(0, 0, 0)
    else
      OnGo(LWTime, LBTime, LMovesToGo)
    end
  end
end
