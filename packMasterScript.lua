function Range(rangeList)
 local ret={}
 for _,r in pairs(rangeList)do
  for c=r[1],r[2]do
   table.insert(ret,c)
  end
 end
 return ret
end

pullRate={
--rare
 {rates={
  {slot=2,odds=1/9},--lvx
  {slot=3,odds=4/13},--holo
  {slot=4}--rare
 },num=1},
--reverse
 {rates = {
  {slot=5,odds=1/4},--arceus
  {slot=6,odds=1/36},--shiny
  {slot=7}--reverse
 },num=1},
}

dropSlots={
--1 uncommon
 {sloType="normal",size=29,num=3},
--2 lvx
 {sloType="normal",size=6,num=0},
--3 holo
 {sloType="normal",size=12,num=0},
--4 rare
 {sloType="normal",size=20,num=0},
--5 arceus
 {sloType="normal",size=9,num=0},
--6 shiny
 {sloType="normal",size=3,num=0},
--7 reverse
 {sloType="copy",size=0,num=0,cards=Range({{1,29},{36,67},{80,111}}),copy={}},
--8 common
 {sloType="normal",size=32,num=5},
}

total=0
curCard=1

function filterObjectEnter(enter_object)
 if Global.GetVar("PPacksOn")==0 then return true end
 return false
end

function randomFromRange(low,high)
 local rand=Global.call("PPacksRand")
 local scale=high-low+1
 return math.floor(low+rand*scale)
end

function addToPack(card)
 if not spread then
  if pulls==nil then
   pulls=card
  elseif pulls.type=="Card"then
   pulls=pulls.putObject(card)
  else
   pulls=pulls.putObject(card)
   card.destruct()
  end
 end
end

function takeCard(leaving,index)
 local card=leaving.takeObject({position=cardPos(),rotation=cardRot,index=index,smooth=spread})
 addToPack(card)
 curCard=curCard+1
end

function chooseCard(slot,leaving)
 for c=1,slot.num do
  local index=randomFromRange(total,total+slot.size-1)
  takeCard(leaving,index)
  slot.size=slot.size-1
 end
end

function doPullRates(rate)
 local rand=Global.call("PPacksRand")
 for _,slot in pairs(rate.rates)do
  rand=rand-(slot.odds or 1)
  if rand<=0 and (energy != 2 or dropSlots[slot.slot].sloType != "energy") then
   dropSlots[slot.slot].num=dropSlots[slot.slot].num+1
   return
  end
 end
end

function doFixed(slot,leaving)
 local deckPos=randomFromRange(total,total+slot.size-1)
 for c=0,slot.num-1 do
  takeCard(leaving,deckPos)
  slot.size=slot.size-1
  if deckPos==total+slot.size then deckPos=total end
 end
end

function cardPos()
 return self.positionToWorld({x=(-(curCard-1)*2.25),y=1+(curCard*-0.1),z=0})
end

function onObjectLeaveContainer(cont,leaving)
 if cont~=self or Global.getVar("PPacksOn")==0 then return end

 if not Global.getVar("PPacksRand")then
  local globalMath=Global.getVar("math")
  Global.setVar("PPacksRand",globalMath.random)
 end

 energy=Global.GetVar("PPacksEnergy") or 1
 if Global.GetVar("PPacksSpread")==1 then spread=true else spread=false end
 packPos=self.getPosition()
 cardRot=self.getRotation()
 if spread then cardRot.z=0 else cardRot.z=cardRot.z+180 end

 for _,rate in pairs(pullRate)do
  for c=1,rate.num do
   doPullRates(rate)
  end
 end

 for _,slot in pairs(dropSlots)do
  if slot.sloType=="copy"then
   for c=1,slot.num do
    rand=randomFromRange(1,#slot.cards)
    slot.copy[c]=leaving.GetData().ContainedObjects[slot.cards[rand]]
   end
  end
 end

 for _,slot in pairs(dropSlots)do
  if slot.sloType=="normal"then chooseCard(slot,leaving)
  elseif slot.sloType=="fixed"then doFixed(slot,leaving)
  elseif slot.sloType=="copy"then
   for _,copy in pairs(slot.copy)do
    local card=spawnObjectData({data=copy,position=packPos,rotation=cardRot})
    if not spread then
     card.setPosition(cardPos())
     addToPack(card)
    else card.setPositionSmooth(cardPos(),false,false)end
    curCard=curCard+1
   end
  elseif slot.sloType=="energy"and energy==1 then chooseCard(slot,leaving)end
  total=total+slot.size
 end
 if pulls then pulls.use_hands=true end
 leaving.destruct()
 self.destruct()
end
