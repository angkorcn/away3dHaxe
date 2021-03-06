package away3d.io.library.naming
{
	import away3d.io.library.assets.IAsset;

	public class IgnoreConflictStrategy extends ConflictStrategyBase
	{
		public function IgnoreConflictStrategy()
		{
			super();
		}


		override public function resolveConflict(changedAsset:IAsset, oldAsset:IAsset, assetsDictionary:Object, precedence:String):void
		{
			// Do nothing, ignore the fact that there is a conflict.
			return;
		}


		override public function create():ConflictStrategyBase
		{
			return new IgnoreConflictStrategy();
		}
	}
}
