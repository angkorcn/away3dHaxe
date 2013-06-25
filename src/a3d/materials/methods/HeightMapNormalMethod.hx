package a3d.materials.methods;


import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.textures.Texture2DBase;



class HeightMapNormalMethod extends BasicNormalMethod
{
	private var _worldXYRatio:Float;
	private var _worldXZRatio:Float;

	public function new(heightMap:Texture2DBase, worldWidth:Float, worldHeight:Float, worldDepth:Float)
	{
		super();
		normalMap = heightMap;
		_worldXYRatio = worldWidth / worldHeight;
		_worldXZRatio = worldDepth / worldHeight;
	}

	override public function initConstants(vo:MethodVO):Void
	{
		var index:Int = vo.fragmentConstantsIndex;
		var data:Vector<Float> = vo.fragmentData;
		data[index] = 1 / normalMap.width;
		data[index + 1] = 1 / normalMap.height;
		data[index + 2] = 0;
		data[index + 3] = 1;
		data[index + 4] = _worldXYRatio;
		data[index + 5] = _worldXZRatio;
	}

	override private inline function get_tangentSpace():Bool
	{
		return false;
	}

	override public function copyFrom(method:ShadingMethodBase):Void
	{
	}

	override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
		var dataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
		var dataReg2:ShaderRegisterElement = regCache.getFreeFragmentConstant();
		_normalTextureRegister = regCache.getFreeTextureReg();
		vo.texturesIndex = _normalTextureRegister.index;
		vo.fragmentConstantsIndex = dataReg.index * 4;

		return getTex2DSampleCode(vo, targetReg, _normalTextureRegister, normalMap, _sharedRegisters.uvVarying, "clamp") +

			"add " + temp + ", " + _sharedRegisters.uvVarying + ", " + dataReg + ".xzzz\n" +
			getTex2DSampleCode(vo, temp, _normalTextureRegister, normalMap, temp, "clamp") +
			"sub " + targetReg + ".x, " + targetReg + ".x, " + temp + ".x\n" +

			"add " + temp + ", " + _sharedRegisters.uvVarying + ", " + dataReg + ".zyzz\n" +
			getTex2DSampleCode(vo, temp, _normalTextureRegister, normalMap, temp, "clamp") +
			"sub " + targetReg + ".z, " + targetReg + ".z, " + temp + ".x\n" +

			"mov " + targetReg + ".y, " + dataReg + ".w\n" +
			"mul " + targetReg + ".xz, " + targetReg + ".xz, " + dataReg2 + ".xy\n" +
			"nrm " + targetReg + ".xyz, " + targetReg + ".xyz\n";
	}
}
