from pathlib import Path
import json,sys,copy,hashlib
import numpy as np
from scipy.ndimage import label
from PIL import Image
sys.path.insert(0,str(Path('/workspace/Yume-WordEnd/tools')))
import hd2d_sheets as sh
ROOT=Path('/workspace/Yume-WordEnd'); BASE=ROOT/'assets/source/section12'
report={}
def restore_source(ident,suffix,anim,target):
 stem=ident+suffix;p=BASE/ident/(stem+'.pr4'); d=json.loads(Path(str(p)+'.json').read_text()); im=Image.open(str(p)+'.png').convert('RGBA')
 out=[]
 for f in d['animations'][anim]['images']:
  c=sh.crop(im,f);top=sh.top_of(c);ratio=target/(f[5]-top)
  sz=(max(1,round(c.width*ratio)),max(1,round(c.height*ratio)))
  c=c.resize(sz,Image.Resampling.NEAREST);ax=round(f[4]*ratio);ay=round(f[5]*ratio)
  # Correct integer NN rounding in the anchor, without touching source artwork.
  ay=sh.top_of(c)+target
  out.append((c,[ax,ay]))
 return out

def generated(ident,rows,target):
 im=Image.open(BASE/ident/'generated_dialogues.png').convert('RGBA');a=np.array(im); lab,n=label(a[:,:,3]>=128,np.ones((3,3)));counts=np.bincount(lab.ravel());components=[]
 for k in range(1,n+1):
  if counts[k]<1000:continue
  yy,xx=np.where(lab==k);components.append((yy.min(),xx.min(),k, (xx.min(),yy.min(),xx.max()+1,yy.max()+1)))
 # sort by grid row then column, rather than inaccurate top hair positions.
 components.sort(key=lambda v:(int((v[3][1]+v[3][3])/2/(im.height/rows)),v[3][0]))
 assert len(components)==rows*2,(ident,len(components))
 outputs=[]
 for i,(_,_,k,box) in enumerate(components):
  ar=a[box[1]:box[3],box[0]:box[2]].copy();ar[:,:,3]=np.where(lab[box[1]:box[3],box[0]:box[2]]==k,255,0)
  c=Image.fromarray(ar);c.save(BASE/ident/f'generated_pose_{i}.png')
  anchor=sh.compute_anchor(c,'dark',axis=True);top=sh.top_of(c);ratio=target/(anchor[1]-top)
  c=c.resize((round(c.width*ratio),round(c.height*ratio)),Image.Resampling.NEAREST)
  # 64 discrete art colours, no dithering and keep binary alpha separately.
  alpha=c.getchannel('A'); rgb=c.convert('RGB').quantize(colors=64,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGB'); c=rgb.convert('RGBA');c.putalpha(alpha)
  anc=[round(anchor[0]*ratio),sh.top_of(c)+target]
  c.save(BASE/ident/f'dialogue_{i}.png');outputs.append((c,anc))
 return outputs

def replace(ident,suffix,replacements):
 stem=ident+suffix;root=ROOT/'assets/characters'/ident;path=root/(stem+'.json');d=json.loads(path.read_text());before=copy.deepcopy(d);im=Image.open(root/(stem+'.png')).convert('RGBA')
 # Append corrected rows to preserve exact original pixel rectangles and metadata of every other animation.
 new_w=max([im.width]+[sum(c.width+4 for c,_ in parts)-4 for parts in replacements.values()]);new_h=im.height+sum(max(c.height for c,_ in parts)+4 for parts in replacements.values())
 canvas=Image.new('RGBA',(new_w,new_h));canvas.paste(im,(0,0));y=im.height+4
 for anim,parts in replacements.items():
  if anim not in d['animations']:d['animations'][anim]={'ips':6,'boucle':True,'images':[]}
  frames=[];x=0
  for c,anchor in parts:
   canvas.paste(c,(x,y));frames.append([x,y,c.width,c.height,*anchor]);x+=c.width+4
  d['animations'][anim]['images']=frames;y+=max(c.height for c,_ in parts)+4
 d['planche']=list(canvas.size)
 canvas.save(root/(stem+'.png'));sh.write_json(path,d)
 unchanged={}
 for anim,meta in before['animations'].items():
  if anim in replacements:continue
  assert meta==d['animations'][anim],(stem,anim,'metadatachanged')
  for i,f in enumerate(meta['images']):
   old=sh.crop(im,f).tobytes();new=sh.crop(canvas,f).tobytes();assert old==new,(stem,anim,i)
  unchanged[anim]=len(meta['images'])
 report[stem]={'changed':{a:[sh.standing_height(c,[0,0,c.width,c.height,*anc]) for c,anc in p] for a,p in replacements.items()},'unchanged_frames':unchanged,'png_bytes':(root/(stem+'.png')).stat().st_size}

for ident,target in [('nygglatho',178),('cat_waiter',158),('snack_vendor',154),('ferryman',163)]:
 repl={'parle':restore_source(ident,'','parle',target)}
 if ident in ['cat_waiter','snack_vendor']:repl['marche']=restore_source(ident,'','marche',target)
 replace(ident,'',repl)
 if ident in ['cat_waiter','snack_vendor']:
  d=json.loads((ROOT/'assets/characters'/ident/(ident+'_back.json')).read_text());im=Image.open(ROOT/'assets/characters'/ident/(ident+'_back.png'));target_back=round(sh.standing_height(sh.crop(im,d['animations']['repos']['images'][0]),d['animations']['repos']['images'][0]));replace(ident,'_back',{'marche':restore_source(ident,'_back','marche',target_back)})
for ident,rows,target in [('willem',3,168),('nephren',2,125)]:
 parts=generated(ident,rows,target)
 for row,suffix in enumerate(['','_front','_back'][:rows]):replace(ident,suffix,{'parle':parts[row*2:row*2+2]})
(BASE/'dialogues-validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
