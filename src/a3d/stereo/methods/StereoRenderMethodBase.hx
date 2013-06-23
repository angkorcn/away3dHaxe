package a3d.stereo.methods
{
	import a3d.core.managers.Stage3DProxy;
	import a3d.errors.AbstractMethodError;

	class StereoRenderMethodBase
	{
		private var _textureSizeInvalid:Bool = true;

		public function StereoRenderMethodBase()
		{
		}

		public function activate(stage3DProxy:Stage3DProxy):Void
		{
		}

		public function deactivate(stage3DProxy:Stage3DProxy):Void
		{
		}

		public function getFragmentCode():String
		{
			throw new AbstractMethodError('Concrete implementation of StereoRenderMethodBase must be used and extend getFragmentCode().');
		}

		public function invalidateTextureSize():Void
		{
			_textureSizeInvalid = true;
		}
	}
}
