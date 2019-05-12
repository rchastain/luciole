
-- Luciole
-- UCI chess engine by R. Chastain

-- Module for chess playing
require('chess')
local LCurrPos = EncodePosition()

-- Module for table pretty printing
local LSerpent = require("modules\\serpent\\serpent")

-- Module for logging
local LLog = require("modules\\log\\log")
LLog.outfile = "luciole.log"
LLog.usecolor = false

function OnUciNewGame()
  LCurrPos = EncodePosition()
end

function OnPositionStartPos()
  LCurrPos = EncodePosition()
end

function OnPositionFen(AFEN)
  LCurrPos = EncodePosition(AFEN)
end

function OnPositionMove(AMove)
  DoMove(LCurrPos, StrToMove(AMove))
end

function OnGo(AWTime, ABTime, AMovesToGo)
  local LBest = GenBest2(LCurrPos)
  LLog.debug(LSerpent.line(LBest, {comment = false}))
  local LMove = LBest[1][1]
  if IsPromotion(LCurrPos, LMove) then
    LMove = LMove .. "q"
  end
  io.write(string.format("bestmove %s\n", LMove))
  io.flush()
end

while true do
  local LInput = io.read()
  LLog.debug(LInput)
  -- uci
  if LInput == "uci" then
    io.write(string.format("id name %s\nid author %s\nuciok\n", "Luciole 0.0.1", "R. Chastain"))
    io.flush()
  end
  -- isready
  if LInput == "isready" then
    io.write(string.format("readyok\n"))
    io.flush()
  end
  -- ucinewgame
  if LInput == "ucinewgame" then
    OnUciNewGame()
  end
  -- quit
  if LInput == "quit" then
    break
  end
  -- show
  if LInput == "show" then
    io.write(BoardToText(LCurrPos.piecePlacement) .. '\n')
    io.flush()
  end
  -- position
  if string.sub(LInput, 1, 8) == "position" then
    if string.sub(LInput, 10, 17) == "startpos" then
      OnPositionStartPos()
    elseif string.sub(LInput, 10, 12) == "fen" then
      local LFEN = string.match(LInput, "%w+/%w+/%w+/%w+/%w+/%w+/%w+/%w+ [wb] [%w-]+ [%w-]+ %d+ %d+")
      if LFEN ~= nil then
        OnPositionFen(LFEN)
      end
    end
    if string.find(LInput, "moves") then
      for LMove in string.gmatch(LInput, "[%w][%d][%w][%d][%w]?") do
        OnPositionMove(LMove)
      end
    end
  end
  -- go
  if string.sub(LInput, 1, 2) == "go" then
    local LWTime, LBTime, LMovesToGo = string.match(LInput, "go wtime (%d+) btime (%d+) movestogo (%d+)")
    if LWTime == nil then
      OnGo(0, 0, 0)
    else
      OnGo(LWTime, LBTime, LMovesToGo)
    end
  end
end
