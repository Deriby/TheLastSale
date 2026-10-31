"""Extract CC0 Quaternius animation samples; never imports or modifies game meshes.
Usage: python tools/extract_motion_reference.py /path/to/AnimationLibrary_Godot_Standard.glb
Requires numpy and scipy for this offline authoring step only.
"""
from pathlib import Path
import hashlib,json,struct,sys
import numpy as np
from scipy.spatial.transform import Rotation, Slerp

source=Path(sys.argv[1]);data=source.read_bytes();size=struct.unpack_from('<I',data,12)[0]
gltf=json.loads(data[20:20+size]);buffer=data[28+size:];nodes=gltf['nodes']
parents={child:i for i,node in enumerate(nodes) for child in node.get('children',[])}
def array(index):
    a=gltf['accessors'][index];view=gltf['bufferViews'][a['bufferView']]
    width={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
    dtype={5126:'<f4',5123:'<u2',5125:'<u4',5121:'u1'}[a['componentType']]
    return np.frombuffer(buffer,dtype=dtype,count=a['count']*width,offset=view.get('byteOffset',0)+a.get('byteOffset',0)).reshape(a['count'],width)

def globals_at(animation=None,time=0):
    local=[dict(translation=n.get('translation',[0,0,0]),rotation=n.get('rotation',[0,0,0,1]),scale=n.get('scale',[1,1,1])) for n in nodes]
    if animation:
        for channel in animation['channels']:
            sampler=animation['samplers'][channel['sampler']];times=array(sampler['input'])[:,0];values=array(sampler['output']);path=channel['target']['path']
            if path=='rotation':value=Slerp(times,Rotation.from_quat(values))([min(float(times[-1]),max(float(times[0]),time))]).as_quat()[0]
            else:value=np.array([np.interp(time,times,values[:,axis]) for axis in range(values.shape[1])])
            local[channel['target']['node']][path]=value
    result={}
    def at(i):
        if i not in result:
            transform=np.eye(4);transform[:3,:3]=Rotation.from_quat(local[i]['rotation']).as_matrix()@np.diag(local[i]['scale']);transform[:3,3]=local[i]['translation']
            result[i]=at(parents[i])@transform if i in parents else transform
        return result[i]
    for i in range(len(nodes)):at(i)
    return result

bone_names=['DEF-hips','DEF-spine.001','DEF-spine.002','DEF-spine.003','DEF-neck','DEF-head']
for side in ['L','R']:
    bone_names += ['DEF-'+name+'.'+side for name in ['shoulder','upper_arm','forearm','hand','thigh','shin','foot']]
indices=[next(i for i,n in enumerate(nodes) if n['name']==name) for name in bone_names]
rest=globals_at();feet={}
# Foot contact is sampled from the reference mesh, including its toe articulation.
for side in ['L','R']:
    selected=[]
    for node in nodes:
        if 'mesh' not in node or 'skin' not in node:continue
        skin=gltf['skins'][node['skin']];bind=array(skin['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1)
        foot_indices=[k for k,index in enumerate(skin['joints']) if nodes[index]['name'] in ['DEF-foot.'+side,'DEF-toe.'+side]]
        for primitive in gltf['meshes'][node['mesh']]['primitives']:
            attributes=primitive['attributes'];v=array(attributes['POSITION']);j=array(attributes['JOINTS_0']).astype(int);w=array(attributes['WEIGHTS_0'])
            mask=np.sum(w*np.isin(j,foot_indices),axis=1)>.55
            selected.append((np.c_[v[mask],np.ones(np.sum(mask))],j[mask],w[mask],skin['joints'],bind))
    feet[side]=selected

def sole_height(pose,side):
    lowest=10.
    for vertices,joints,weights,skin,bind in feet[side]:
        matrices=np.array([pose[i]@bind[k] for k,i in enumerate(skin)])
        deformed=np.sum(np.einsum('nvij,nj->nvi',matrices[joints],vertices)*weights[:,:,None],axis=1)
        lowest=min(lowest,float(np.min(deformed[:,1])))
    return max(0.,lowest)

def packed(pose):
    return [[*[round(float(x),6) for x in pose[i][:3,3]],*[round(float(x),7) for x in Rotation.from_matrix(pose[i][:3,:3]).as_quat()]] for i in indices]
result={'source':'Quaternius Universal Animation Library Standard','license':'CC0-1.0','url':'https://quaternius.com/packs/universalanimationlibrary.html','source_glb_sha256':hashlib.sha256(data).hexdigest(),'bones':bone_names,'rest':packed(rest),'clips':{}}
for name in ['Idle_Loop','Walk_Loop','Walk_Formal_Loop','Sprint_Loop','Crouch_Fwd_Loop','Crouch_Idle_Loop','Idle_Talking_Loop']:
    animation=next(a for a in gltf['animations'] if a['name']==name);duration=max(float(array(s['input'])[-1,0]) for s in animation['samplers']);count=round(duration*30)
    samples=[];soles=[]
    for frame in range(count+1):
        pose=globals_at(animation,frame*duration/count);samples.append(packed(pose));soles.append([round(sole_height(pose,side),6) for side in ['L','R']])
    candidates=[]
    for side,k in [('L',0),('R',1)]:
        foot=bone_names.index('DEF-foot.'+side);z=np.array([s[foot][2] for s in samples]);speeds=-np.diff(z)*count;contact=np.array([s[k] for s in soles[:-1]])
        candidates.extend(speeds[(contact<.018)&(speeds>.3)])
    stride=float(np.median(candidates)) if candidates else 0
    result['clips'][name]={'length':round(duration,6),'frames':samples,'soles':soles,'stride':round(stride,5)}
    print(name,'frames',count+1,'stride',round(stride,3),'sole range',np.min(soles,axis=0),np.max(soles,axis=0))
output=Path(__file__).parent/'motion_reference'/'quaternius.json';output.write_text(json.dumps(result,separators=(',',':'))+'\n')
print(output,output.stat().st_size)
