package a3d.core.partition
{
	import a3d.core.base.IRenderable;
	import a3d.core.traverse.PartitionTraverser;
	import a3d.entities.Entity;

	/**
	 * RenderableNode is a space partitioning leaf node that contains any Entity that is itself a IRenderable
	 * object. This excludes Mesh (since the renderable objects are its SubMesh children).
	 */
	class RenderableNode extends EntityNode
	{
		private var _renderable:IRenderable;

		/**
		 * Creates a new RenderableNode object.
		 * @param mesh The mesh to be contained in the node.
		 */
		public function RenderableNode(renderable:IRenderable)
		{
			super(Entity(renderable));
			_renderable = renderable; // also keep a stronger typed reference
		}

		/**
		 * @inheritDoc
		 */
		override public function acceptTraverser(traverser:PartitionTraverser):Void
		{
			if (traverser.enterNode(this))
			{
				super.acceptTraverser(traverser);
				traverser.applyRenderable(_renderable);
			}
		}

	}
}
