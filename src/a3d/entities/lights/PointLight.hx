package a3d.entities.lights
{
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;


	import a3d.bounds.BoundingSphere;
	import a3d.bounds.BoundingVolumeBase;
	import a3d.core.base.IRenderable;
	import a3d.core.partition.EntityNode;
	import a3d.core.partition.PointLightNode;
	import a3d.entities.lights.shadowmaps.CubeMapShadowMapper;
	import a3d.entities.lights.shadowmaps.ShadowMapperBase;
	import a3d.math.Matrix3DUtils;



	/**
	 * PointLight represents an omni-directional light. The light is emitted from a given position in the scene.
	 */
	class PointLight extends LightBase
	{
		//private static var _pos : Vector3D = new Vector3D();
		private var _radius:Float = 90000;
		private var _fallOff:Float = 100000;
		private var _fallOffFactor:Float;

		/**
		 * Creates a new PointLight object.
		 */
		public function PointLight()
		{
			super();
			_fallOffFactor = 1 / (_fallOff * _fallOff - _radius * _radius);
		}

		override private function createShadowMapper():ShadowMapperBase
		{
			return new CubeMapShadowMapper();
		}


		override private function createEntityPartitionNode():EntityNode
		{
			return new PointLightNode(this);
		}

		/**
		 * The minimum distance of the light's reach.
		 */
		private inline function get_radius():Float
		{
			return _radius;
		}

		private inline function set_radius(value:Float):Void
		{
			_radius = value;
			if (_radius < 0)
				_radius = 0;
			else if (_radius > _fallOff)
			{
				_fallOff = _radius;
				invalidateBounds();
			}

			_fallOffFactor = 1 / (_fallOff * _fallOff - _radius * _radius);
		}

		private inline function get_fallOffFactor():Float
		{
			return _fallOffFactor;
		}

		/**
		 * The maximum distance of the light's reach
		 */
		private inline function get_fallOff():Float
		{
			return _fallOff;
		}

		private inline function set_fallOff(value:Float):Void
		{
			_fallOff = value;
			if (_fallOff < 0)
				_fallOff = 0;
			if (_fallOff < _radius)
				_radius = _fallOff;
			_fallOffFactor = 1 / (_fallOff * _fallOff - _radius * _radius);
			invalidateBounds();
		}

		/**
		 * @inheritDoc
		 */
		override private function updateBounds():Void
		{
//			super.updateBounds();
//			_bounds.fromExtremes(-_fallOff, -_fallOff, -_fallOff, _fallOff, _fallOff, _fallOff);
			_bounds.fromSphere(new Vector3D(), _fallOff);
			_boundsInvalid = false;
		}

		/**
		 * @inheritDoc
		 */
		override private function getDefaultBoundingVolume():BoundingVolumeBase
		{
			return new BoundingSphere();
		}

		/**
		 * @inheritDoc
		 */
		override public function getObjectProjectionMatrix(renderable:IRenderable, target:Matrix3D = null):Matrix3D
		{
			var raw:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
			var bounds:BoundingVolumeBase = renderable.sourceEntity.bounds;
			var m:Matrix3D = new Matrix3D();

			// todo: do not use lookAt on Light
			m.copyFrom(renderable.sceneTransform);
			m.append(_parent.inverseSceneTransform);
			lookAt(m.position);

			m.copyFrom(renderable.sceneTransform);
			m.append(inverseSceneTransform);
			m.copyColumnTo(3, _pos);

			var v1:Vector3D = m.deltaTransformVector(bounds.min);
			var v2:Vector3D = m.deltaTransformVector(bounds.max);
			var z:Float = _pos.z;
			var d1:Float = v1.x * v1.x + v1.y * v1.y + v1.z * v1.z;
			var d2:Float = v2.x * v2.x + v2.y * v2.y + v2.z * v2.z;
			var d:Float = Math.sqrt(d1 > d2 ? d1 : d2);
			var zMin:Float, zMax:Float;

			zMin = z - d;
			zMax = z + d;

			raw[uint(5)] = raw[uint(0)] = zMin / d;
			raw[uint(10)] = zMax / (zMax - zMin);
			raw[uint(11)] = 1;
			raw[uint(1)] = raw[uint(2)] = raw[uint(3)] = raw[uint(4)] =
				raw[uint(6)] = raw[uint(7)] = raw[uint(8)] = raw[uint(9)] =
				raw[uint(12)] = raw[uint(13)] = raw[uint(15)] = 0;
			raw[uint(14)] = -zMin * raw[uint(10)];

			target ||= new Matrix3D();
			target.copyRawDataFrom(raw);
			target.prepend(m);

			return target;
		}
	}
}
