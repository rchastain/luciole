
local XFEN = {}

function FileLetter(AFile, AColor)
  return string.char(string.byte(AColor and 'a' or 'A') + AFile - 1)
end

function XFEN.EncodeCastling(AFen3, ABoard)
  
  function RookFile(
    AColor,
    APattern,
    AFrom,
    ATo,
    AStep,
    AKey
  )
    local LResult = nil
    for LMatch in string.gmatch(AFen3, APattern) do
      local LRook = AColor and 'r' or 'R'
      local LRank = AColor and  8  or  1
      for x = AFrom, ATo, AStep do
        if LResult == nil then
          if (ABoard[x][LRank] == LRook) and ((LMatch == FileLetter(x, AColor)) or (LMatch == AKey)) then
            LResult = x
            break
          end
        end
      end
    end
    return LResult
  end

  local K, Q, k, q, X = nil, nil, nil, nil, nil
  local WhiteCastling = string.match(AFen3, "[ABCDEFGHKQ]")
  local BlackCastling = string.match(AFen3, "[abcdefghkq]")
  
  if WhiteCastling then
    for x = 1, 8 do
      if ABoard[x][1] == 'K' then
        X = x
        break
      end
    end
    K = RookFile(false, "[BCDEFGHK]", 8, X, -1, "K")
    Q = RookFile(false, "[ABCDEFGQ]", 1, X,  1, "Q")
  end
  
  if BlackCastling then
    if X == nil then
      for x = 1, 8 do
        if ABoard[x][8] == 'k' then
          X = x
          break
        end
      end
    end
    k = RookFile(true,  "[bcdefghk]", 8, X, -1, "k")
    q = RookFile(true,  "[abcdefgq]", 1, X,  1, "q")
  end

  return {K = K, Q = Q, k = k, q = q, X = X}
end 

function RookInFront(ABoard, AColor, AFrom, ATo, AStep)
  local LRook = AColor and 'r' or 'R'
  local LRank = AColor and  8  or  1
  for x = AFrom, ATo - AStep, AStep do
    if ABoard[x][LRank] == LRook then
      return true
    end
  end
  return false
end

function XFEN.DecodeCastling(ACastling, ABoard, AAlwaysFileLetter)
  local LResult = ""
  if AAlwaysFileLetter then -- Shredder-FEN
    if ACastling.K then LResult = LResult .. FileLetter(ACastling.K, false) end
    if ACastling.Q then LResult = LResult .. FileLetter(ACastling.Q, false) end
    if ACastling.k then LResult = LResult .. FileLetter(ACastling.k,  true) end
    if ACastling.q then LResult = LResult .. FileLetter(ACastling.q,  true) end
  else -- X-FEN
    if ACastling.K then LResult = LResult .. (RookInFront(ABoard, false, 8, ACastling.K,-1) and FileLetter(ACastling.K, false) or "K") end
    if ACastling.Q then LResult = LResult .. (RookInFront(ABoard, false, 1, ACastling.Q, 1) and FileLetter(ACastling.Q, false) or "Q") end
    if ACastling.k then LResult = LResult .. (RookInFront(ABoard, true,  8, ACastling.k,-1) and FileLetter(ACastling.k, true)  or "k") end
    if ACastling.q then LResult = LResult .. (RookInFront(ABoard, true,  1, ACastling.q, 1) and FileLetter(ACastling.q, true)  or "q") end
  end
  return (string.len(LResult) > 0) and LResult or "-"
end

return XFEN
