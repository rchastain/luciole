
require('strict')
local Chess = require('chess')
local LLog = require("modules/log/log")
LLog.outfile = "luciole.log"
LLog.usecolor = false

local LPos = Chess.EncodePosition()

local function OnNewGame()
  LPos = Chess.EncodePosition()
end

local function OnStartPos()
  LPos = Chess.EncodePosition()
end

local function OnFen(AFen)
  LPos = Chess.EncodePosition(AFen)
end

local function OnMove(AMove)
  local x1, y1, x2, y2, p = Chess.StrToMove(AMove)
  if Chess.IsKing(LPos.piecePlacement[x1][y1]) then
    if (x2 - x1 == 2) then -- e1g1, e8g8
      x2 = 8
    elseif (x2 - x1 == -2) then -- e1c1, e8c8
      x2 = 1
    end
  end
  Chess.DoMove(LPos, x1, y1, x2, y2, p)
end

local function OnGo(AWTime, ABTime, AMovesToGo)
  local LTime = os.clock()
  local LMove = Chess.BestMove(LPos)
  LTime = os.clock() - LTime
  --LLog.debug(string.format("Temps écoulé : %.2f s", LTime))
  io.write(string.format("bestmove %s\n", LMove))
  io.flush()
end

local function OnSetOption(AValue)
  --LLog.debug(AValue)
end

local LValue, LIndex = "", 0

while true do
  local LInput = io.read()
  if LInput == nil then break end
  LLog.debug(">> " .. LInput)
  LValue = string.match(LInput, "setoption name UCI_Chess960 value (%w+)")
  if LValue then
    OnSetOption(LValue == "true")
  elseif LInput == "uci" then
    io.write(string.format("id name %s\nid author %s\noption name UCI_Chess960 type check default false\nuciok\n", "Luciole 0.0.4", "Roland Chastain"))
    io.flush()
  elseif LInput == "isready" then
    io.write(string.format("readyok\n"))
    io.flush()
  elseif LInput == "ucinewgame" then
    OnNewGame()
  elseif LInput == "quit" then
    break
  elseif LInput == "show" then
    io.write(Chess.BoardToText(LPos.piecePlacement) .. '\n')
    io.write(Chess.DecodePosition(LPos) .. '\n')
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
      --LLog.debug(LInput)
      for LMove in string.gmatch(LInput, "[%w][%d][%w][%d][%w]?") do
        OnMove(LMove)
      end
    end
  elseif string.sub(LInput, 1, 2) == "go" then
    local LWTime, LBTime, LMovesToGo = string.match(LInput, "go wtime (%d+) btime (%d+) movestogo (%d+)")
    if LWTime == nil then OnGo(0, 0, 0) else OnGo(LWTime, LBTime, LMovesToGo) end
  elseif string.sub(LInput, 1, 5) == "perft" then
    LValue = string.match(LInput, "perft (%d+)")
    io.write(string.format("perft(%d) = %d\n", LValue, Chess.CountLegalMove(LPos, tonumber(LValue))))
    io.flush()
  end
end
