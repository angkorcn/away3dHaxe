package a3d.filters;

import flash.geom.Vector3D;

import a3d.entities.Camera3D;
import a3d.core.managers.Stage3DProxy;
import a3d.entities.ObjectContainer3D;
import a3d.filters.tasks.Filter3DHDepthOfFFieldTask;

class HDepthOfFieldFilter3D extends Filter3DBase
{
	public var focusTarget(get, set):ObjectContainer3D;
	public var focusDistance(get, set):Int;
	public var range(get, set):Float;
	public var maxBlur(get, set):Int;
	
	private var _dofTask:Filter3DHDepthOfFFieldTask;
	private var _focusTarget:ObjectContainer3D;

	/**
	 * Creates a new HDepthOfFieldFilter3D object
	 * @param amount The amount of blur to apply in pixels
	 * @param stepSize The distance between samples. Set to -1 to autodetect with acceptable quality.
	 */
	public function new(maxBlur:Int = 3, stepSize:Int = -1)
	{
		super();
		_dofTask = new Filter3DHDepthOfFFieldTask(maxBlur, stepSize);
		addTask(_dofTask);
	}

	private function get_focusTarget():ObjectContainer3D
	{
		return _focusTarget;
	}

	private function set_focusTarget(value:ObjectContainer3D):ObjectContainer3D
	{
		return _focusTarget = value;
	}

	private function get_focusDistance():Float
	{
		return _dofTask.focusDistance;
	}

	private function set_focusDistance(value:Float):Float
	{
		return _dofTask.focusDistance = value;
	}

	private function get_range():Float
	{
		return _dofTask.range;
	}

	private function set_range(value:Float):Float
	{
		return _dofTask.range = value;
	}

	private function get_maxBlur():Int
	{
		return _dofTask.maxBlur;
	}

	private function set_maxBlur(value:Int):Int
	{
		_dofTask.maxBlur = value;
	}

	override public function update(stage:Stage3DProxy, camera:Camera3D):Void
	{
		if (_focusTarget != null)
			updateFocus(camera);
	}

	private function updateFocus(camera:Camera3D):Void
	{
		var target:Vector3D = camera.inverseSceneTransform.transformVector(_focusTarget.scenePosition);
		_dofTask.focusDistance = target.z;
	}
}
