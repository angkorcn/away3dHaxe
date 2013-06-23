/**
 */
package a3d.filters.tasks
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;
	
	import a3d.entities.Camera3D;
	import a3d.core.managers.Stage3DProxy;
	import a3d.utils.Debug;
	import a3d.errors.AbstractMethodError;

	class Filter3DTaskBase
	{
		private var _mainInputTexture:Texture;

		private var _scaledTextureWidth:Int = -1;
		private var _scaledTextureHeight:Int = -1;
		private var _textureWidth:Int = -1;
		private var _textureHeight:Int = -1;
		private var _textureDimensionsInvalid:Bool = true;
		private var _program3DInvalid:Bool = true;
		private var _program3D:Program3D;
		private var _target:Texture;
		private var _requireDepthRender:Bool;
		private var _textureScale:Int = 0;

		public function Filter3DTaskBase(requireDepthRender:Bool = false)
		{
			_requireDepthRender = requireDepthRender;
		}

		/**
		 * The texture scale for the input of this texture. This will define the output of the previous entry in the chain
		 */
		private inline function get_textureScale():Int
		{
			return _textureScale;
		}

		private inline function set_textureScale(value:Int):Void
		{
			if (_textureScale == value)
				return;
			_textureScale = value;
			_scaledTextureWidth = _textureWidth >> _textureScale;
			_scaledTextureHeight = _textureHeight >> _textureScale;
			_textureDimensionsInvalid = true;
		}

		private inline function get_target():Texture
		{
			return _target;
		}

		private inline function set_target(value:Texture):Void
		{
			_target = value;
		}

		private inline function get_textureWidth():Int
		{
			return _textureWidth;
		}

		private inline function set_textureWidth(value:Int):Void
		{
			if (_textureWidth == value)
				return;
			_textureWidth = value;
			_scaledTextureWidth = _textureWidth >> _textureScale;
			_textureDimensionsInvalid = true;
		}

		private inline function get_textureHeight():Int
		{
			return _textureHeight;
		}

		private inline function set_textureHeight(value:Int):Void
		{
			if (_textureHeight == value)
				return;
			_textureHeight = value;
			_scaledTextureHeight = _textureHeight >> _textureScale;
			_textureDimensionsInvalid = true;
		}

		public function getMainInputTexture(stage:Stage3DProxy):Texture
		{
			if (_textureDimensionsInvalid)
				updateTextures(stage);

			return _mainInputTexture;
		}

		public function dispose():Void
		{
			if (_mainInputTexture)
				_mainInputTexture.dispose();
			if (_program3D)
				_program3D.dispose();
		}

		private function invalidateProgram3D():Void
		{
			_program3DInvalid = true;
		}

		private function updateProgram3D(stage:Stage3DProxy):Void
		{
			if (_program3D)
				_program3D.dispose();
			_program3D = stage.context3D.createProgram();
			_program3D.upload(new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.VERTEX, getVertexCode()),
				new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.FRAGMENT, getFragmentCode()));
			_program3DInvalid = false;
		}

		private function getVertexCode():String
		{
			return "mov op, va0\n" +
				"mov v0, va1\n";
		}

		private function getFragmentCode():String
		{
			throw new AbstractMethodError();
			return null;
		}

		private function updateTextures(stage:Stage3DProxy):Void
		{
			if (_mainInputTexture)
				_mainInputTexture.dispose();

			_mainInputTexture = stage.context3D.createTexture(_scaledTextureWidth, _scaledTextureHeight, Context3DTextureFormat.BGRA, true);

			_textureDimensionsInvalid = false;
		}

		public function getProgram3D(stage3DProxy:Stage3DProxy):Program3D
		{
			if (_program3DInvalid)
				updateProgram3D(stage3DProxy);
			return _program3D;
		}

		public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D, depthTexture:Texture):Void
		{
		}

		public function deactivate(stage3DProxy:Stage3DProxy):Void
		{
		}

		private inline function get_requireDepthRender():Bool
		{
			return _requireDepthRender;
		}
	}
}