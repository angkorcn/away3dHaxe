package a3d.filters.tasks;

import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.textures.Texture;
import flash.display3D.textures.TextureBase;


import a3d.entities.Camera3D;
import a3d.core.managers.Stage3DProxy;



class Filter3DCompositeTask extends Filter3DTaskBase
{
	private var _data:Vector<Float>;
	private var _overlayTexture:TextureBase;
	private var _blendMode:String;

	public function new(blendMode:String, exposure:Float = 1)
	{
		super();
		_data = Vector<Float>([exposure, 0, 0, 0]);
		_blendMode = blendMode;
	}

	private inline function get_overlayTexture():TextureBase
	{
		return _overlayTexture;
	}

	private inline function set_overlayTexture(value:TextureBase):Void
	{
		_overlayTexture = value;
	}

	private inline function get_exposure():Float
	{
		return _data[0];
	}

	private inline function set_exposure(value:Float):Void
	{
		_data[0] = value;
	}


	override private function getFragmentCode():String
	{
		var code:String;
		var op:String;
		code = "tex ft0, v0, fs0 <2d,linear,clamp>	\n" +
			"tex ft1, v0, fs1 <2d,linear,clamp>	\n" +
			"mul ft0, ft0, fc0.x				\n";
		switch (_blendMode)
		{
			case "multiply":
				op = "mul";
			
			case "add":
				op = "add";
			
			case "subtract":
				op = "sub";
			
			case "normal":
				// for debugging purposes
				op = "mov";
			
			default:
				throw new Error("Unknown blend mode");
		}
		if (op != "mov")
			code += op + " oc, ft0, ft1\n";
		else
			code += "mov oc, ft0\n";
		return code;
	}

	override public function activate(stage3DProxy:Stage3DProxy, camera3D:Camera3D, depthTexture:Texture):Void
	{
		var context:Context3D = stage3DProxy._context3D;
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 1);
		context.setTextureAt(1, _overlayTexture);
	}

	override public function deactivate(stage3DProxy:Stage3DProxy):Void
	{
		stage3DProxy._context3D.setTextureAt(1, null);
	}
}
