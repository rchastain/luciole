
-- Luciole
-- Joueur d'échecs artificiel
-- Interface UCI pour le joueur d'échecs artificiel

require('chess')

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
  LTime = os.clock() - LTime
  GLog.debug(string.format("Temps écoulé : %.2f s", LTime))
  io.write(string.format("bestmove %s\n", LMove))
  io.flush()
end

function OnSetOption(AValue)
  GLog.debug(AValue)
end

local LValue, LIndex = "", 0

while true do
  local LInput = io.read()
  GLog.debug(">> " .. LInput)
  LValue = string.match(LInput, "setoption name UCI_Chess960 value (%w+)")
  if LValue then
    OnSetOption(LValue == "true")
  elseif LInput == "uci" then
    io.write(string.format("id name %s\nid author %s\noption name UCI_Chess960 type check default false\nuciok\n", "Luciole 0.0.3", "Roland Chastain"))
    io.flush()
  elseif LInput == "isready" then
    io.write(string.format("readyok\n"))
    io.flush()
  elseif LInput == "ucinewgame" then
    OnNewGame()
  elseif LInput == "quit" then
    break
  elseif LInput == "show" then
    io.write(BoardToText(LPos.piecePlacement) .. '\n')
    io.write(DecodePosition(LPos) .. '\n')
    io.flush()
  elseif string.sub(LInput, 1, 8) == "position" then
    if string.sub(LInput, 10, 17) == "startpos" then
      OnStartPos()
    elseif string.sub(LInput, 10, 12) == "fen" then
      local LFEN = string.match(LInput, "%w+/%w+/%w+/%w+/%w+/%w+/%w+/%w+ [wb] [%w-]+ [%w-]+ %d+ %d+")
      if LFEN ~= nil then
        OnFen(LFEN)
      end
    end
    LIndex = string.find(LInput, "moves")
    if LIndex then
      LInput =  string.sub(LInput, LIndex)
      GLog.debug(LInput)
      for LMove in string.gmatch(LInput, "[%w][%d][%w][%d][%w]?") do
        OnMove(LMove)
      end
    end
  elseif string.sub(LInput, 1, 2) == "go" then
    local LWTime, LBTime, LMovesToGo = string.match(LInput, "go wtime (%d+) btime (%d+) movestogo (%d+)")
    if LWTime == nil then OnGo(0, 0, 0) else OnGo(LWTime, LBTime, LMovesToGo) end
  elseif string.sub(LInput, 1, 5) == "perft" then
    LValue = string.match(LInput, "perft (%d+)")
    io.write(string.format("perft(%d) = %d\n", LValue, CountLegalMove(LPos, tonumber(LValue))))
    io.flush()
  end
end
