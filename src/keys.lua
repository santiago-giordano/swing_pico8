-- ===== swing keys =====
-- bajo, lead y acordes por grados
-- de la escala de la cancion
pbit,mbit,patb,pats=2,128,128,24
function lstr()
 rn=split(tx("baj,led,aco","bas,led,chd"))
 wn=split(tx("tri,sier,sie2,cuad,puls,orga,fase","tri,saw,saw2,sqr,puls,orgn,phas"))
end
wid={0,1,2,3,4,5,7}
defk={
"1010000500000000708000004040000800000f0000500000",
"7070000300000000200000003030000000000100002f0000"}
last={1,5,1}
lit={}
kx,ky=0,0

function initpart()
 if gd(239)&128==0 then
  for p=1,2 do
   local s=defk[p]
   for k=0,47 do
    fs(128+(p-1)*24,k,4,tonum("0x"..sub(s,k+1,k+1)))
   end
  end
  local d={0,0,6,4,70, 0,2,4,66,64, 5,2,3,25,74, 133}
  for i=1,16 do sd(223+i,d[i]) end
 end
end

-- ---- parametros ----
function kp(r,j) return gd(224+r*5+j) end
function kfx(r,b,w) return kp(r,3)>>b&(1<<w)-1 end

-- grado (1-14) a pitch
function deg(d,o)
 local s=scl[gd(5)+1]
 local p=gd(4)+12*o+s[(d-1)%7+1]+12*((d-1)\7)
 while (p>63) p-=12
 return p
end

-- nombre del acorde sobre grado c
function cname(c)
 local s=scl[gd(5)+1]
 local function iv(k) return (s[(c+k-1)%7+1]-s[c])%12 end
 local q=({["4711"]="maj7",["3710"]="m7",["4710"]="7",["3610"]="m7b5"})[iv(2)..iv(4)..iv(6)] or ""
 return notes[(gd(4)+s[c])%12+1]..q
end

-- ---- escritura de sfx ----
function wnote(sl,i,p,w,v,f)
 local a,x=0x3200+sl*68+i*2-2,p+w*64+v*512+(f or 0)*4096
 poke(a,x%256,x\256)
end

-- arma el sonido de la pista r
-- en el slot sl. modo: 0 nota,
-- 1 release
function wsfx(sl,r,p,rel)
 local w,lv=wid[kp(r,0)+1],kp(r,2)
 local fx=kfx(r,6,1)*2
 local sp,l0,l1=4,0,0
 local e=0
 for i=1,32 do
  local v=0
  if rel then
   v=max(0,lv-i+1)
  elseif r==0 then
   sp=3
   v=i<=10 and lv or max(0,lv-(i-10)\3)
  elseif r==1 then
   local ec=gd(239)&3
   if ec>0 then
    sp=max(1,flr(45/gd(2)*120/11))
    e=flr(45/gd(2)*120/sp+.5)
   end
   if i<=8 then v=max(0,lv-(i-1)\2)
   elseif e>0 and i>e and i<=e+4 then v=max(1,lv\2-(i-e-1)\2)
   elseif ec>1 and e>0 and i>2*e and i<=2*e+3 then v=max(1,lv\4)
   end
  else
   v=gd(239)&4>0 and min(lv,i) or lv
   l0,l1=8,16
  end
  wnote(sl,i,p,w,v,v>0 and fx or 0)
 end
 local f=kfx(r,4,2)*8+kfx(r,0,2)*24+kfx(r,2,2)*72
 poke(0x3200+sl*68+64,f,sp,l0,l1)
end

-- ---- notas ----
function chordp(c)
 local o=kp(2,1)
 local lo=gd(4)+12*o+3
 local p3,p7=deg(c+2,o),deg(c+6,o)
 while (p3<lo) p3+=12
 while (p3>=lo+12) p3-=12
 while (p7<lo) p7+=12
 while (p7>=lo+12) p7-=12
 return p3,p7
end

function play(r,v)
 if v==15 then
  for k=r,r+tonum(r==2) do
   if (pl[k]) wsfx(k,r,pl[k],true) sfx(k,k)
  end
  lit[r]=nil
  return
 end
 if r<2 then
  local p=deg(v,kp(r,1))
  -- parlante: el bajo por debajo de
  -- mi3 (~160 hz) sube una octava
  if (r==0 and gd(239)&32<1 and p<16) p+=12
  wsfx(r,r,p) sfx(r,r)
  pl[r]=p lit[r]={p}
 else
  local a,b=chordp(v)
  wsfx(2,2,a) wsfx(3,2,b)
  sfx(2,2) sfx(3,3)
  pl[2],pl[3]=a,b
  lit[2]={a,b,deg(v,kp(2,1)-1)}
  chord=cname(v)
 end
end
pl={}

-- ---- secuencia ----
function trig(i,p,s)
 for r=0,2 do
  local v=fg(128+p*24,s*3+r,4)
  if v>0 then
   push(i+lead+max(-lead,swo(gd(3),s)+sgd(228+r*5)*5.5125+hum(5+r,s)),{r=r,v=v})
  end
 end
end

function fire(e)
 if e.ck then
  for i=1,32 do wnote(4,i,i<3 and (e.a and 46 or 41) or 0,4,i<3 and 5 or 0) end
  poke(0x3200+4*68+64,0,2,0,0)
  sfx(4,3)
 else play(e.r,e.v) end
end

kd=0
function onstart() kd=0 end
function onstop()
 for k=0,3 do sfx(-1,k) end
 lit={}
end
function onend() play(2,15) play(0,15) play(1,15) end
function onstep() end

-- ---- paginas ----
function cellch(r,v)
 if (v==15) return "x"
 if (r==2) return v
 return (v-1)%7+1
end

function gridpage()
 local p={n=tx("patron","pattern"),h=tx("o:nota o+^v:grado o+<>:rota","o:note o+^v:degree o+<>:rotate")}
 p.mv=function(dx,dy) kx=(kx+dx)%16 ky=mid(0,2,ky+dy) end
 local function at() return 128+ep*24,kx*3+ky end
 p.act=function()
  local b,k=at()
  local v=fg(b,k,4)
  if v==0 then
   v=last[ky+1] play(ky,v)
  else
   last[ky+1]=v v=0
  end
  fs(b,k,4,v)
 end
 p.adj=function(dx,dy)
  local b,k=at()
  if dy~=0 then
   local v,mx=fg(b,k,4),ky==2 and 7 or 14
   if (v==15) v=mx+1
   v=mid(1,mx+1,v+dy)
   if (v>mx) v=15
   fs(b,k,4,v) last[ky+1]=v play(ky,v)
  end
  if dx~=0 then
   local q={}
   for s=0,15 do q[s]=fg(b,s*3+ky,4) end
   for s=0,15 do fs(b,s*3+ky,4,q[(s-dx)%16]) end
  end
 end
 p.draw=function()
  local b,cc=128+ep*24,{12,9,14}
  for r=0,2 do
   local y=47+r*14
   print(rn[r+1],1,y+4,ky==r and 7 or 6)
   for s=0,15 do
    local x,v=14+s*7,fg(b,s*3+r,4)
    local c=s%4==0 and 2 or 1
    if v>0 then
     c=v==15 and 5 or cc[r+1]
     if (r<2 and v>7 and v<15) c=r==0 and 3 or 10
    end
    rectfill(x,y,x+5,y+11,c)
    if (v>0) print(cellch(r,v),x+1,y+4,0)
   end
  end
  rect(13+kx*7,46+ky*14,20+kx*7,59+ky*14,7)
  if playing and cur>=0 and curp==ep then
   rectfill(14+cur*7,90,19+cur*7,91,11)
  end
  local v=fg(b,kx*3+ky,4)
  local s="-"
  if v==15 then s=tx("corte","cut")
  elseif v>0 then
   if ky==2 then s=tx("acorde ","chord ")..cname(v)
   else
    local pp=deg(v,kp(ky,1))
    s=tx("grado ","degree ")..v.." = "..notes[pp%12+1]..(pp\12+2)
   end
  end
  print(s,2,95,6)
  print(sub(scn[gd(5)+1],1,6),102,95,12)
  if (chord and playing) print(tx("suena ","playing ")..chord,2,103,13)
 end
 return p
end

function soundpage()
 local its={}
 local rows=split(tx("onda,octava,nivel,reverb,filtro,detune,wobble,nudge,eco/at/parl","wave,octave,level,reverb,filter,detune,wobble,nudge,echo/at/spk"))
 for r=0,2 do
  local x=44+r*28
  local function fxi(b,w,mx)
   return {v=function() return kfx(r,b,w) end,a=function(d)
    local f=kp(r,3)
    local v=mid(0,mx,(f>>b&(1<<w)-1)+d)
    sd(227+r*5,f&~((1<<w)-1<<b)|v<<b) end}
  end
  local def={
   {v=function() return wn[kp(r,0)+1] end,a=function(d) sd(224+r*5,(kp(r,0)+d)%7) end},
   {v=function() return kp(r,1) end,a=function(d) clampset(225+r*5,d,0,3) end},
   {v=function() return kp(r,2) end,a=function(d) clampset(226+r*5,d,1,7) end},
   fxi(0,2,2),fxi(2,2,2),fxi(4,2,2),fxi(6,1,1),
   {v=function() return sgd(228+r*5) end,a=function(d) clampset(228+r*5,d*2,0,124) end}}
  if (r==0) add(def,{v=function() return gd(239)&32<1 and tx("si","on") or "no" end,a=function() sd(239,gd(239)^^32) end})
  if (r==1) add(def,{v=function() return gd(239)&3 end,a=function(d) local f=gd(239) sd(239,f&0xfc|mid(0,2,(f&3)+d)) end})
  if (r==2) add(def,{v=function() return gd(239)&4>0 and tx("len","slow") or tx("rap","fast") end,a=function() sd(239,gd(239)^^4) end})
  for j,t in pairs(def) do
   t.x,t.y,t.d,t.r=x,53+(j-1)*7,soundcell,r
   t.k=function() play(r,r==2 and 1 or 5) end
   add(its,t)
  end
 end
 return ipage(tx("sonido","sound"),its,function()
  for j=1,#rows do print(rows[j],2,53+(j-1)*7,5) end
 end,tx("o:escuchar  o+<>:ajustar","o:listen  o+<>:adjust"))
end

function soundcell(t,s)
 if (t.y==53) print(rn[t.r+1],t.x+8,46,s and 9 or 13)
 local v=tostr(t.v())
 if (s) rectfill(t.x,t.y-1,t.x+25,t.y+5,4)
 print(v,t.x+13-#v*2,t.y,s and 7 or 6)
end

-- ---- escena: teclado ----
function scene()
 rectfill(0,9,127,33,0)
 fillp(0b1010010110100101.1)
 rectfill(0,9,127,33,1)
 fillp()
 local hl={}
 local cc={12,9,14}
 for r=0,2 do
  if lit[r] then
   for p in all(lit[r]) do hl[p%24]=cc[r+1] end
  end
 end
 local wk={0,2,4,5,7,9,11}
 rectfill(3,11,102,32,4)
 for i=0,13 do
  local p=wk[i%7+1]+i\7*12
  local x=4+i*7
  rectfill(x,12,x+5,31,hl[p] or 7)
 end
 for i=0,13 do
  local n=i%7
  if n~=2 and n~=6 then
   local p=wk[n+1]+1+i\7*12
   local x=8+i*7
   rectfill(x,12,x+3,23,hl[p] or 0)
  end
 end
 -- cassette
 rectfill(106,14,125,30,2)
 rectfill(108,16,123,24,0)
 local a=playing and t() or 0
 for c in all({111,120}) do
  circfill(c,20,3,6)
  pset(c+cos(a)*2,20+sin(a)*2,0)
 end
 rectfill(110,26,121,28,1)
end

-- ---- principal ----
function _init()
 lofipal()
 pcminit()
end
function mkpages()
 pages={gridpage(),soundpage(),songpage()}
 pg=1
end

function _update60()
 pcmcheck()
 if not song then
  pickupdate()
  return
 end
 -- reloj: un cuadro por frame,
 -- corregido de a poco por lo que
 -- consumio el pcm (llega en
 -- bloques; seguirlo crudo mete
 -- saltos de 2-3 frames)
 local n=91.875
 if pcmok then
  local q=pcmneed(768)
  memset(0x4300,128,q)
  if (q>0) serial(0x808,0x4300,q)
  kd+=q
  n=max(0,n+(kd-n)*.1)
  kd-=n
 end
 if (playing) advance(n)
 inp()
 uitick()
 savetick()
end

function _draw()
 if not song then
  pickdraw("swing keys",tx("bajo, lead y acordes","bass, lead and chords"))
  return
 end
 cls(0)
 header("swing keys")
 scene()
 tabs()
 pages[pg].draw()
 statusline()
 footer(pages[pg].h)
end
