-- Small preview whitelist grouped by native FCodexEnemyRow.EnemyType.
-- Chinese category captions explain internal enum values; no elite/minion rank is inferred.
local M={}
M.taxonomy={
 {id='training',label='训练木桩',native=false},
 {id='GuaiMian',label='怪面',native=true},
 {id='DragonModified',label='龙体改造',native=true},
 {id='Puppet',label='人偶',native=true},
 {id='Animal',label='动物',native=true},
 {id='HumanMaster',label='人类高手',native=true},
}
M.list={
 {id='gold',name='金面人训练木桩',category='training',class='/Game/RenewalContent/Actors/Mobs/Normal/BP_Monster_GoldMaskMan_Dummy_OnlyHit.BP_Monster_GoldMaskMan_Dummy_OnlyHit_C',skills={}},
 {id='spear',name='长枪暴徒',category='GuaiMian',class='/PBZCombatAsset/ActorData/Mobs/003_MaleThug/BP_Monster_MaleThug_Spear_Blue.BP_Monster_MaleThug_Spear_Blue_C',skills={red='GA_MaleThug_Spear_SpecialAttack_02_C'}},
 {id='sword',name='暴徒',category='GuaiMian',class='/PBZCombatAsset/ActorData/Mobs/003_MaleThug/BP_Monster_MaleThug_Sword_Blue.BP_Monster_MaleThug_Sword_Blue_C',skills={blue='GA_MaleThug_Sword_HeavyAttack_01_C'}},
 {id='club',name='黄袍暴徒',category='GuaiMian',class='/PBZCombatAsset/ActorData/Mobs/003_MaleThug/BP_Monster_MaleThug_Club_Yellow.BP_Monster_MaleThug_Club_Yellow_C',skills={blue='GA_MaleThug_Club_Skill_01_C'}},
 {id='bigshield',name='大盾暴徒',category='GuaiMian',class='/PBZCombatAsset/ActorData/Mobs/003_MaleThug/BP_Monster_MaleThug_BigShield.BP_Monster_MaleThug_BigShield_C',skills={}},
 {id='swordshield',name='刀盾暴徒',category='GuaiMian',class='/PBZCombatAsset/ActorData/Mobs/003_MaleThug/BP_Monster_MaleThug_Sword_Blue_Shield.BP_Monster_MaleThug_Sword_Blue_Shield_C',skills={}},
 {id='twinaxe',name='双斧暴徒',category='GuaiMian',class='/PBZCombatAsset/ActorData/Mobs/003_MaleThug/BP_Monster_MaleThug_TwinAxe.BP_Monster_MaleThug_TwinAxe_C',skills={}},
 {id='hoe',name='疯妇',category='GuaiMian',class='/PBZCombatAsset/ActorData/Mobs/025_FemaleThug/BP_Monster_FemaleThug_Hoe.BP_Monster_FemaleThug_Hoe_C',skills={}},
 {id='twinhoe',name='双镐疯妇',category='GuaiMian',class='/PBZCombatAsset/ActorData/Mobs/025_FemaleThug/BP_Monster_FemaleThug_TwinHoe.BP_Monster_FemaleThug_TwinHoe_C',skills={blue='GA_FemaleThug_TwinHoe_Attack_02_C'}},
 {id='bigknife',name='巨刃疯妇',category='GuaiMian',class='/PBZCombatAsset/ActorData/Mobs/025_FemaleThug/BP_Monster_FemaleThug_BigKnife.BP_Monster_FemaleThug_BigKnife_C',skills={}},
 {id='bandit',name='山贼',category='GuaiMian',class='/PBZCombatAsset/ActorData/Mobs/041_Bandit/BP_Monster_Bandit_Sword_ShieldBroken.BP_Monster_Bandit_Sword_ShieldBroken_C',skills={}},
 {id='banditmaster',name='山贼高手',category='GuaiMian',class='/PBZCombatAsset/ActorData/Mobs/041_Bandit/BP_Monster_Bandit_Sword.BP_Monster_Bandit_Sword_C',skills={}},
 {id='copperfist',name='活铜人.拳',category='GuaiMian',class='/PBZCombatAsset/ActorData/Mobs/HuoTongRen/HuoTongRen_BP/BP_Monster_HuoTongRen_Fist.BP_Monster_HuoTongRen_Fist_C',skills={}},
 {id='swordsman',name='无面剑客',category='DragonModified',class='/PBZCombatAsset/ActorData/Mobs/035_HuaShan/BP_Monster_HuaShan_Normal_White.BP_Monster_HuaShan_Normal_White_C',skills={}},
 {id='spearman',name='无面枪兵',category='DragonModified',class='/PBZCombatAsset/ActorData/Mobs/036_SpearMan/BP_Monster_SpearMan_Spear_White.BP_Monster_SpearMan_Spear_White_C',skills={}},
 {id='swordcaptain',name='无面剑客队长',category='DragonModified',class='/PBZCombatAsset/ActorData/Mobs/035_HuaShan/BP_Monster_HuaShan_Normal_Blue.BP_Monster_HuaShan_Normal_Blue_C',skills={}},
 {id='spearcaptain',name='无面枪兵队长',category='DragonModified',class='/PBZCombatAsset/ActorData/Mobs/036_SpearMan/BP_Monster_SpearMan_Spear_Blue.BP_Monster_SpearMan_Spear_Blue_C',skills={}},
 {id='emei',name='白山女徒',category='DragonModified',class='/PBZCombatAsset/ActorData/Mobs/034_EMei/BP_Monster_EMei_EMeiCi.BP_Monster_EMei_EMeiCi_C',skills={}},
 {id='emeitwin',name='白山双刺护法',category='DragonModified',class='/PBZCombatAsset/ActorData/Mobs/034_EMei/BP_Monster_EMei_ShuangCi.BP_Monster_EMei_ShuangCi_C',skills={}},
 {id='guichai',name='鬼差',category='DragonModified',class='/PBZCombatAsset/ActorData/Mobs/037_GuiChai/Blueprints/BP_Monster_GuiChai_Black_TwinBlade.BP_Monster_GuiChai_Black_TwinBlade_C',skills={}},
 {id='maledoll',name='阳体人偶',category='Puppet',class='/PBZCombatAsset/ActorData/Mobs/MaleDoll/BP_Monster_MaleDoll_Weaponless.BP_Monster_MaleDoll_Weaponless_C',skills={}},
 {id='femaledoll',name='阴体人偶',category='Puppet',class='/PBZCombatAsset/ActorData/Mobs/FemaleDoll/BP_Monster_FemaleDoll_Weaponless.BP_Monster_FemaleDoll_Weaponless_C',skills={}},
 {id='sworddoll',name='剑盾人偶',category='Puppet',class='/PBZCombatAsset/ActorData/Mobs/FemaleDoll/BP_Monster_FemaleDoll_Sword.BP_Monster_FemaleDoll_Sword_C',skills={}},
 {id='speardoll',name='枪盾人偶',category='Puppet',class='/PBZCombatAsset/ActorData/Mobs/MaleDoll/BP_Monster_MaleDoll_QiangDun.BP_Monster_MaleDoll_QiangDun_C',skills={}},
 {id='dog',name='狂犬',category='Animal',class='/PBZCombatAsset/ActorData/Mobs/005_ModDog/BP_Monster_Dog.BP_Monster_Dog_C',skills={}},
}
for _,row in ipairs(M.list)do
 local hint=row.skills.red and '原生红光' or row.skills.blue and '原生蓝光' or '静止受击'
 row.label=row.name..'（'..hint..'）'
end
function M.get(id)
 for _,row in ipairs(M.list)do if row.id==id then return row end end
 error('未知训练目标')
end
local function identity(key,...)if select('#',...)>0 then return string.format(key,...)end;return key end
function M.label(id,T)
 T=T or identity
 local row=M.get(id)
 local hint=row.skills.red and '原生红光' or row.skills.blue and '原生蓝光' or '静止受击'
 return T(row.name)..T('（%s）',T(hint))
end
function M.options(category,T)
 local out={}
 for _,row in ipairs(M.list)do
  if not category or row.category==category then out[#out+1]={label=M.label(row.id,T),value=row.id}end
 end
 return out
end
function M.categories(T)
 T=T or identity
 local out={}
 for _,row in ipairs(M.taxonomy)do
  if #M.options(row.id)>0 then out[#out+1]={label=T(row.label),value=row.id}end
 end
 return out
end
function M.description(id,T)
 T=T or identity
 local row=M.get(id);local modes={T('静止受击')}
 if row.skills.red then modes[#modes+1]=T('红光循环') end
 if row.skills.blue then modes[#modes+1]=T('蓝光循环') end
 local pending=not row.skills.red and not row.skills.blue and row.category~='training'
 return T('训练模式：%s%s',table.concat(modes,T('、')),pending and T('（红蓝招式待核验）') or '')
end
function M.modes(id,T)
 T=T or identity
 local row=M.get(id)
 local out={{label=T('静止受击'),value='hold'}}
 if row.skills.red then out[#out+1]={label=T('循环红光（实验）'),value='red'}end
 if row.skills.blue then out[#out+1]={label=T('循环蓝光（实验）'),value='blue'}end
 return out
end
function M.health(value)
 assert(type(value)=='number' and value==value and value>=10 and value<=10000000,'目标血量须为 10～10000000')
 return math.floor(value)
end
function M.interval(value)
 assert(type(value)=='number' and value==value and value>=0.5 and value<=30,'攻击间隔须为 0.5～30 秒')
 return value
end
return M
