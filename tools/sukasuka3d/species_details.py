"""Closed low-poly anatomy and reference-specific costume pieces for SukaSuka.

User scans p054–056, 061–062, 065–066 and 068–071. Blender coordinates
are Z up / front -Y. All pieces receive palette UVs and shared bone weights
through Builder's mesh, ellipsoid and tube methods. No image billboards.
"""
import math
import bpy


def decorate(b):
    s=b.spec; h=b.height; ident=s['id']; species=s.get('species','human')
    skin=s['skin_color']; dark=s['outfit_color']; gold=s['accent_color']; pale=s['white_color']; hair=s['hair_color']
    def remove(prefixes):
        for obj in list(b.parts):
            if any(obj.name.startswith(prefix) for prefix in prefixes):
                b.parts.remove(obj); bpy.data.objects.remove(obj,do_unlink=True)
    # Replace misleading default humanoid/anthro features before custom additions.
    if ident=='cyclops_doctor':
        remove(['EyeWhite','EyeIris','EyePupil','EyeSparkle','UpperEyelash','Brow','Blush','Nose','Smile'])
        b.ellipsoid('Cyclops_Central_Eye',(0,-.14*h,.848*h),(.047*h,.018*h,.048*h),pale,'head')
        b.ellipsoid('Cyclops_Orange_Iris',(0,-.158*h,.848*h),(.029*h,.009*h,.031*h),'#AB713F','head')
        b.ellipsoid('Cyclops_Dark_Pupil',(0,-.167*h,.848*h),(.013*h,.005*h,.017*h),'#30382C','head')
    if ident=='eboncandle_ancient':
        remove(['Face','Ear','Eye','UpperEyelash','Brow','Blush','Nose','Smile','Hair','Lapel','BellSkirt','HemTrim'])
    if ident=='frog_soldier':remove(['EyeWhite','EyeIris','EyePupil','EyeSparkle','UpperEyelash','Brow','Blush','Nose','Smile'])
    if ident=='bird_soldier':remove(['Beak','Nose','Smile'])
    if ident in ['bird_soldier','hawk_soldier']:remove(['Foot','Boot','Shin'])
    if species in ['cat','dog']:remove(['Muzzle','AnimalNose'])
    if species in ['cat','dog','reptile','rabbit']:remove(['Tail'])
    if ident=='limeskin':remove(['Crest','ReptileMuzzle'])
    if ident=='wolf_soldier':remove(['DogEar'])
    if s['outfit']=='uniform' or ident=='cyclops_doctor':remove(['Lapel','Button'])
    if ident=='godrey':remove(['HairCap','FringeLock'])
    def mesh(name,v,f,c,bone='chest'):
        return b.mesh(name,[(x*h,y*h,z*h) for x,y,z in v],f,c,bone)
    def ell(name,p,r,c,bone='chest'):
        return b.ellipsoid(name,tuple(x*h for x in p),tuple(x*h for x in r),c,bone)
    def tube(name,pts,r,c,bone='chest'):
        rr=[r]*len(pts) if isinstance(r,(int,float)) else r
        return b.tube(name,[tuple(x*h for x in p) for p in pts],[x*h for x in rr],c,bone)
    def prism(name,p,r,c,bone='head'):
        x,y,z=p; rx,ry,rz=r
        return mesh(name,[(x-rx,y-ry,z-rz),(x+rx,y-ry,z-rz),(x+rx,y+ry,z-rz),(x-rx,y+ry,z-rz),(x-rx,y-ry,z+rz),(x+rx,y-ry,z+rz),(x+rx,y+ry,z+rz),(x-rx,y+ry,z+rz)],[(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],c,bone)
    def cone(name,p,tip,r,c,bone='head',n=8):
        x,y,z=p; v=[(x+math.cos(i*math.tau/n)*r,y+math.sin(i*math.tau/n)*r,z) for i in range(n)]+[tip]
        return mesh(name,v,[tuple(reversed(range(n)))]+[(i,(i+1)%n,n) for i in range(n)],c,bone)
    def ring(name,p,r,c,bone='head',plane='xz',thick=.007,n=16):
        x,y,z=p;rx,ry=r; pts=[]
        for i in range(n+1):
            a=i*math.tau/n
            pts.append((x+rx*math.cos(a),y,z+ry*math.sin(a)) if plane=='xz' else (x,y+rx*math.cos(a),z+ry*math.sin(a)) if plane=='yz' else (x+rx*math.cos(a),y+ry*math.sin(a),z))
        return tube(name,pts,thick,c,bone)
    def ear(name,side,length=.115,width=.055,z=.88,c=skin,pointed=True):
        x=side*.14
        v=[(x,-.006,z-.026),(x+side*width,.012,z+length),(x+side*.078,.005,z+.025),(x,.058,z-.026),(x+side*width,.036,z+length),(x+side*.078,.05,z+.025)]
        mesh(name,v,[(0,1,2),(3,5,4),(0,3,4,1),(1,4,5,2),(2,5,3,0)],c,'head')
        mesh(name+'_Inner',[(x+side*.016,-.009,z),(x+side*width,.008,z+length*.84),(x+side*.064,.001,z+.029)],[(0,1,2)],'#D4A79E','head')
    def cape():
        for side in [-1,1]:
            x=side*.03
            v=[(x,.075,.625),(side*.18,.06,.61),(side*.26,.18,.14),(side*.09,.18,.11),(x,.09,.625),(side*.18,.076,.61),(side*.26,.197,.14),(side*.09,.197,.11)]
            mesh('Ebon_Split_Cape_'+str(side),v,[(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],'#676A56')
    def wings(color):
        for side in [-1,1]:
            # Solid membranes hidden by overlapping tapered feather meshes.
            v=[(side*.11,.073,.61),(side*.36,.13,.74),(side*.44,.14,.5),(side*.3,.12,.19),(side*.18,.1,.25),(side*.11,.093,.61),(side*.36,.15,.74),(side*.44,.16,.5),(side*.3,.14,.19),(side*.18,.12,.25)]
            mesh('Wing_Base_'+str(side),v,[(0,1,2,3,4),(5,9,8,7,6),(0,5,6,1),(1,6,7,2),(2,7,8,3),(3,8,9,4),(4,9,5,0)],color)
            for j in range(9):
                x=side*(.215+j*.022);z=.625-j*.038;length=.19+(.08*j/8)
                # Each flight feather has a convex cross-section and pointed tip.
                v=[(x-side*.024,.11,z),(x+side*.024,.11,z),(x+side*.035,.115,z-length*.7),(x+side*.006,.11,z-length),(x-side*.018,.11,z-length*.65),(x,.09,z-length*.45),(x,.137,z-length*.45)]
                mesh('Flight_Feather_'+str(side)+'_'+str(j),v,[(0,1,5),(1,2,5),(2,3,5),(3,4,5),(4,0,5),(1,0,6),(2,1,6),(3,2,6),(4,3,6),(0,4,6)],color if j%2 else ('#B08A4B' if ident=='hawk_soldier' else '#D3D3C7'))
    def birdfeet(col):
        for side in [-1,1]:
            bone='foot.'+('R' if side>0 else 'L');x=side*.072
            tube('Avian_Shin_'+str(side),[(x,0,.17),(x,0,.055)],.017,col,'lower_leg.'+('R' if side>0 else 'L'))
            for j in [-1,0,1]:
                tube('Avian_Toe_'+str(side)+str(j),[(x,0,.042),(x+j*.027,-.045,.019),(x+j*.041,-.102,.01)],[.011,.008,.0028],col,bone)
            tube('Avian_Rear_Toe_'+str(side),[(x,0,.034),(x,.047,.012)], [.009,.003],col,bone)
    def armband():
        bone='upper_arm.R';prism('Red_Knight_Armband',(.189,-.015,.549),(.04,.053,.016),'#B9573D',bone)
        for side in [-1,1]:
            mesh('Armband_Bow'+str(side),[(.232,-.04,.548),(.235+side*.035,-.045,.564),(.232+side*.033,-.037,.533)],[(0,1,2)],'#B9573D',bone)
    def whiskers():
        for side in [-1,1]:
            for j in [-1,0,1]:tube('Whisker_'+str(side)+str(j),[(side*.06,-.151,.775+j*.009),(side*.168,-.161,.784+j*.016)],.0016,'#393B3A','head')
    def buttons():
        for side in [-1,1]:
            for j in range(4):ell('Uniform_Button_'+str(side)+str(j),(side*.032,-.117,.57-j*.038),(.0045,.003,.0045),gold)
    if species=='cat':
        tube('Feline_Gray_Tail',[(0,.05,.37),(.04,.18,.32),(.14,.23,.28),(.21,.20,.34)],[.024,.020,.018,.009],skin,'hips')
    elif species=='dog' and ident=='wolf_soldier':
        tube('Wolf_Bushy_Tail',[(0,.045,.37),(.10,.16,.28),(.16,.22,.17),(.18,.22,.10)],[.036,.060,.047,.008],skin,'hips')
        cone('Wolf_Dark_Tail_Tip',(.17,.22,.145),(.184,.22,.08),.035,'#3A4138','hips')
    elif species=='rabbit':ell('Rabbit_Short_Tail',(0,.115,.352),(.042,.04,.045),skin,'hips')
    elif species=='reptile':
        tube('Dragon_Large_Tail',[(0,.057,.38),(0,.17,.32),(0,.245,.245),(0,.29,.16),(.018,.29,.13)],[.075,.063,.055,.028,.005],skin,'hips')
    if s['outfit']=='uniform' and species not in ['golem','armor'] and ident not in ['grick','knight_canine','knight_feline']:
        buttons()
        b.shell('Military_Long_Tunic',.31*h,.405*h,.145*h,.093*h,.129*h,.077*h,dark,'hips',16)
        ring('Military_Gold_Tunic_Hem',(0,0,.311),(.146,.094),gold,'hips',plane='xy',thick=.004)
        tube('Military_Gold_Front_Seam',[(0,-.117,.58),(0,-.107,.407),(0,-.10,.315)],.0035,gold)
        ring('Military_Gold_Standing_Collar',(0,0,.616),(.062,.048),gold,'neck',plane='xy',thick=.004)
        for side in [-1,1]:
            prism('Military_Epaulette'+str(side),(side*.144,-.026,.596),(.035,.036,.009),gold)
            tube('Military_Cuff_Gold'+str(side),[(side*.270,-.036,.443),(side*.292,-.029,.411)],.006,gold,'lower_arm.'+('R' if side>0 else 'L'))
    if species in ['cat','dog']:
        # Core provides anthropomorphic head. Add true muzzle, lips and whiskers.
        ell('Species_Muzzle',(0,-.133,.782),(.065,.039,.036), '#C5C2B2' if ident=='wolf_soldier' else skin,'head')
        ell('Species_Dark_Nose',(0,-.171,.801),(.020,.012,.014),'#282E28','head')
        tube('Species_Mouth',[(-.027,-.170,.771),(0,-.18,.766),(.027,-.170,.771)],.0025,'#3A3C32','head')
        if species=='cat':whiskers()
        if ident in ['wolf_soldier','knight_canine']:
            for side in [-1,1]:cone('Canine_Fang'+str(side),(side*.027,-.160,.776),(side*.027,-.16,.753),.006,pale)
    if ident=='grick':
        for side in [-1,1]:
            ear('Goblin_Point_Ear'+str(side),side,.014,.075,z=.835)
            cone('Goblin_Horn'+str(side),(side*.095,-.033,.939),(side*.111,-.025,.972),.018,skin)
            ell('Goggle_Lens'+str(side),(side*.053,-.117,.928),(.042,.014,.038),'#68758A','head')
            ring('Goggle_Frame'+str(side),(side*.053,-.134,.928),(.045,.041),'#242938',thick=.007)
            cone('Goblin_Tusk'+str(side),(side*.035,-.140,.775),(side*.038,-.153,.796),.007,pale)
            ell('Goblin_Earring'+str(side),(side*.187,-.018,.82),(.009,.009,.009),gold,'head')
            prism('Traveler_Vest_Front'+str(side),(side*.075,-.10,.525),(.057,.021,.1),dark,'chest')
            prism('Traveler_Pocket'+str(side),(side*.078,-.125,.503),(.034,.010,.03),'#574030')
            prism('Traveler_Belt_Pouch'+str(side),(side*.075,-.122,.388),(.040,.025,.040),dark,'hips')
        tube('Goggle_Straps',[(-.14,-.013,.926),(-.11,-.10,.928),(.11,-.10,.928),(.14,-.013,.926)],.01,'#2C3032','head')
    elif ident=='limeskin':
        ell('Dragon_Long_Muzzle',(0,-.136,.735),(.109,.098,.064),skin,'head')
        for side in [-1,1]:
            for j in range(3):
                cone('Crown_Dragon_Scale'+str(side)+str(j),(side*(.032+j*.04),.005,.914),(side*(.044+j*.06),.026,.987-j*.012),.026,'#829890')
            ear('Dragon_Cheek_Fin'+str(side),side,.078,.105,z=.85,c=skin)
            for j in range(3):tube('Red_Face_Mark'+str(side)+str(j),[(side*.012,-.223,.745-j*.018),(side*.060,-.217,.744-j*.014),(side*.098,-.196,.754-j*.01)],.0035,'#9D4E38','head')
            for j in range(5):ell('Dragon_Side_Braid'+str(side)+str(j),(side*.128,.026,.773-j*.019),(.012,.012,.016),'#DDD8C3','head')
            for j in range(3):prism('Dragon_Bracer_Plate'+str(side)+str(j),(side*(.234+j*.006),-.048,.466-j*.032),(.032,.018,.025),'#5F6B69','lower_arm.'+('R' if side>0 else 'L'))
        for j in range(7):
            z=.397-j*.035;y=.075+j*.027
            cone('Tail_Back_Scale'+str(j),(0,y,z),(0,y+.025,z+.023),.026,'#829890','hips')
    elif ident=='eboncandle_ancient':
        # Armored neck connects flattened helmet to torso without a floating gap.
        ell('Ebon_Armored_Gorget',(0,0,.745),(.072,.068,.108),'#505D5D','neck')
        for side in [-1,1]:
            tube('Ebon_Gorget_Turquoise_Ridge'+str(side),[(side*.043,-.061,.663),(side*.034,-.069,.748),(side*.025,-.062,.840)],.006,gold,'neck')
        # Flattened alien helmet. Closed overlapping armor facets, not a human head.
        mesh('Ebon_Wing_Helmet',[(-.21,-.045,.86),(-.13,-.102,.924),(0,-.09,.972),(.13,-.102,.924),(.21,-.045,.86),(0,-.129,.842),(-.17,.06,.867),(0,.084,.945),(.17,.06,.867)],[(0,1,5),(1,2,5),(2,3,5),(3,4,5),(0,6,7,2,1),(2,7,8,4,3),(0,5,4,8,7,6)],dark,'head')
        prism('Alien_Visor',(0,-.12,.866),(.073,.011,.007),'#243335','head')
        for side in [-1,1]:
            tube('Ebon_Helmet_Tracery'+str(side),[(side*.12,-.108,.913),(side*.05,-.107,.934),(side*.027,-.14,.886),(side*.011,-.142,.86)],.008,gold,'head')
            ell('Ebon_Shoulder_Plate'+str(side),(side*.175,0,.581),(.093,.095,.080),'#626867','chest')
            prism('Ebon_Chest_Plate'+str(side),(side*.071,-.108,.566),(.056,.018,.061),dark)
            tube('Ebon_Chest_Seam'+str(side),[(side*.105,-.134,.602),(side*.061,-.145,.55),(side*.076,-.13,.496)],.009,gold)
            for j in range(3):cone('Ebon_Claw'+str(side)+str(j),(side*(.275+j*.013),-.01,.345),(side*(.279+j*.013),-.033,.303),.006,'#727878','hand.'+('R' if side>0 else 'L'))
        cape()
    elif ident=='eboncandle_skull':
        # Custom sphere skull with hollow frontal orbital cups and exposed tooth rows.
        cranium=[]; faces=[]; n=20; m=10
        for j in range(m+1):
            phi=math.pi*j/m
            for i in range(n):
                theta=math.tau*i/n
                cranium.append((.237*math.sin(phi)*math.cos(theta),.02+.174*math.sin(phi)*math.sin(theta),.735+.224*math.cos(phi)))
        for j in range(m):
            for i in range(n):
                inds=(j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i)
                pts=[cranium[k] for k in inds];x=sum(p[0] for p in pts)/4;y=sum(p[1] for p in pts)/4;z=sum(p[2] for p in pts)/4
                # Cut orbital apertures in front sphere; shadow cups behind opening.
                eye=any(((x-side*.093)/.073)**2+((z-.722)/.066)**2<1.18 for side in [-1,1])
                if not (y<-.07 and eye):faces.append(inds)
        mesh('Skull_Hollow_Cranium',cranium,faces,skin,'head')
        for side in [-1,1]:
            ell('Skull_Orbital_Recess'+str(side),(side*.093,-.105,.722),(.073,.038,.069),'#283A30','head')
            ring('Skull_Orbital_Rim'+str(side),(side*.093,-.131,.722),(.074,.068),skin,thick=.012)
            ell('Skull_Cheekbone'+str(side),(side*.146,-.099,.626),(.043,.04,.048),skin,'head')
            tube('Skull_Zygomatic_Arch'+str(side),[(side*.182,-.012,.7),(side*.176,-.098,.64),(side*.115,-.12,.622)],.016,skin,'head')
        mesh('Skull_Nose_Cavity',[(-.023,-.156,.657),(.023,-.156,.657),(0,-.16,.704),(0,-.109,.667)],[(0,1,2),(0,3,1),(1,3,2),(2,3,0)],'#24382F','head')
        tube('Skull_Lower_Jaw',[(-.136,-.042,.625),(-.115,-.121,.548),(0,-.151,.525),(.115,-.121,.548),(.136,-.042,.625)],.023,skin,'head')
        for j in range(10):
            a=(j-4.5)*.18;x=.104*math.sin(a);y=-.15+.045*(1-math.cos(a))
            ell('Skull_Upper_Tooth'+str(j),(x,y,.606),(.010,.013,.021),pale,'head')
            ell('Skull_Lower_Tooth'+str(j),(x,y,.565),(.010,.012,.017),pale,'head')
        for side in [-1,1]:
            tube('Skull_Crimson_Tracery'+str(side),[(side*.025,-.12,.945),(side*.073,-.15,.904),(side*.112,-.155,.875),(side*.11,-.172,.829)],.005,gold,'head')
            tube('Cradle_Side_Rail'+str(side),[(side*.24,.28,.435),(side*.29,.14,.435),(side*.29,-.12,.37),(side*.29,-.31,.365)],.021,dark,'hips')
            for z,y,rr in [(.2,.12,.182),(.135,-.3,.12)]:
                ring('Cradle_Wheel'+str(side)+str(y),(side*.29,y,z),(rr,rr),dark,'hips',plane='yz',thick=.022)
                for j in range(4):
                    a=j*math.tau/4
                    tube('Wheel_Spoke'+str(side)+str(y)+str(j),[(side*.29,y,z),(side*.29,y+math.cos(a)*rr,z+math.sin(a)*rr)],.009,dark,'hips')
                ell('Wheel_Hub'+str(side)+str(y),(side*.29,y,z),(.028,.035,.035),dark,'hips')
            for y,z in [(.22,.46),(-.28,.387)]:
                tube('Cradle_Lantern_Post'+str(side)+str(y),[(side*.29,y,z),(side*.29,y,z+.062)],.015,dark,'hips')
                ell('Cradle_Lantern'+str(side)+str(y),(side*.29,y,z+.068),(.024,.024,.036),pale,'hips')
                cone('Cradle_Lantern_Cap'+str(side)+str(y),(side*.29,y,z+.095),(side*.29,y,z+.12),.026,dark,'hips')
        ell('Cradle_Gold_Basin',(0,.02,.415),(.245,.195,.065),dark,'hips')
        ring('Cradle_Basin_Rim',(0,.02,.467),(.244,.193),dark,'hips',plane='xy',thick=.018)
    elif ident=='ballman':
        ell('Ballman_Spherical_Body',(0,0,.61),(.30,.24,.32),skin,'head')
        for side in [-1,1]:
            ell('Ballman_Tiny_Eye'+str(side),(side*.078,-.23,.70),(.014,.008,.014),'#34372D','head')
            tube('Ballman_Wire_Arm'+str(side),[(side*.28,0,.59),(side*.41,-.008,.38)],[.012,.009],skin,'upper_arm.'+('R' if side>0 else 'L'))
            ell('Ballman_Mitten'+str(side),(side*.41,-.008,.34),(.055,.034,.06),skin,'hand.'+('R' if side>0 else 'L'))
            tube('Ballman_Wire_Leg'+str(side),[(side*.10,0,.31),(side*.10,0,.08)],.012,skin,'upper_leg.'+('R' if side>0 else 'L'))
            ell('Ballman_Shoe'+str(side),(side*.10,-.026,.042),(.055,.072,.028),pale,'foot.'+('R' if side>0 else 'L'))
        mesh('Ballman_Open_Mouth',[(-.18,-.239,.57),(.18,-.239,.57),(.135,-.245,.50),(0,-.247,.472),(-.135,-.245,.50),(0,-.20,.53)],[(0,1,5),(1,2,5),(2,3,5),(3,4,5),(4,0,5)],'#453E2C','head')
    elif species=='golem':
        # Custom round morphology. Arms reach nearly to ground, legs stay short.
        ell('Golem_Round_Body',(0,0,.45),(.31,.20,.37),skin,'chest')
        ell('Golem_Small_Round_Head',(0,-.025,.80),(.152,.142,.139),skin,'head')
        for side in [-1,1]:
            ell('Golem_Long_Arm'+str(side),(side*.32,.005,.43),(.105,.12,.27),skin,'upper_arm.'+('R' if side>0 else 'L'))
            ell('Golem_Hand'+str(side),(side*.335,-.01,.188),(.09,.092,.09),skin,'hand.'+('R' if side>0 else 'L'))
            ell('Golem_Short_Leg'+str(side),(side*.13,0,.096),(.092,.112,.095),skin,'upper_leg.'+('R' if side>0 else 'L'))
            ell('Golem_Dot_Eye'+str(side),(side*.058,-.191,.798),(.009,.008,.01),'#32382D','head')
            ell('Golem_Worn_Arm_Patch'+str(side),(side*.365,-.102,.465),(.063,.019,.065),'#B4B5A0','upper_arm.'+('R' if side>0 else 'L'))
        ell('Golem_Face_Stone_Patch',(.05,-.158,.84),(.070,.018,.069),'#B4B5A0','head')
        if ident=='police_golem':
            prism('Police_Blue_Kepi',(0,-.022,.985),(.105,.091,.080),dark,'head')
            prism('Police_Kepi_Visor',(0,-.137,.927),(.122,.060,.012),dark,'head')
            ring('Police_Gold_Hat_Band',(0,-.022,.943),(.11,.095),gold,'head',plane='xy',thick=.007)
            ring('Police_Gold_Hat_Emblem',(0,-.117,.977),(.031,.036),gold,'head',thick=.004)
            prism('Police_Blue_Waist',(0,-.162,.271),(.25,.022,.075),dark,'hips')
            tube('Police_Diagonal_Sash',[(-.20,-.102,.745),(-.15,-.19,.63),(.04,-.208,.44),(.25,-.18,.30)],.025,dark)
            tube('Police_Sash_Gold_Trim',[(-.222,-.106,.746),(-.17,-.212,.63),(.02,-.228,.44),(.23,-.20,.30)],.006,gold)
            tube('Police_Baton',[(.265,-.05,.29),(.37,-.035,.40)],.018,'#2B313C','hips')
        else:
            prism('Domestic_Apron',(0,-.204,.395),(.207,.011,.135),dark,'hips')
            for side in [-1,1]:tube('Domestic_Apron_Strap'+str(side),[(side*.13,-.118,.73),(side*.165,-.194,.52)],.016,dark)
    elif ident=='cyclops_doctor':
        cone('Cyclops_Central_Horn',(0,-.015,.952),(0,-.006,1.018),.026,skin)
        for side in [-1,1]:ear('Cyclops_Point_Ear'+str(side),side,.006,.092,z=.86)
        ring('Cyclops_Optical_Lens',(0,-.166,.848),(.059,.062),'#887F50',thick=.007)
        for side in [-1,1]:
            tube('Cyclops_Strap'+str(side),[(side*.14,.006,.895),(side*.072,-.132,.875),(side*.037,-.161,.822)],.0045,'#887F50','head')
            cone('Cyclops_Lower_Tusk'+str(side),(side*.03,-.144,.767),(side*.035,-.154,.796),.01,pale)
            for j in range(5):ell('Labcoat_Button'+str(j),(-.052,-.135,.57-j*.057),(.005,.003,.005),'#B4AE99')
        prism('Labcoat_Name_Pocket',(.065,-.14,.558),(.034,.007,.016),pale)
    elif ident=='knight_canine':armband()
    elif ident=='knight_feline':
        armband()
        ell('Top_Hat_Brim',(0,0,.986),(.207,.148,.013),dark,'head')
        prism('Top_Hat_Crown',(0,.01,1.047),(.093,.074,.069),dark,'head')
        tube('Knight_Cane',[(.245,-.065,.34),(.245,-.07,.012)],.01,'#B69C66','hand.R')
    elif ident=='godrey':
        for side in [-1,1]:ear('Godrey_Wide_Ear'+str(side),side,-.028,.115,z=.85)
        cone('Godrey_Horn',(0,0,.951),(0,-.007,.98),.016,skin)
        tube('Godrey_Goatee',[(-.035,-.108,.753),(0,-.122,.71),(.035,-.108,.753)],[.018,.025,.018],pale,'head')
        tube('Godrey_Pipe',[(.035,-.14,.765),(.105,-.185,.768),(.14,-.185,.811)],[.004,.008,.013],'#725441','head')
        tube('Godrey_Purple_Tail',[(0,.05,.36),(.09,.17,.30),(.17,.16,.255),(.235,.14,.284)],[.012,.014,.012,.006],skin,'hips')
        mesh('Godrey_Spade_Tail',[(.218,.13,.287),(.265,.13,.31),(.272,.13,.27),(.238,.13,.263),(.243,.147,.284)],[(0,1,4),(1,2,4),(2,3,4),(3,0,4),(0,3,2,1)],skin,'hips')
    elif ident in ['baroni','rabbit_soldier']:
        if ident=='baroni':
            for side in [-1,1]:
                ring('Baroni_Round_Glasses'+str(side),(side*.056,-.152,.845),(.029,.028),'#292D3B',thick=.004)
                ell('Baroni_Dark_Lens'+str(side),(side*.056,-.152,.845),(.026,.007,.026),'#4E4E70','head')
            tube('Baroni_Glasses_Bridge',[(-.025,-.157,.845),(.025,-.157,.845)],.003,'#31323D','head')
        else:
            ell('Rabbit_White_Muzzle',(0,-.14,.79),(.057,.035,.034),'#E0D7B8','head')
            for side in [-1,1]:prism('Rabbit_Incisor'+str(side),(side*.009,-.17,.765),(.007,.007,.014),pale,'head')
    elif ident=='frog_soldier':
        ell('Frog_Wide_Jaw',(0,-.08,.783),(.16,.11,.053),'#C4D38B','head')
        for side in [-1,1]:
            ell('Frog_Eye_Mound'+str(side),(side*.126,-.058,.92),(.055,.048,.060),skin,'head')
            ell('Frog_Eye'+str(side),(side*.126,-.099,.93),(.038,.018,.04),'#E4D598','head')
            ell('Frog_Pupil'+str(side),(side*.126,-.115,.935),(.025,.008,.028),'#24281D','head')
        tube('Frog_Mouth_Line',[(-.145,-.152,.797),(0,-.185,.773),(.145,-.152,.797)],.004,'#455F35','head')
    elif ident=='bird_soldier':
        wings('#E1E1D6');birdfeet('#C7826E')
        mesh('Bird_Coral_Beak',[(-.035,-.151,.823),(.035,-.151,.823),(0,-.225,.784),(0,-.142,.773)],[(0,1,2),(0,3,1),(1,3,2),(2,3,0)],'#CC8D7C','head')
        cone('Bird_Feather_Beard',(0,-.074,.699),(0,-.113,.65),.045,pale,'neck')
    elif ident=='wolf_soldier':
        for side in [-1,1]:ear('Wolf_Pointed_Ear'+str(side),side,.125,.020,z=.89,c=skin)
        for j in range(3):cone('Wolf_Dark_Forehead_Tuft'+str(j),((j-1)*.026,-.007,.953),((j-1)*.030,-.006,.993+j%2*.015),.023,hair)
        tube('Wolf_Red_Eye_Scar',[(-.074,-.134,.889),(-.048,-.143,.852),(-.069,-.139,.835)],.0045,'#A8776C','head')
    elif ident=='hawk_soldier':
        wings('#A98C51');birdfeet('#AB995A')
        for j in range(3):cone('Hawk_Forehead_Feather'+str(j),(j*.012,-.018,.97),(j*.014,-.016,1.008+j*.009),.012,'#BF7652' if j%2 else '#ECE4C8')
