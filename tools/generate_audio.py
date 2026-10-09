"""Original deterministic 16-bit mono wave synthesis, 22050Hz."""
import math, wave, struct, random
from pathlib import Path
out=Path(__file__).resolve().parents[1]/'assets/audio'
out.mkdir(parents=True,exist_ok=True)
rate=22050
rng=random.Random(4101)
def write(name,notes,duration,noise=0):
 samples=[]
 for i in range(int(rate*duration)):
  t=i/rate
  part=min(int(t/duration*len(notes)),len(notes)-1)
  f=notes[part]
  local=t%(duration/len(notes))
  env=max(0,1-local/(duration/len(notes)))**2
  v=(math.sin(t*f*math.tau)*.65+math.sin(t*f*2*math.tau)*.15 if f else 0)
  v=v*(1-noise)+(rng.random()*2-1)*noise
  samples.append(struct.pack('<h',int(v*env*11000)))
 with wave.open(str(out/(name+'.wav')),'wb') as w:
  w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(b''.join(samples))
for n,ns,d,no in [('ui',[660,880],.10,0),('deploy',[330,440,660],.24,0),('attack',[150,80],.10,.3),('hit',[90],.11,.7),('skill',[220,330,110],.4,.35),('victory',[523,659,784,1047],1.4,0),('defeat',[440,330,220],1.1,0),('menu',[262,330,392,330,294,349,440,349]*4,16,0),('battle',[196,196,294,247,220,196,330,294]*4,12,0)]: write(n,ns,d,no)
# Godot importer loops only music.
for n in ['menu','battle']:
 (out/(n+'.wav.import')).write_text('''[remap]\nimporter="wav"\ntype="AudioStreamWAV"\n\n[deps]\nsource_file="res://assets/audio/'''+n+'''.wav"\n\n[params]\nedit/loop_mode=2\nedit/loop_begin=0\nedit/loop_end=-1\n''')
