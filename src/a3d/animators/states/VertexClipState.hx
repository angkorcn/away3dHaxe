package a3d.animators.states;

import a3d.animators.IAnimator;
import a3d.animators.VertexAnimator;
import a3d.animators.nodes.VertexClipNode;
import a3d.core.base.Geometry;
import flash.Vector;

/**
 *
 */
class VertexClipState extends AnimationClipState implements IVertexAnimationState
{
	private var _frames:Vector<Geometry>;
	private var _vertexClipNode:VertexClipNode;
	private var _currentGeometry:Geometry;
	private var _nextGeometry:Geometry;

	/**
	 * @inheritDoc
	 */
	public var currentGeometry(get, null):Geometry;
	

	/**
	 * @inheritDoc
	 */
	public var nextGeometry(get, null):Geometry;
	
	

	public function new(animator:IAnimator, vertexClipNode:VertexClipNode)
	{
		super(animator, vertexClipNode);

		_vertexClipNode = vertexClipNode;
		_frames = _vertexClipNode.frames;
	}

	/**
	 * @inheritDoc
	 */
	override private function updateFrames():Void
	{
		super.updateFrames();

		_currentGeometry = _frames[_currentFrame];

		if (_vertexClipNode.looping && _nextFrame >= _vertexClipNode.lastFrame)
		{
			_nextGeometry = _frames[0];
			Std.instance(_animator,VertexAnimator).dispatchCycleEvent();
		}
		else
		{
			_nextGeometry = _frames[_nextFrame];
		}
	}

	/**
	 * @inheritDoc
	 */
	override private function updatePositionDelta():Void
	{
		//TODO:implement positiondelta functionality for vertex animations
	}
	
	private function get_currentGeometry():Geometry
	{
		if (_framesDirty)
			updateFrames();

		return _currentGeometry;
	}
	
	private function get_nextGeometry():Geometry
	{
		if (_framesDirty)
			updateFrames();

		return _nextGeometry;
	}
}
