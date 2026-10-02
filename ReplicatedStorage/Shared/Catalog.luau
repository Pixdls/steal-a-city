--!strict
local Config = require(script.Parent.Config)
export type Object = {id: string, name: string, stage: string, tier: string, income: number, weight: number, size: Vector3}
local Catalog = {}
Catalog.Objects = {} :: {[string]: Object}
local function add(id: string, name: string, stage: string, tier: string, income: number, weight: number, size: Vector3)
 Catalog.Objects[id] = {id=id,name=name,stage=stage,tier=tier,income=income,weight=weight,size=size}
end
add("Bucket","Bucket","RanchTrail","small",1,5,Vector3.new(2,2,2))
add("HayBale","Hay Bale","RanchTrail","small",3,15,Vector3.new(4,3,3))
add("Cactus","Cactus","RanchTrail","medium",6,40,Vector3.new(3,7,3))
add("Scarecrow","Scarecrow","RanchTrail","medium",12,90,Vector3.new(4,8,2))
add("CoveredWagon","Covered Wagon","RanchTrail","showpiece",20,200,Vector3.new(7,8,12))
add("WaterTrough","Water Trough","CowboyTown","small",30,350,Vector3.new(6,2.5,3))
add("Outhouse","Outhouse","CowboyTown","small",50,700,Vector3.new(4,8,4))
add("Stagecoach","Stagecoach","CowboyTown","medium",80,1500,Vector3.new(6,8,11))
add("WaterTower","Water Tower","CowboyTown","medium",110,3500,Vector3.new(9,20,9))
add("Saloon","Saloon","CowboyTown","showpiece",150,8000,Vector3.new(22,18,16))
Catalog.Stages = {
 RanchTrail={id="RanchTrail",index=1,zStart=0,zEnd=-170,halfWidth=34,recommendedSize=10,chaser="RanchDog"},
 CowboyTown={id="CowboyTown",index=2,zStart=-210,zEnd=-400,halfWidth=56,recommendedSize=300,chaser="Sheriff"},
}
Catalog.Chasers = {RanchDog={stage="RanchTrail",speedMultiplier=0.8},Sheriff={stage="CowboyTown",speedMultiplier=0.9}}
Catalog.Safes = {PiggyBank={name="Piggy Bank",minSeconds=10,maxSeconds=30,secretChance=0,weightMultiplier=0.6,size=Vector3.new(3,3,3)}}
function Catalog.GetObject(id: string): Object? return Catalog.Objects[id] end
function Catalog.GetVariant(id: string)
 for _, variant in Config.VARIANTS do if variant.id == id then return variant end end
 return Config.VARIANTS[1]
end
function Catalog.GetStageObjects(stage: string): {Object}
 local result: {Object} = {}
 for _, object in Catalog.Objects do if object.stage == stage then table.insert(result,object) end end
 table.sort(result,function(a,b) return a.weight < b.weight end)
 return result
end
function Catalog.Income(id: string, variant: string): number
 local object = Catalog.GetObject(id)
 return if object then object.income*Catalog.GetVariant(variant).multiplier else 0
end
return Catalog
