package away3d.animators.nodes
{
	import away3d.io.library.assets.AssetType;
	import away3d.io.library.assets.IAsset;
	import away3d.io.library.assets.NamedAssetBase;

	/**
	 * Provides an abstract base class for nodes in an animation blend tree.
	 */
	public class AnimationNodeBase extends NamedAssetBase implements IAsset
	{
		protected var _stateClass:Class;

		public function get stateClass():Class
		{
			return _stateClass;
		}

		/**
		 * Creates a new <code>AnimationNodeBase</code> object.
		 */
		public function AnimationNodeBase()
		{
		}

		/**
		 * @inheritDoc
		 */
		public function dispose():void
		{
		}

		/**
		 * @inheritDoc
		 */
		public function get assetType():String
		{
			return AssetType.ANIMATION_NODE;
		}
	}
}
