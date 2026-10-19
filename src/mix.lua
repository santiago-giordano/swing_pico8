-- ===== swing mix =====
-- reproduce la cancion con los 3
-- motores: beats y noise por pcm,
-- keys por los canales de chip.
-- nivel/mute/solo por stem en los
-- bytes 14-15 de la cancion
pbit,mbit,patb,pats,ro=0,0,0,1,true
function lstr()
 stn=split(tx("beats,keys,ruido","beats,keys,noise"))
end

-- ---- mezcla ----
-- 14: b0-2 beats b3-5 keys b7 init
-- 15: b0-2 noise b3-5 mute b6-7 solo
function initpart()
 if (gd(14)&128==0) sd(14,182) sd(15,5)
 renderall()
end
function mlv(k)
 return k==2 and gd(15)&7 or gd(14)>>k*3&7
end
function mset(k,v)
 if k==2 then sd(15,gd(15)&~7|v)
 else sd(14,gd(14)&~(7<<k*3)|v<<k*3) end
end
-- nivel efectivo 0-1
function ef(k)
 local so=gd(15)\64
 if (so>0 and so~=k+1 or gd(15)&8<<k>0) return 0
 return mlv(k)/7
end

-- ---- motor beats (pcm) ----
velg={.35,.65,1}
tunes={.84,.89,.94,1,1.06,1.12,1.19}
kits={
"1500,160,50,90,700,1,.08,80,.5,0,.4,1300,230,185,200,250,.45,.85,500,.6,.3,0,400,900,750,100,70,.6,.35,60,1,1,0,300,0,0,1,1,0,.7,60,1,1,0,1500,0,0,1,1,0,.6,500,.9,1,0",
"1800,120,44,140,1000,1,.04,60,.3,0,.15,1100,210,180,300,320,.7,.45,380,.35,.1,0,350,700,650,120,90,.8,.2,50,.7,.6,0,260,0,0,1,1,0,.5,50,.6,1,0,1400,0,0,1,1,0,.45,420,.6,1,0",
"1200,190,58,60,450,1,.15,60,.7,0,.6,1000,250,190,150,200,.35,1,420,.9,.5,.2,300,1300,1100,80,50,.5,.5,40,1,1,.2,260,0,0,1,1,0,.9,45,1,1,.1,1300,0,0,1,1,0,.8,450,1,1,0"}
vb,vn,vp,vg={},{},{},{}
lpf,ri,rj,rb,rc=0,1,1,{},{}
for i=1,337 do rb[i]=0 rc[i]=0 end

function syn(n,f0,f1,pd,ad,ta,na,nd,nc,hp,ck)
 local b,ph,a,an,p,nl,pn={},0,1,1,1,0,0
 local ka,kn,kp=1-.693/ad,1-.693/nd,1-.693/pd
 for i=1,n do
  ph+=(f1+(f0-f1)*p)/sr
  local x=rnd(2)-1
  nl+=(x-nl)*nc
  local v=sin(ph)*a*ta+(nl*(1-hp)+(nl-pn)*hp*2)*an*na
  pn=nl
  if (i<12) v+=x*ck
  if (i>n-60) v*=(n-i)/60
  b[i]=v
  a*=ka an*=kn p*=kp
 end
 return b
end

function renderall()
 vp={}
 local k=split(kits[gd(123)+1])
 local tu=tunes[(gd(127)>>2&7)+1]
 for t=1,5 do
  local q={unpack(k,(t-1)*11+1,t*11)}
  q[2]*=tu q[3]*=tu
  vb[t]=syn(unpack(q))
  vn[t]=q[1]
 end
 if gd(127)&32<1 then
  local b,ph,a,f=vb[1],0,1,700*tu
  for i,v in ipairs(b) do
   ph+=f/sr f=max(300*tu,f*.997) a*=.993
   v+=sin(ph)*a
   b[i]=v*5/(1+abs(v*4))
  end
 end
end

-- ---- motor keys (chip) ----
wid={0,1,2,3,4,5,7}
pl,kq={},{}
function kp(r,j) return gd(224+r*5+j) end
function kfx(r,b,w) return kp(r,3)>>b&(1<<w)-1 end
function deg(d,o)
 local s=scl[gd(5)+1]
 local p=gd(4)+12*o+s[(d-1)%7+1]+12*((d-1)\7)
 while (p>63) p-=12
 return p
end
function wnote(sl,i,p,w,v,f)
 local a,x=0x3200+sl*68+i*2-2,p+w*64+v*512+(f or 0)*4096
 poke(a,x%256,x\256)
end
function wsfx(sl,r,p,rel)
 local w,lv=wid[kp(r,0)+1],flr(kp(r,2)*ef(1)+.5)
 local fx=kfx(r,6,1)*2
 local sp,l0,l1,e=4,0,0,0
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
  if (lv==0) v=0
  wnote(sl,i,p,w,v,v>0 and fx or 0)
 end
 poke(0x3200+sl*68+64,kfx(r,4,2)*8+kfx(r,0,2)*24+kfx(r,2,2)*72,sp,l0,l1)
end
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
  return
 end
 mtr[2]=max(mtr[2],ef(1))
 if r<2 then
  local p=deg(v,kp(r,1))
  if (r==0 and gd(127)&32<1 and p<16) p+=12
  wsfx(r,r,p) sfx(r,r)
  pl[r]=p
 else
  local a,b=chordp(v)
  wsfx(2,2,a) wsfx(3,2,b)
  sfx(2,2) sfx(3,3)
  pl[2],pl[3]=a,b
 end
end

-- ---- motor noise (pcm) ----
nl={}
ca,rum,hy,ry,dpa,dpf,dpp,fy,fca,fb,my,cc,cp,cph=0,0,0,0,0,0,0,0,0,0,0,0,999,0
fph,rph,wph,nlp,dkv,fgn,fgt,ib,tp,tph,ns=0,0,0,0,1,1,1,0,0,0,0
ckn,ckp,ckf,ia=0,0,0,0
-- nq=2: ruido a media tasa si
-- no alcanza la cpu
nq,cpa=1,0

function bars()
 local tb,cb=0,0
 for j=0,gd(7)-1 do
  local r=1<<(gd(16+j)>>4&3)
  if (j<ci) cb+=r
  tb+=r
 end
 return cb+rep,tb
end

-- ---- motor comun ----
-- idl: ver gen de swing_beats
idl=0
function flush()
 for i=1,337 do rb[i]=0 rc[i]=0 end
 lpf=0
end
function gen(n)
 for i=1,6 do nl[i]=gd(239+i) end
 local l1,l2,l3,l4,l5,l6=unpack(nl)
 local ntc,nmv=(gd(248)+1)/8,gd(253)/5
 local gb,gn,q=ef(0)*100,ef(2),nq/sr
 local pc,pq2,mb,mn=l1*.0002*nq,l1*.00001*nq,0,0
 if (gn==0) ns=0
 for i=0,n-1 do
  if (i>=nxt) service(i)
  local o=0
  if gb>0 then
   local s,on=0
   for t=1,5 do
    local p=vp[t]
    if p then
     s+=vb[t][p]*vg[t]
     vp[t]=p<vn[t] and p+1 or nil
     on=1
    end
   end
   idl=on and 0 or min(idl+1,4001)
   if (idl==4000) flush()
   if idl<4000 then
    lpf+=(s-lpf)*tc
    s=lpf*drv
    s=s/(1+abs(s)*.5)
    local a,c=rb[ri],rc[rj]
    rb[ri]=s+a*.5 rc[rj]=s+c*.45
    ri=ri%233+1 rj=rj%337+1
    s+=(a+c)*rm
    if (cr>0) s=flr(s*cr+.5)/cr
    o=s*gb mb=max(mb,abs(o))
   end
  end
  if gn>0 and i%nq==0 then
   local s=0
   if l1>0 then
    if rnd()<pc then ca=(rnd(25)+12)*sgn(rnd(2)-1)
    elseif rnd()<pq2 then ca=(rnd(30)+50)*sgn(rnd(2)-1) end
    rum+=(rnd(2)-1-rum)*.02
    s+=ca*l1*.25+rum*l1*8
    ca*=.5
   end
   if l2>0 then
    hy+=(rnd(2)-1-hy)*.3
    s+=hy*l2*4*(1+sin(fph)*.2)
   end
   if l3>0 then
    local r=rnd(2)-1
    s+=(r-ry)*l3*1.6*(.75+sin(rph)*.25)
    ry=r
    if rnd()<l3*.001*nq then
     dpa=rnd(8)+4 dpf=(900+rnd(1400))*q
    end
    dpp+=dpf
    s+=sin(dpp)*dpa
    dpa*=.92
   end
   if l4>0 then
    fy+=(rnd(2)-1-fy)*.07
    s+=fy*l4*10*(.6+.4*sin(fph*.37))
    if (rnd()<l4*.0004*nq) fb=flr(rnd(5))+2
    if fb>0 and rnd()<.015 then
     fca=(rnd(40)+20)*sgn(rnd(2)-1) fb-=1
    end
    s+=fca*l4*.3
    fca*=.35
   end
   if l5>0 then
    local w=.55+.35*sin(wph)+.1*sin(wph*2.3)
    my+=(rnd(2)-1-my)*(.03+.3*w)
    s+=my*l5*16*w
   end
   if l6>0 then
    cc-=nq
    if (cc<=0) cc=flr(3800+rnd(3500)) cp=0
    cp+=nq
    cph+=.39*nq
    if (cp<420 and cp%140<85) s+=sin(cph)*l6*2.2
   end
   fph+=6*q rph+=.3*q wph+=.13*q
   s*=dkv*fgn
   if tp>0 then
    tph+=55*q
    s+=sin(tph)*tp*60
    tp*=.997
    if (tp<.01) tp=0
   end
   if ib>0 then
    if (rnd()<.01) ia=(rnd(30)+15)*sgn(rnd(2)-1)
    s+=ia ia*=.5 ib-=1
   end
   dkv+=(1-dkv)*.0015*nq
   fgn+=(fgt-fgn)*.0004*nq
   nlp+=(s-nlp)*ntc
   ns=nlp*nmv*gn mn=max(mn,abs(ns))
  end
  o+=ns
  if ckn>0 then
   ckp+=ckf o+=sin(ckp)*70 ckn-=1
  end
  poke(0x4300+i,128+mid(-127,127,o))
 end
 if (wph>1000) wph-=1000 fph-=1000 rph-=1000
 mtr[1]=max(mtr[1],mb/127) mtr[3]=max(mtr[3],mn/127)
end

-- ---- secuencia ----
function trig(i,_,s)
 local e=gd(16+ci)
 local bp,kk=e&3,e>>2&3
 if (mode==0) bp,kk,e=ep,ep,0
 if e&64==0 then
  for t=0,4 do
   local v=fg(32+bp*20,t*16+s,2)
   if v>0 then
    local o=i+lead+max(-lead,boff(t,s)+hum(t,s))
    local f=fg(11,t,2)*55.125
    if (f>0 and v>1) push(max(i,o-f),{h=t+1,v=1})
    push(o,{h=t+1,v=v})
   end
  end
  if (gd(247)>0 and fg(32+bp*20,s,2)>0) push(i+lead+max(-lead,boff(0,s)),{dk=1})
 end
 if e&128==0 then
  for r=0,2 do
   local v=fg(128+kk*24,s*3+r,4)
   if (v>0) push(i+lead+max(-lead,swo(gd(3),s)+sgd(228+r*5)*5.5125+hum(5+r,s)),{r=r,v=v})
  end
 end
 local f=1
 if mode==1 then
  local b,tb=bars()
  local pos=b+s/16
  local fi,fo=gd(249),gd(250)
  if (fi>0) f=min(f,pos/fi)
  if (fo>0) f=min(f,(tb-pos)/fo)
  if (b==0 and s==0 and gd(251)>0) push(i+lead,{nd=1})
 end
 fgt=mid(0,1,f)
end

-- keys suena por chip: se demora
-- lo que tarda el pcm en salir
function fire(e,i)
 if e.h then
  vp[e.h],vg[e.h]=1,(gd(117+e.h)&7)/7*velg[e.v]
  if (e.h==4) vp[5]=nil
 elseif e.r then add(kq,{f=(bl+i)/91.875+.5,r=e.r,v=e.v})
 elseif e.ck then ckn,ckf=120,(e.a and 2200 or 1600)/sr
 elseif e.dk then dkv=1-gd(247)*.09
 elseif e.nd then ib=900 tp=1 tph=0
 end
end

function onstart() fgt=0 fgn=0 kq={} end
function onstop()
 for k=0,3 do sfx(-1,k) end
 fgt=0 kq={} vp={}
end
function onend()
 play(2,15) play(0,15) play(1,15)
 if (gd(252)>0) ib=1200 tp=.6 tph=0
 fgt=0
end
function onstep() end

function mkmenu()
 menuitem(1,tx("grabar mezcla","record mix"),function()
  if (playing) stopplay()
  startplay(true)
 end)
 menuitem(5,tx("cambiar cancion","change song"),function() extcmd("reset") end)
end

-- ---- pagina mezcla ----
mtr={0,0,0}
function mixpage()
 local its={}
 for k=0,2 do
  local x=6+k*42
  add(its,{x=x,y=50,j=k,d=fadcell,a=function(d) mset(k,mid(0,7,mlv(k)+d)) end})
  add(its,{x=x,y=96,j=k,d=btncell,l="m",kk=function() sd(15,gd(15)^^8<<k) end})
  add(its,{x=x+16,y=96,j=k,d=btncell,l="s",kk=function()
   local so=gd(15)\64
   sd(15,gd(15)&63|(so==k+1 and 0 or k+1)<<6) end})
 end
 -- parlante: el mismo ajuste de
 -- beats (byte 127 bit 5)
 local function spk() sd(127,gd(127)^^32) renderall() end
 add(its,{x=2,y=112,w=56,l=tx("parlante","speaker"),v=function() return gd(127)&32<1 and tx("si","on") or "no" end,a=spk,kk=spk})
 for t in all(its) do t.k=t.kk end
 return ipage(tx("mezcla","mix"),its,function()
  for k=0,2 do print(stn[k+1],6+k*42,46,ef(k)>0 and 6 or 5) end
  local s,c=tx("loop ","loop ")..split("a,b,c,d")[ep+1],12
  if (mode==1) s=playing and tx("bloque ","block ")..(curc+1).."/"..gd(7) or tx("cadena","song")
  if rec and playing then
   s,c=cnt>0 and tx("conteo...","count-in...") or tx("rec bloque ","rec block ")..(curc+1).."/"..gd(7),8
  elseif done and done>0 then s,c=tx("listo: corta la grabacion","done: stop recording"),10 end
  if (pcmok==false) s,c=tx("sin pcm: usa pico-8 oficial","no pcm: use official pico-8"),8
  print(s,2,105,c)
  if (nq>1) print(tx("ruido 1/2","noise 1/2"),88,112,8)
  cpu(96,105)
 end,tx("o+^v:nivel  o:mute/solo","o+^v:level  o:mute/solo"))
end

-- el estado va en la pagina
function statusline() end

function fadcell(t,s)
 local l,on=mlv(t.j),ef(t.j)>0
 for j=0,6 do
  local y=86-j*5
  rectfill(t.x,y,t.x+10,y+3,j<l and (s and 9 or on and 13 or 2) or 1)
 end
 -- medidor
 local m=min(1,mtr[t.j+1])
 rectfill(t.x+14,56,t.x+17,89,1)
 if (m>0) rectfill(t.x+14,89-m*33,t.x+17,89,m>.9 and 8 or 11)
 print(l,t.x+24,82,s and 9 or 6)
end

function btncell(t,s)
 local b=gd(15)
 local on=t.l=="m" and b&8<<t.j>0 or t.l=="s" and b\64==t.j+1
 rectfill(t.x,t.y,t.x+12,t.y+8,on and (t.l=="m" and 8 or 10) or 1)
 rect(t.x,t.y,t.x+12,t.y+8,s and 7 or 2)
 print(t.l,t.x+5,t.y+2,on and 0 or 6)
end

-- ---- escena: consola ----
function scene()
 rectfill(0,9,127,33,0)
 fillp(0b1010010110100101.1)
 rectfill(0,9,127,33,1)
 fillp()
 rectfill(8,11,119,32,4)
 for k=0,2 do
  local x=12+k*36
  rectfill(x,13,x+31,30,0)
  clip(x,13,32,18)
  local a=.38-min(1,mtr[k+1])*.26
  circ(x+16,30,13,2)
  line(x+16,30,x+16+cos(a)*12,30+sin(a)*12,9)
  print(sub(tx("bkr","bkn"),k+1,k+1),x+2,15,5)
  clip()
 end
end

-- ---- principal ----
function _init()
 lofipal()
 pcminit()
end
function mkpages()
 pages={mixpage(),songpage()}
 pg=1
end

function _update60()
 pcmcheck()
 if not song then
  pickupdate()
  return
 end
 if (mode0==nil) mode=1 mode0=1
 tc=(gd(124)+1)/8
 drv=1+gd(125)*.5
 rm=gd(126)*.07
 cr=({0,24,12,6})[(gd(127)&3)+1]
 for k=1,3 do mtr[k]*=.85 end
 if pcmok then
  local n=pcmneed(1024)
  if n>0 then
   bl=stat(108)
   gen(n)
   serial(0x808,0x4300,n)
   shift(n)
  end
 end
 for u in all(kq) do
  u.f-=1
  if (u.f<=0) del(kq,u) play(u.r,u.v)
 end
 -- cpu alta sostenida: ruido a
 -- media tasa hasta el proximo stop
 cpa=cpa*.95+stat(1)*.05
 if (playing and cpa>.88) nq=2
 if (not playing) nq=1 cpa=0
 inp()
 uitick()
 savetick()
end

function _draw()
 if not song then
  pickdraw("swing mix",tx("escucha los 3 juntos","hear all 3 together"))
  return
 end
 cls(0)
 header("swing mix")
 scene()
 tabs()
 pages[pg].draw()
 statusline()
 footer(pages[pg].h)
end
