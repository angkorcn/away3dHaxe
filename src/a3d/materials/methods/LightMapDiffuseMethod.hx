package a3d.materials.methods;


import a3d.core.managers.Stage3DProxy;
import a3d.materials.BlendMode;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.textures.Texture2DBase;
import flash.errors.Error;



class LightMapDiffuseMethod extends CompositeDiffuseMethod
{
	private var _blendMode:BlendMode;
	private var _useSecondaryUV:Bool;

	public function new(lightMap:Texture2DBase, blendMode:BlendMode = null, useSecondaryUV:Bool = false, baseMethod:BasicDiffuseMethod = null)
	{
		super(null, baseMethod);
		_useSecondaryUV = useSecondaryUV;
		_texture = lightMap;
		this.blendMode = blendMode;
	}

	override public function initVO(vo:MethodVO):Void
	{
		vo.needsSecondaryUV = _useSecondaryUV;
		vo.needsUV = !_useSecondaryUV;
	}

	public var blendMode(get,set):BlendMode;
	private function get_blendMode():BlendMode
	{
		return _blendMode;
	}

	private function set_blendMode(value:BlendMode):BlendMode
	{
		if (value != BlendMode.ADD && value != BlendMode.MULTIPLY)
			throw new Error("Unknown blendmode!");
		if (_blendMode == value)
			return _blendMode;
		_blendMode = value;
		invalidateShaderProgram();
		
		return _blendMode;
	}

	public var lightMapTexture(get,set):Texture2DBase;
	private function get_lightMapTexture():Texture2DBase
	{
		return _texture;
	}

	private function set_lightMapTexture(value:Texture2DBase):Texture2DBase
	{
		return _texture = value;
	}

	override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		stage3DProxy.context3D.setTextureAt(vo.secondaryTexturesIndex, _texture.getTextureForStage3D(stage3DProxy));
		super.activate(vo, stage3DProxy);
	}

	override public function getFragmentPostLightingCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var code:String;
		var lightMapReg:ShaderRegisterElement = regCache.getFreeTextureReg();
		var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
		vo.secondaryTexturesIndex = lightMapReg.index;

		code = getTex2DSampleCode(vo, temp, lightMapReg, _texture, _sharedRegisters.secondaryUVVarying);

		if (_blendMode == BlendMode.MULTIPLY)
		{
			code += "mul " + _totalLightColorReg + ", " + _totalLightColorReg + ", " + temp + "\n";
		}
		else if (_blendMode == BlendMode.ADD)
		{
			code += "add " + _totalLightColorReg + ", " + _totalLightColorReg + ", " + temp + "\n";
		}
		
		code += super.getFragmentPostLightingCode(vo, regCache, targetReg);

		return code;
	}
}
