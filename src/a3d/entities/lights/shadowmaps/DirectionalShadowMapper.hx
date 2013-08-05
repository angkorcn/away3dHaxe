package a3d.entities.lights.shadowmaps;

import a3d.core.render.DepthRenderer;
import a3d.entities.Camera3D;
import a3d.entities.lenses.FreeMatrixLens;
import a3d.entities.lights.DirectionalLight;
import a3d.entities.Scene3D;
import a3d.math.FMatrix3D;
import a3d.math.Plane3D;
import flash.display3D.textures.TextureBase;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.Vector;





class DirectionalShadowMapper extends ShadowMapperBase
{
	public var snap(get, set):Float;
	
	public var lightOffset(get, set):Float;
	
	/**
	 * Depth projection matrix that projects from scene space to depth map.
	 */
	public var depthProjection(get, null):Matrix3D;
	
	/**
	 * Depth projection matrix that projects from scene space to depth map.
	 */
	public var depth(get, null):Float;
	
	private var _overallDepthCamera:Camera3D;
	private var _localFrustum:Vector<Float>;

	private var _lightOffset:Float = 10000;
	private var _matrix:Matrix3D;
	private var _overallDepthLens:FreeMatrixLens;
	private var _snap:Float = 64;

	private var _cullPlanes:Vector<Plane3D>;
	private var _minZ:Float;
	private var _maxZ:Float;

	public function new()
	{
		super();
		_cullPlanes = new Vector<Plane3D>();
		_overallDepthLens = new FreeMatrixLens();
		_overallDepthCamera = new Camera3D(_overallDepthLens);
		_localFrustum = new Vector<Float>(8 * 3);
		_matrix = new Matrix3D();
	}

	
	private inline function get_snap():Float
	{
		return _snap;
	}

	private inline function set_snap(value:Float):Float
	{
		return _snap = value;
	}

	private inline function get_lightOffset():Float
	{
		return _lightOffset;
	}

	private inline function set_lightOffset(value:Float):Float
	{
		return _lightOffset = value;
	}

	
	private inline function get_depthProjection():Matrix3D
	{
		return _overallDepthCamera.viewProjection;
	}

	
	private inline function get_depth():Float
	{
		return _maxZ - _minZ;
	}

	override private function drawDepthMap(target:TextureBase, scene:Scene3D, renderer:DepthRenderer):Void
	{
		_casterCollector.camera = _overallDepthCamera;
		_casterCollector.cullPlanes = _cullPlanes;
		_casterCollector.clear();
		scene.traversePartitions(_casterCollector);
		renderer.render(_casterCollector, target);
		_casterCollector.cleanUp();
	}

	private function updateCullPlanes(viewCamera:Camera3D):Void
	{
		var lightFrustumPlanes:Vector<Plane3D> = _overallDepthCamera.frustumPlanes;
		var viewFrustumPlanes:Vector<Plane3D> = viewCamera.frustumPlanes;
		_cullPlanes.length = 4;

		_cullPlanes[0] = lightFrustumPlanes[0];
		_cullPlanes[1] = lightFrustumPlanes[1];
		_cullPlanes[2] = lightFrustumPlanes[2];
		_cullPlanes[3] = lightFrustumPlanes[3];

		var dir:Vector3D = Std.instance(_light,DirectionalLight).sceneDirection;
		var dirX:Float = dir.x;
		var dirY:Float = dir.y;
		var dirZ:Float = dir.z;
		var j:Int = 4;
		for (i in 0...6)
		{
			var plane:Plane3D = viewFrustumPlanes[i];
			if (plane.a * dirX + plane.b * dirY + plane.c * dirZ < 0)
				_cullPlanes[j++] = plane;
		}
	}

	override private function updateDepthProjection(viewCamera:Camera3D):Void
	{
		updateProjectionFromFrustumCorners(viewCamera, viewCamera.lens.frustumCorners, _matrix);
		_overallDepthLens.matrix = _matrix;
		updateCullPlanes(viewCamera);
	}

	private function updateProjectionFromFrustumCorners(viewCamera:Camera3D, corners:Vector<Float>, matrix:Matrix3D):Void
	{
		var minX:Float, minY:Float;
		var maxX:Float, maxY:Float;
		

		var dir:Vector3D = Std.instance(_light,DirectionalLight).sceneDirection;
		_overallDepthCamera.transform = _light.sceneTransform;
		var x:Float = Std.int((viewCamera.x - dir.x * _lightOffset) / _snap) * _snap;
		var y:Float = Std.int((viewCamera.y - dir.y * _lightOffset) / _snap) * _snap;
		var z:Float = Std.int((viewCamera.z - dir.z * _lightOffset) / _snap) * _snap;
		_overallDepthCamera.x = x;
		_overallDepthCamera.y = y;
		_overallDepthCamera.z = z;

		_matrix.copyFrom(_overallDepthCamera.inverseSceneTransform);
		_matrix.prepend(viewCamera.sceneTransform);
		_matrix.transformVectors(corners, _localFrustum);

		minX = maxX = _localFrustum[0];
		minY = maxY = _localFrustum[1];
		_maxZ = _localFrustum[2];

		var i:Int = 3;
		while (i < 24)
		{
			x = _localFrustum[i];
			y = _localFrustum[i + 1];
			z = _localFrustum[i + 2];
			if (x < minX)
				minX = x;
			if (x > maxX)
				maxX = x;
				
			if (y < minY)
				minY = y;
			if (y > maxY)
				maxY = y;
				
			if (z > _maxZ)
				_maxZ = z;
			i += 3;
		}
		_minZ = 1;

		var w:Float = maxX - minX;
		var h:Float = maxY - minY;
		var d:Float = 1 / (_maxZ - _minZ);

		if (minX < 0)
			minX -= _snap; // because int() rounds up for < 0
		if (minY < 0)
			minY -= _snap;
		minX = Std.int(minX / _snap) * _snap;
		minY = Std.int(minY / _snap) * _snap;

		var snap2:Float = 2 * _snap;
		w = Std.int(w / snap2 + 2) * snap2;
		h = Std.int(h / snap2 + 2) * snap2;

		maxX = minX + w;
		maxY = minY + h;

		w = 1 / w;
		h = 1 / h;

		var raw:Vector<Float> = FMatrix3D.RAW_DATA_CONTAINER;
		raw[0] = 2 * w;
		raw[5] = 2 * h;
		raw[10] = d;
		raw[12] = -(maxX + minX) * w;
		raw[13] = -(maxY + minY) * h;
		raw[14] = -_minZ * d;
		raw[15] = 1;
		raw[1] = raw[2] = raw[3] = raw[4] = raw[6] = raw[7] = raw[8] = raw[9] = raw[11] = 0;

		matrix.copyRawDataFrom(raw);
	}
}
