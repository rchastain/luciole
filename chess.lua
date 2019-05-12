
function InRange(aNumber, aLow, aHigh)
  return (aNumber >= aLow) and (aNumber <= aHigh)
end

function StrToSquare(aStr)
  assert(#aStr == 2)
  assert(string.match(aStr, '[a-h][1-8]'))
  return
    string.byte(aStr, 1) - string.byte('a') + 1,
    string.byte(aStr, 2) - string.byte('1') + 1
end

function SquareToStr(aX, aY)
  assert(InRange(aX, 1, 8))
  assert(InRange(aY, 1, 8))
  return string.char(
    string.byte('a') + aX - 1,
    string.byte('1') + aY - 1
  )
end

function StrToMove(aStr)
  assert(InRange(#aStr, 4, 5))
  assert(string.match(aStr, '[a-h][1-8][a-h][1-8]' .. ((#aStr == 5) and '[nbrq]' or '')))
  local promotion = (#aStr == 5) and string.sub(aStr, 5, 5) or nil
  return
    string.byte(aStr, 1) - string.byte('a') + 1,
    string.byte(aStr, 2) - string.byte('1') + 1,
    string.byte(aStr, 3) - string.byte('a') + 1,
    string.byte(aStr, 4) - string.byte('1') + 1,
    promotion
end

function MoveToStr(aX1, aY1, aX2, aY2)
  assert(InRange(aX1, 1, 8))
  assert(InRange(aY1, 1, 8))
  assert(InRange(aX2, 1, 8))
  assert(InRange(aY2, 1, 8))
  return string.char(
    string.byte('a') + aX1 - 1,
    string.byte('1') + aY1 - 1,
    string.byte('a') + aX2 - 1,
    string.byte('1') + aY2 - 1
  )
end

function BoardToText(aBoard)
  local result = ''
  for y = 8, 1, -1 do
    for x = 1, 8 do
      result = result .. ((aBoard[x][y] ~= nil) and aBoard[x][y] or '.')
    end
    if y > 1 then
      result = result .. '\n'
    end
  end
  return result
end

function MovePiece(aBoard, x1, y1, x2, y2, aPromotion)
  assert(InRange(x1, 1, 8))
  assert(InRange(y1, 1, 8))
  assert(InRange(x2, 1, 8))
  assert(InRange(y2, 1, 8))
  if aBoard[x1][y1] == nil then
    return false
  else
    aBoard[x2][y2] = aPromotion or aBoard[x1][y1]
    aBoard[x1][y1] = nil
    return true 
  end
end

function IsColor(aBoardValue, aColor)
  assert(string.match(aColor, '[wb]'))
  return (aBoardValue ~= nil) and string.match(aBoardValue, (aColor == 'w') and '[PNBRQK]' or '[pnbrqk]')
end

function OtherColor(aColor)
  assert(string.match(aColor, '[wb]'))
  return (aColor == 'w') and 'b' or 'w'
end

function IsWhitePiece(aBoardValue)
  return IsColor(aBoardValue, 'w')
end

function IsBlackPiece(aBoardValue)
  return IsColor(aBoardValue, 'b')
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

function StrToBoard(aPiecePlacementStr)
  local result = {{}, {}, {}, {}, {}, {}, {}, {}}
  local i, x, y = 1, 1, 8
  while i <= #aPiecePlacementStr do
    local s = string.sub(aPiecePlacementStr, i, i)
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

function EncodePosition(aFENRecord)
  local t = {}
  for s in string.gmatch(aFENRecord or 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1', '%S+') do
    t[#t + 1] = s
  end
  assert(#t == 6)
  return {
    piecePlacement = StrToBoard(t[1]),
    activeColor = t[2],
    castlingAvailability = t[3],
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
          n = n + 1
          x = x + 1
        end
        result = result .. tostring(n)
      end
    end
    if y > 1 then
      result = result .. '/'
    end
  end
  return result
end

function DecodePosition(APos)
  return string.format(
    '%s %s %s %s %d %d',
    BoardToStr(APos.piecePlacement),
    APos.activeColor,
    APos.castlingAvailability,
    APos.enPassantTargetSquare,
    APos.halfmoveClock,
    APos.fullmoveNumber
  )
end

local vectors = {
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
  assert(InRange(aVectorIndex, 1, #vectors))
  local x2, y2 =
    aX1 + vectors[aVectorIndex].x,
    aY1 + vectors[aVectorIndex].y
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
              result[#result + 1] = MoveToStr(x, y, x2, y2)
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
              result[#result + 1] = MoveToStr(x, y, x2, y2)
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
              result[#result + 1] = MoveToStr(x, y, x2, y2)
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
    e1g1 = false,
    e1c1 = false,
    e8g8 = false,
    e8c8 = false
  }
  for k, v in ipairs(LMoves) do
    local x2, y2 = StrToSquare(string.sub(v, 3, 4))
    LCheck = LCheck or IsKing(APos.piecePlacement[x2][y2])
    local row = (APos.activeColor == 'w') and 1 or 8
    if y2 == row then
      if InRange(x2, 5, 8) then
        if row == 1 then
          LCastleCheck.e1g1 = true
        else
          LCastleCheck.e8g8 = true
        end
      else
        if row == 1 then
          LCastleCheck.e1c1 = true
        else
          LCastleCheck.e8c8 = true
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
  result = result and (aBoard[aKingX][y] == (aColor == 'w') and 'K' or 'k')
  result = result and (aBoard[aRookX][y] == (aColor == 'w') and 'R' or 'r')
  local j = (aRookX == 8) and (aKingX + 1) or (aKingX - 1)
  local k = (aRookX == 8) and (aRookX - 1) or (aRookX + 1)
  local step = (k > j) and 1 or -1
  for x = j, k, step do
    result = result and (aBoard[x][y] == nil)
  end
  return result
end

function GenSpecial(APos, aColor)
  local j, k
  local result = {}
  local extraPositionData = Think(APos)
  local function GenCastling(aSymbol, aColor, aKingX, aRookX, aMove)
    if string.match(APos.castlingAvailability, aSymbol)
    and IsWayClear(APos.piecePlacement, aColor, aKingX, aRookX)
    and not extraPositionData.castlingCheck[aMove] then
      result[#result + 1] = aMove
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
            result[#result + 1] = MoveToStr(x, y, x2, y2)
            if y == ((aColor == 'w') and 2 or 7) then
              success, x2, y2 = ComputeTargetSquare(x2, y2, j)
              if success and (APos.piecePlacement[x2][y2] == nil) then
                result[#result + 1] = MoveToStr(x, y, x2, y2)
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
            and (SquareToStr(x2, y2) == APos.enPassantTargetSquare) then
              result[#result + 1] = MoveToStr(x, y, x2, y2)
            end
          end
        elseif IsKing(APos.piecePlacement[x][y]) and not extraPositionData.check then
          if IsWhitePiece(APos.piecePlacement[x][y]) then
            GenCastling('K', aColor, 5, 8, 'e1g1')
            GenCastling('Q', aColor, 5, 1, 'e1c1')
          else
            GenCastling('k', aColor, 5, 8, 'e8g8')
            GenCastling('q', aColor, 5, 1, 'e8c8')
          end
        end
      end
    end
  end
  return result
end

function RemoveCastling(APos, aChar)
  local result = string.gsub(APos.castlingAvailability, aChar, '')
  if result == '' then
    result = '-'
  end
  APos.castlingAvailability = result
end

function DoMove(APos, x1, y1, x2, y2, aPromotion)
  assert(APos.piecePlacement[x1][y1] ~= nil)
  local result = true
  if IsKing(APos.piecePlacement[x1][y1]) and (x1 == 5) then
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
      if (x1 == 8) then RemoveCastling(APos, 'K') end
      if (x1 == 1) then RemoveCastling(APos, 'Q') end
    elseif (y1 == 8) and (APos.activeColor == 'b') then
      if (x1 == 8) then RemoveCastling(APos, 'k') end
      if (x1 == 1) then RemoveCastling(APos, 'q') end
    end
  end
  if IsPawn(APos.piecePlacement[x1][y1]) and (math.abs(y2 - y1) == 2) then
    APos.enPassantTargetSquare = SquareToStr(x1, (APos.activeColor == 'w') and 3 or 6)
  else
    APos.enPassantTargetSquare = '-'
  end
  if IsKing(APos.piecePlacement[x1][y1]) and (math.abs(x2 - x1) == 2) then
    if x2 == 7 then
      result = result and MovePiece(APos.piecePlacement, 8, y1, 6, y2)
    elseif x2 == 3 then
      result = result and MovePiece(APos.piecePlacement, 1, y1, 4, y2)
    else
      assert(false)
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
  result = result and MovePiece(APos.piecePlacement, x1, y1, x2, y2, aPromotion)
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

function IsCastling(APos, aMove)
  local x1, y1, x2, y2 = StrToMove(aMove)
  if IsKing(APos.piecePlacement[x1][y1])
  and (math.abs(x2 - x1) == 2) then
    local rookMove = string.format('%s%d%s%d', (x2 == 7) and 'h' or 'a', y1, (x2 == 7) and 'f' or 'd', y1)
    return true, rookMove
  else
    return false
  end
end

function IsEnPassant(APos, aMove)
  local x1, y1, x2, y2 = StrToMove(aMove)
  if IsPawn(APos.piecePlacement[x1][y1])
  and (x2 ~= x1)
  and (APos.piecePlacement[x2][y2] == nil) then
    return true, SquareToStr(x2, y1)
  else
    return false
  end
end

function IsPromotion(APos, aMove)
  local x1, y1, x2, y2 = StrToMove(aMove)
  return IsPawn(APos.piecePlacement[x1][y1]) and ((y2 == 1) or (y2 == 8))
end

function Material(APos)
  local result = 0
  local diff
  for x = 1, 8 do
    for y = 1, 8 do
      if APos.piecePlacement[x][y] ~= nil then   
        if IsPawn(APos.piecePlacement[x][y]) then
          diff = 10
        elseif IsKnight(APos.piecePlacement[x][y]) then
          diff = 30
        elseif IsBishop(APos.piecePlacement[x][y]) then
          diff = 35
        elseif IsRook(APos.piecePlacement[x][y]) then
          diff = 80
        elseif IsQueen(APos.piecePlacement[x][y]) then
          diff = 150
        elseif IsKing(APos.piecePlacement[x][y]) then
          diff = 5000
        end
        if IsBlackPiece(APos.piecePlacement[x][y]) then
          diff = -1 * diff
        end
        result = result + diff
      end
    end
  end
  if APos.activeColor == 'b' then
    result = -1 * result
  end
  return result
end

function GenBest(APos)
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
      local LPosStr2 = DecodePosition(LPos1)
      local LMax2 = math.mininteger
      LT1 = GenMoves(LPos1.piecePlacement, LPos1.activeColor)
      for kk, vv in ipairs(LT1) do
        local xx1, yy1, xx2, yy2 = StrToMove(vv)
        local LPos2 = EncodePosition(LPosStr2)
        if DoMove(LPos2, xx1, yy1, xx2, yy2, nil) then
          LPos2.activeColor = OtherColor(LPos2.activeColor)
          local LScore = Material(LPos2)
          if LScore > LMax2 then
            LMax2 = LScore
          end
        end
      end
      table.insert(result, {v, -1 * LMax2})
    end
  end
  table.sort(result, function(a, b) return a[2] > b[2] end)
  return result
end

function GenBest2(APos)
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
      local LPosStr2 = DecodePosition(LPos1)
      local LMin2 = math.maxinteger
      LT1 = GenMoves(LPos1.piecePlacement, LPos1.activeColor)
      for kk, vv in ipairs(LT1) do
        local xx1, yy1, xx2, yy2 = StrToMove(vv)
        local LPos2 = EncodePosition(LPosStr2)
        if IsKing(LPos2.piecePlacement[xx2][yy2]) then
          LMin2 = math.mininteger
          break
        elseif DoMove(LPos2, xx1, yy1, xx2, yy2, nil) then
          local LPosStr3 = DecodePosition(LPos2)
          local LMax3 = math.mininteger
          LT2 = GenMoves(LPos2.piecePlacement, LPos2.activeColor)
          for kkk, vvv in ipairs(LT2) do
            local xxx1, yyy1, xxx2, yyy2 = StrToMove(vvv)
            local LPos3 = EncodePosition(LPosStr3)
            
            if DoMove(LPos3, xxx1, yyy1, xxx2, yyy2, nil) then
            
              LPos3.activeColor = OtherColor(LPos3.activeColor)
              local LScore2 = Material(LPos3)
              if LScore2 > LMax3 then
                LMax3 = LScore2
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
