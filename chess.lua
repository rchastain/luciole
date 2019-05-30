
-- Luciole
-- Joueur d'échecs artificiel
-- Cerveau du joueur d'échecs artificiel

require("xfen")

local LSerpent = require("modules/serpent/serpent") -- Module pour la conversion des tables en chaînes de caractères
GLog = require("modules/log/log") -- Module pour la production du journal
GLog.outfile = "luciole.log"
GLog.usecolor = false

local LSquareName = {
  {'a1', 'a2', 'a3', 'a4', 'a5', 'a6', 'a7', 'a8'},
  {'b1', 'b2', 'b3', 'b4', 'b5', 'b6', 'b7', 'b8'},
  {'c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'c8'},
  {'d1', 'd2', 'd3', 'd4', 'd5', 'd6', 'd7', 'd8'},
  {'e1', 'e2', 'e3', 'e4', 'e5', 'e6', 'e7', 'e8'},
  {'f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8'},
  {'g1', 'g2', 'g3', 'g4', 'g5', 'g6', 'g7', 'g8'},
  {'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'h7', 'h8'}
}

function InRange(aNumber, aLow, aHigh)
  return (aNumber >= aLow) and (aNumber <= aHigh)
end

function IsBetween(aNumber, aLow, aHigh)
  return (aNumber > aLow) and (aNumber < aHigh) or (aNumber > aHigh) and (aNumber < aLow)
end

function StrToSquare(aStr)
  --assert(#aStr == 2)
  --assert(string.match(aStr, '[a-h][1-8]'))
  return
    string.byte(aStr, 1) - string.byte('a') + 1,
    string.byte(aStr, 2) - string.byte('1') + 1
end

function SquareToStr(aX, aY)
  --assert(InRange(aX, 1, 8))
  --assert(InRange(aY, 1, 8))
  return string.char(
    string.byte('a') + aX - 1,
    string.byte('1') + aY - 1
  )
end

function StrToMove(aStr)
  assert(InRange(#aStr, 4, 5))
  assert(string.match(aStr, '[a-h][1-8][a-h][1-8]' .. ((#aStr == 5) and '[nbrq]' or '')), '"' .. aStr .. '"')
  local promotion = (#aStr == 5) and string.sub(aStr, 5, 5) or nil
  return
    string.byte(aStr, 1) - string.byte('a') + 1,
    string.byte(aStr, 2) - string.byte('1') + 1,
    string.byte(aStr, 3) - string.byte('a') + 1,
    string.byte(aStr, 4) - string.byte('1') + 1,
    promotion
end

function MoveToStr(aX1, aY1, aX2, aY2)
  --assert(InRange(aX1, 1, 8))
  --assert(InRange(aY1, 1, 8))
  --assert(InRange(aX2, 1, 8))
  --assert(InRange(aY2, 1, 8))
  return string.char(
    string.byte('a') + aX1 - 1,
    string.byte('1') + aY1 - 1,
    string.byte('a') + aX2 - 1,
    string.byte('1') + aY2 - 1
  )
end

function CastlingMove(ACastling, AKey, ATradition)
  if ATradition then
    if AKey == "K" then return "e1g1" end
    if AKey == "Q" then return "e1c1" end
    if AKey == "k" then return "e8g8" end
    if AKey == "q" then return "e8c8" end
  else
    local LRank = ((AKey == "K") or (AKey == "Q")) and 1 or 8
    return MoveToStr(ACastling.X, LRank, ACastling[AKey], LRank)
  end
end

function BoardToText(aBoard)
  local result = '+    A B C D E F G H    +\n\n'
  for y = 8, 1, -1 do
    result = result .. tostring(y) .. '   '
    for x = 1, 8 do
      result = result .. ' ' .. ((aBoard[x][y] ~= nil) and aBoard[x][y] or '.')
    end
    result = result .. '    ' .. tostring(y) .. '\n'
  end
  result = result .. '\n+    A B C D E F G H    +'
  return result
end

function MovePiece(aBoard, x1, y1, x2, y2, aPromotion)
  --assert(InRange(x1, 1, 8))
  --assert(InRange(y1, 1, 8))
  --assert(InRange(x2, 1, 8))
  --assert(InRange(y2, 1, 8))
  if aBoard[x1][y1] == nil then
    return false
  else
    aBoard[x2][y2] = aPromotion or aBoard[x1][y1]
    aBoard[x1][y1] = nil
    return true 
  end
end

function MoveKingRook(aBoard, kx1, ky1, kx2, ky2, rx1, ry1, rx2, ry2)
  if (aBoard[kx1][ky1] == nil) or (aBoard[rx1][ry1] == nil) then
    return false
  else
    local LRook = aBoard[rx1][ry1]
    aBoard[rx1][ry1] = nil
    if kx2 ~= kx1 then
      aBoard[kx2][ky2] = aBoard[kx1][ky1]
      aBoard[kx1][ky1] = nil
    end
    aBoard[rx2][ry2] = LRook
    return true 
  end
end

function IsColor(aBoardValue, aColor)
  --assert(string.match(aColor, '[wb]'))
  return (aBoardValue ~= nil) and string.match(aBoardValue, (aColor == 'w') and '[PNBRQK]' or '[pnbrqk]')
end

function OtherColor(aColor)
  --assert(string.match(aColor, '[wb]'))
  return (aColor == 'w') and 'b' or 'w'
end

function IsWhitePiece(aBoardValue)
  return IsColor(aBoardValue, 'w')
end

function IsBlackPiece(aBoardValue)
  return IsColor(aBoardValue, 'b')
end

function IsSameColor(ABoardValue1, ABoardValue2)
  return IsWhitePiece(ABoardValue1) and IsWhitePiece(ABoardValue2) or IsBlackPiece(ABoardValue1) and IsBlackPiece(ABoardValue2)
end

function IsPawn(aBoardValue)
  return (aBoardValue == 'P') or (aBoardValue == 'p')
end

function IsKnight(aBoardValue)
  return (aBoardValue == 'N') or (aBoardValue == 'n')
end

function IsBishop(aBoardValue)
  return (aBoardValue == 'B') or (aBoardValue == 'b')
end

function IsRook(aBoardValue)
  return (aBoardValue == 'R') or (aBoardValue == 'r')
end

function IsQueen(aBoardValue)
  return (aBoardValue == 'Q') or (aBoardValue == 'q')
end

function IsKing(aBoardValue)
  return (aBoardValue == 'K') or (aBoardValue == 'k')
end

function StrToBoard(AFen1)
  local result = {{}, {}, {}, {}, {}, {}, {}, {}}
  local i, x, y = 1, 1, 8
  while i <= #AFen1 do
    local s = string.sub(AFen1, i, i)
    if s == '/' then
      y = y - 1
      x = 1
    elseif string.match(s, '%d') then
      for i = 1, tonumber(s) do
        result[x][y] = nil
        x = x + 1
      end
    else
      result[x][y] = s
      x = x + 1
    end
    i = i + 1
  end
  return result
end

function EncodePosition(AFen)
  local t = {}
  for s in string.gmatch(AFen or 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1', '%S+') do
    t[#t + 1] = s
  end
  assert(#t == 6, AFen)
  local LBoard = StrToBoard(t[1])
  return {
    piecePlacement = LBoard,
    activeColor = t[2],
    castlingAvailability = EncodeCastling(t[3], LBoard),
    enPassantTargetSquare = t[4],
    halfmoveClock = tonumber(t[5]),
    fullmoveNumber = tonumber(t[6])
  }
end

function BoardToStr(aBoard)
  local result = ''
  for y = 8, 1, -1 do
    local x = 1
    while x <= 8 do
      if aBoard[x][y] ~= nil then
        result = result .. aBoard[x][y]
        x = x + 1
      else
        local n = 0
        while (x <= 8) and (aBoard[x][y] == nil) do
          n, x = n + 1, x + 1
        end
        result = result .. tostring(n)
      end
    end
    if y > 1 then result = result .. '/' end
  end
  return result
end

function DecodePosition(APos)
  return string.format(
    '%s %s %s %s %d %d',
    BoardToStr(APos.piecePlacement),
    APos.activeColor,
    DecodeCastling(APos.castlingAvailability, APos.piecePlacement, false),
    APos.enPassantTargetSquare,
    APos.halfmoveClock,
    APos.fullmoveNumber
  )
end

local LVectors = {
  {x =-1, y = 1},
  {x = 1, y = 1},
  {x =-1, y =-1},
  {x = 1, y =-1},
  {x =-1, y = 0},
  {x = 1, y = 0},
  {x = 0, y = 1},
  {x = 0, y =-1},
  {x = 1, y = 2},
  {x = 2, y = 1},
  {x = 2, y =-1},
  {x = 1, y =-2},
  {x =-1, y =-2},
  {x =-2, y =-1},
  {x =-2, y = 1},
  {x =-1, y = 2}
}

function ComputeTargetSquare(aX1, aY1, aVectorIndex)
  --assert(InRange(aVectorIndex, 1, #LVectors))
  local x2, y2 =
    aX1 + LVectors[aVectorIndex].x,
    aY1 + LVectors[aVectorIndex].y
  if InRange(x2, 1, 8) and InRange(y2, 1, 8) then
    return true, x2, y2
  else
    return false
  end
end

function GenMoves(aBoard, aColor)
  local j, k
  local result = {}
  for x = 1, 8 do
    for y = 1, 8 do
      if IsColor(aBoard[x][y], aColor) then
        if IsPawn(aBoard[x][y]) then
          if IsWhitePiece(aBoard[x][y]) then
            j, k = 1, 2
          else
            j, k = 3, 4
          end
          for i = j, k do
            local success, x2, y2 = ComputeTargetSquare(x, y, i)
            if success and IsColor(aBoard[x2][y2], OtherColor(aColor)) then
              --result[#result + 1] = MoveToStr(x, y, x2, y2)
              result[#result + 1] = LSquareName[x][y] .. LSquareName[x2][y2]
            end
          end
        elseif IsKnight(aBoard[x][y]) or IsKing(aBoard[x][y]) then
          if IsKnight(aBoard[x][y]) then
            j, k = 9, 16
          elseif IsKing(aBoard[x][y]) then
            j, k = 1, 8
          end
          for i = j, k do
            local success, x2, y2 = ComputeTargetSquare(x, y, i)
            if success and not IsColor(aBoard[x2][y2], aColor) then
              --result[#result + 1] = MoveToStr(x, y, x2, y2)
              result[#result + 1] = LSquareName[x][y] .. LSquareName[x2][y2]
            end
          end
        elseif IsBishop(aBoard[x][y]) or IsRook(aBoard[x][y]) or IsQueen(aBoard[x][y]) then
          if IsBishop(aBoard[x][y]) then
            j, k = 1, 4
          elseif IsRook(aBoard[x][y]) then
            j, k = 5, 8
          elseif IsQueen(aBoard[x][y]) then
            j, k = 1, 8
          end
          for i = j, k do
            local success, x2, y2 = ComputeTargetSquare(x, y, i)
            while success and not IsColor(aBoard[x2][y2], aColor) do
              --result[#result + 1] = MoveToStr(x, y, x2, y2)
              result[#result + 1] = LSquareName[x][y] .. LSquareName[x2][y2]
              if aBoard[x2][y2] ~= nil then
                break
              end
              success, x2, y2 = ComputeTargetSquare(x2, y2, i)
            end
          end
        end
      end
    end
  end
  return result
end

function Think(APos)
  local LMoves = GenMoves(APos.piecePlacement, OtherColor(APos.activeColor))
  local LCheck = false
  local LCastleCheck = {
    K = false,
    Q = false,
    k = false,
    q = false
  }
  for k, v in ipairs(LMoves) do
    local x2, y2 = StrToSquare(string.sub(v, 3, 4))
    if IsKing(APos.piecePlacement[x2][y2]) then
      LCheck = true
    end
    
    if APos.castlingAvailability.X ~= nil then
      if (APos.activeColor == 'w') and (y2 == 1) then
        if IsBetween(x2, APos.castlingAvailability.X, 7) then
          LCastleCheck.K = true
        elseif IsBetween(x2, APos.castlingAvailability.X, 3) then
          LCastleCheck.Q = true
        end
      elseif (APos.activeColor == 'b') and (y2 == 8) then
        if IsBetween(x2, APos.castlingAvailability.X, 7) then
          LCastleCheck.k = true
        elseif IsBetween(x2, APos.castlingAvailability.X, 3) then
          LCastleCheck.q = true
        end
      end
    end
  end
  local result = {
    check = LCheck and true or false,
    castlingCheck = LCastleCheck
  }
  return result
end

function IsWayClear(aBoard, aColor, aKingX, aRookX)
  local result = true
  local y = (aColor == 'w') and 1 or 8
  result = result and (aBoard[aKingX][y] == ((aColor == 'w') and 'K' or 'k'))
  result = result and (aBoard[aRookX][y] == ((aColor == 'w') and 'R' or 'r'))
  --print(1)
  if aRookX > aKingX then
    --print(2)
    for x = math.min(aKingX, 6), math.max(aRookX, 7), 1 do
      --print(3)
      result = result and ((aBoard[x][y] == nil) or (x == aKingX) or (x == aRookX))
    end
  else
    --print(4)
    for x = math.max(aKingX, 4), math.min(aRookX, 3), -1 do
      --print(5)
      result = result and ((aBoard[x][y] == nil) or (x == aKingX) or (x == aRookX))
    end
  end
  return result
end

function GenSpecial(APos, aColor)
  local j, k
  local result = {}
  local extraPositionData = Think(APos)
  
  local function GenCastling(ASymbol)
    local LColor = ((ASymbol == "K") or (ASymbol == "Q")) and "w" or "b"
    if (APos.castlingAvailability[ASymbol] ~= nil)
    and IsWayClear(APos.piecePlacement, LColor, APos.castlingAvailability.X, APos.castlingAvailability[ASymbol])
    and not extraPositionData.castlingCheck[ASymbol] then
      result[#result + 1] = CastlingMove(APos.castlingAvailability, ASymbol, false)
    end
  end
  
  for x = 1, 8 do
    for y = 1, 8 do
      if IsColor(APos.piecePlacement[x][y], aColor) then
        if IsPawn(APos.piecePlacement[x][y]) then
          if IsWhitePiece(APos.piecePlacement[x][y]) then
            j = 7
          else
            j = 8
          end
          local success, x2, y2 = ComputeTargetSquare(x, y, j)
          if success and (APos.piecePlacement[x2][y2] == nil) then
            --result[#result + 1] = MoveToStr(x, y, x2, y2)
            result[#result + 1] = LSquareName[x][y] .. LSquareName[x2][y2]
            if y == ((aColor == 'w') and 2 or 7) then
              success, x2, y2 = ComputeTargetSquare(x2, y2, j)
              if success and (APos.piecePlacement[x2][y2] == nil) then
                --result[#result + 1] = MoveToStr(x, y, x2, y2)
                result[#result + 1] = LSquareName[x][y] .. LSquareName[x2][y2]
              end
            end
          end
          if IsWhitePiece(APos.piecePlacement[x][y]) then
            j, k = 1, 2
          else
            j, k = 3, 4
          end
          for i = j, k do
            local success, x2, y2 = ComputeTargetSquare(x, y, i)
            if success
            and (APos.piecePlacement[x2][y2] == nil)
            --and (SquareToStr(x2, y2) == APos.enPassantTargetSquare) then
            and (LSquareName[x2][y2] == APos.enPassantTargetSquare) then
              --result[#result + 1] = MoveToStr(x, y, x2, y2)
              result[#result + 1] = LSquareName[x][y] .. LSquareName[x2][y2]
            end
          end
        elseif IsKing(APos.piecePlacement[x][y]) and not extraPositionData.check then
          if IsWhitePiece(APos.piecePlacement[x][y]) then
            GenCastling('K')
            GenCastling('Q')
          else
            GenCastling('k')
            GenCastling('q')
          end
        end
      end
    end
  end
  return result
end

function RemoveCastling(APos, aChar)
  APos.castlingAvailability[aChar] = nil
end

function DoMove(APos, x1, y1, x2, y2, aPromotion)
  assert(APos.piecePlacement[x1][y1] ~= nil, "coup impossible " .. MoveToStr(x1, y1, x2, y2) .. " (pas de pièce sur la case de départ)")
  local result = true
  local LSkip = false
  if IsKing(APos.piecePlacement[x1][y1]) and (x1 == APos.castlingAvailability.X) then
    if (y1 == 1) and (APos.activeColor == 'w') then
      RemoveCastling(APos, 'K')
      RemoveCastling(APos, 'Q')
    elseif (y1 == 8)  and (APos.activeColor == 'b') then
      RemoveCastling(APos, 'k')
      RemoveCastling(APos, 'q')
    end
  end
  if IsRook(APos.piecePlacement[x1][y1]) then
    if (y1 == 1) and (APos.activeColor == 'w') then
      if (x1 == APos.castlingAvailability.K) then RemoveCastling(APos, 'K') end
      if (x1 == APos.castlingAvailability.Q) then RemoveCastling(APos, 'Q') end
    elseif (y1 == 8) and (APos.activeColor == 'b') then
      if (x1 == APos.castlingAvailability.k) then RemoveCastling(APos, 'k') end
      if (x1 == APos.castlingAvailability.q) then RemoveCastling(APos, 'q') end
    end
  end
  if IsPawn(APos.piecePlacement[x1][y1]) and (math.abs(y2 - y1) == 2) then
    APos.enPassantTargetSquare = SquareToStr(x1, (APos.activeColor == 'w') and 3 or 6)
  else
    APos.enPassantTargetSquare = '-'
  end
  
  if IsKing(APos.piecePlacement[x1][y1]) and IsRook(APos.piecePlacement[x2][y2]) and IsSameColor(APos.piecePlacement[x1][y1], APos.piecePlacement[x2][y2]) then
    if x2 > x1 then
      result = result and MoveKingRook(APos.piecePlacement, x1, y1, 7, y1, x2, y1, 6, y1)
      LSkip = true
    else
      result = result and MoveKingRook(APos.piecePlacement, x1, y1, 3, y1, x2, y1, 4, y1)
      LSkip = true
    end
  end
  
  if IsPawn(APos.piecePlacement[x1][y1]) and (math.abs(x2 - x1) == 1) and (APos.piecePlacement[x2][y2] == nil) then
    APos.piecePlacement[x2][y1] = nil
  end
  if IsPawn(APos.piecePlacement[x1][y1]) or (APos.piecePlacement[x2][y2] ~= nil) then
    APos.halfmoveClock = 0
  else
    APos.halfmoveClock = APos.halfmoveClock + 1
  end
  
  if APos.activeColor == 'b' then
    APos.fullmoveNumber = APos.fullmoveNumber + 1
  end
  
  if IsPawn(APos.piecePlacement[x1][y1]) and ((y2 == 1) or (y2 == 8)) then
    if aPromotion == nil then
      aPromotion = (APos.activeColor == 'w') and 'Q' or 'q'
    else
      aPromotion = (APos.activeColor == 'w') and string.upper(aPromotion) or string.lower(aPromotion)
    end
  else
    aPromotion = nil
  end
  
  if not LSkip then
    result = result and MovePiece(APos.piecePlacement, x1, y1, x2, y2, aPromotion)
  end
  APos.activeColor = OtherColor(APos.activeColor)
  return result
end

function GenLegal(APos)
  local LPosStr = DecodePosition(APos)
  local LT1 = GenMoves(APos.piecePlacement, APos.activeColor)
  local LT2 = GenSpecial(APos, APos.activeColor)
  local LT3 = {}
  for k, v in ipairs(LT1) do LT3[#LT3 + 1] = v end
  for k, v in ipairs(LT2) do LT3[#LT3 + 1] = v end
  local result = {}
  for k, v in ipairs(LT3) do
    local x1, y1, x2, y2 = StrToMove(v)
    local LPos1 = EncodePosition(LPosStr)
    if DoMove(LPos1, x1, y1, x2, y2, nil) then
      LPos1.activeColor = OtherColor(LPos1.activeColor)
      local LThink = Think(LPos1)
      if not LThink.check then
        result[#result + 1] = v
      end
    end
  end
  return result
end

function IsEnPassant(APos, aMove)
  local x1, y1, x2, y2 = StrToMove(aMove)
  if IsPawn(APos.piecePlacement[x1][y1])
  and (x2 ~= x1)
  and (APos.piecePlacement[x2][y2] == nil) then
    --return true, SquareToStr(x2, y1)
    return true, LSquareName[x2][y1]
  else
    return false
  end
end

function IsPromotion(APos, aMove)
  local x1, y1, x2, y2 = StrToMove(aMove)
  return IsPawn(APos.piecePlacement[x1][y1]) and ((y2 == 1) or (y2 == 8))
end

function IsCastling(APos, aMove)
  local x1, y1, x2, y2 = StrToMove(aMove)
  return IsKing(APos.piecePlacement[x1][y1]) and IsRook(APos.piecePlacement[x2][y2])
end

function Material(APos)
  local result = 0
  for x = 1, 8 do
    for y = 1, 8 do
      local LPiece = APos.piecePlacement[x][y]
      if LPiece ~= nil then
        local d = 0      
        if     IsPawn  (LPiece) then d =  10
        elseif IsKnight(LPiece) then d =  30
        elseif IsBishop(LPiece) then d =  35
        elseif IsRook  (LPiece) then d =  80
        elseif IsQueen (LPiece) then d = 150
        elseif IsKing  (LPiece) then d = 500
        end
        if IsBlackPiece(LPiece) then
          d = -1 * d
        end
        result = result + d
      end
    end
  end
  if APos.activeColor == 'b' then
    result = -1 * result
  end
  return result
end

function CopyPosition(APos)
  local result = {}
  result.piecePlacement = {{}, {}, {}, {}, {}, {}, {}, {}}
  for x = 1, 8 do
    for y = 1, 8 do
      result.piecePlacement[x][y] = APos.piecePlacement[x][y]
    end
  end
  result.activeColor = APos.activeColor
  result.castlingAvailability = APos.castlingAvailability
  result.enPassantTargetSquare = APos.enPassantTargetSquare
  result.halfmoveClock = APos.halfmoveClock
  result.fullmoveNumber = APos.fullmoveNumber
  return result
end

function GenBest(APos)
  local LT1 = GenMoves(APos.piecePlacement, APos.activeColor)
  local LT2 = GenSpecial(APos, APos.activeColor)
  local LT3 = {}
  local LCount = 0
  for k, v in ipairs(LT1) do LT3[#LT3 + 1] = v end
  for k, v in ipairs(LT2) do LT3[#LT3 + 1] = v end
  local result = {}
  for k, v in ipairs(LT3) do
    local x1, y1, x2, y2 = StrToMove(v)
    LPos1 = CopyPosition(APos)
    if DoMove(LPos1, x1, y1, x2, y2, nil) then
      local LMin2 = math.maxinteger
      LT1 = GenMoves(LPos1.piecePlacement, LPos1.activeColor)
      for kk, vv in ipairs(LT1) do
        local xx1, yy1, xx2, yy2 = StrToMove(vv)
        LPos2 = CopyPosition(LPos1)
        if IsKing(LPos2.piecePlacement[xx2][yy2]) then
          LMin2 = math.mininteger
          break
        elseif DoMove(LPos2, xx1, yy1, xx2, yy2, nil) then
          local LMax3 = math.mininteger
          LT2 = GenMoves(LPos2.piecePlacement, LPos2.activeColor)
          LCount = 0
          for kkk, vvv in ipairs(LT2) do
            local xxx1, yyy1, xxx2, yyy2 = StrToMove(vvv)
            if LPos2.piecePlacement[xxx2][yyy2] == nil then
              LCount = LCount + 1
            end
            if (LCount < 2) or (LPos2.piecePlacement[xxx2][yyy2] ~= nil) then
              LPos3 = CopyPosition(LPos2)
              if DoMove(LPos3, xxx1, yyy1, xxx2, yyy2, nil) then
                LPos3.activeColor = OtherColor(LPos3.activeColor)
                local LScore2 = Material(LPos3)
                if LScore2 > LMax3 then
                  LMax3 = LScore2
                end
              end
            end
          end
          if LMax3 < LMin2 then
            LMin2 = LMax3
          end
        end
      end
      table.insert(result, {v, LMin2})
    end
  end
  table.sort(result, function(a, b) return a[2] > b[2] end)
  return result
end

function BestMove(APos)
  local LBest = GenBest(APos)
  GLog.debug(LSerpent.line(LBest, {comment = false}))
  
  local LBest2 = {}
  table.insert(LBest2, {LBest[1][1], 0})
  local i = 2
  while (i <= #LBest) and (LBest[i][2] == LBest[i-1][2]) do
    table.insert(LBest2, {LBest[i][1], 0})
    i = i + 1
  end
  i = 1
  while i <= #LBest2 do
    --local x1, y1, x2, y2 = StrToMove(LBest2[i][1])
    --LBest2[i][2] = IsPawn(APos.piecePlacement[x1][y1]) and 1 or 0
    LBest2[i][2] = IsCastling(APos, LBest2[i][1]) and 1 or 0
    i = i + 1
  end
  table.sort(LBest2, function(a, b) return a[2] > b[2] end)
  GLog.debug(LSerpent.line(LBest2, {comment = false}))
  
  local LMove = LBest2[1][1]
  if IsPromotion(APos, LMove) then
    LMove = LMove .. "q"
  end
  return LMove
end

function CountLegalMove(APos, ADepth)
  local LPos = CopyPosition(APos)
  local LLegal = GenLegal(LPos)
  if ADepth < 2 then
    return #LLegal
  else
    local LTotal = 0
    for k, v in ipairs(LLegal) do
      local x1, y1, x2, y2 = StrToMove(v)
      local LPos1 = CopyPosition(APos)
      if DoMove(LPos1, x1, y1, x2, y2, nil) then
        LTotal = LTotal + CountLegalMove(LPos1, ADepth - 1)
      end
    end
    return LTotal
  end  
end
