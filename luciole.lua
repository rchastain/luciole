
-- Luciole
-- Joueur d'échecs artificiel écrit en Lua.

-- Module pour la recherche du meilleur coup.
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
  local LMove = BestMove(LPos)
  io.write(string.format("bestmove %s\n", LMove))
  io.flush()
end

-- Boucle principale (interface UCI)

while true do
  local LInput = io.read()
  
  if LInput == "uci" then
    io.write(string.format("id name %s\nid author %s\nuciok\n", "Luciole 0.0.1", "R. Chastain"))
    io.flush()
  end
  if LInput == "isready" then
    io.write(string.format("readyok\n"))
    io.flush()
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
