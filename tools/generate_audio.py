import wave, math, array, random
from pathlib import Path
out=Path(__file__).resolve().parents[1]/'assets'/'audio';out.mkdir(parents=True,exist_ok=True);sr=22050
random.seed(14)
def save(name,a):
 with wave.open(str(out/(name+'.wav')),'wb') as w:
  w.setnchannels(1);w.setsampwidth(2);w.setframerate(sr)
  w.writeframes(array.array('h',(int(max(-.95,min(.95,x))*32767) for x in a)).tobytes())
def fx(name,duration,f0,f1,noise=0):
 n=int(sr*duration);phase=0;a=[]
 for i in range(n):
  t=i/n;phase+=2*math.pi*(f0+(f1-f0)*t)/sr
  env=min(1,t*30)*(1-t)**1.6
  a.append(env*(.48*math.sin(phase)+noise*random.uniform(-1,1)))
 save(name,a)
for args in [('shot',.12,1200,160,.04),('jump',.22,220,850,0),('dash',.23,720,100,.25),('hit',.12,320,70,.35),('hurt',.28,170,40,.3),('pickup',.4,520,1400,0),('victory',1.0,330,990,0),('alarm',.45,650,270,0),('enemy_shot',.15,450,130,.07)]:fx(*args)
for name,tempo,notes in [('station',108,[45,52,57,60,43,50,55,59]),('boss',144,[40,47,52,55,41,48,53,56])]:
 beat=60/tempo;duration=beat*32;n=int(sr*duration);a=[0.0]*n
 def tone(start,length,freq,vol):
  begin=int(start*sr);count=int(length*sr)
  for j in range(min(count,n-begin)):
   t=j/sr;env=min(1,t/.015)*max(0,1-j/count)**1.3
   a[begin+j]+=vol*env*(math.sin(2*math.pi*freq*t)+.18*math.sin(4*math.pi*freq*t))
 for step in range(64):
  note=notes[(step//8)%len(notes)]+[0,12,7,12][step%4]
  tone(step*beat/2,beat*.42,440*2**((note-69)/12),.18)
 for b in range(32):
  tone(b*beat,beat*.75,440*2**((notes[(b//4)%len(notes)]-12-69)/12),.22)
  begin=int(b*beat*sr)
  for j in range(min(int(.1*sr),n-begin)):
   t=j/sr;a[begin+j]+=.24*math.sin(2*math.pi*(65*t-180*t*t))*math.exp(-t*35)
  if b%2:
   for j in range(min(int(.06*sr),n-begin)):
    a[begin+j]+=.1*random.uniform(-1,1)*(1-j/(.06*sr))
 save(name,a)
print('11 archivos WAV originales creados')
