package a3d.animators.states;

import flash.display3D.Context3DVertexBufferFormat;
import flash.geom.Vector3D;
import flash.utils.Dictionary;
import flash.Vector;


import a3d.animators.ParticleAnimator;
import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.data.AnimationSubGeometry;
import a3d.animators.data.ParticlePropertiesMode;
import a3d.animators.nodes.ParticleVelocityNode;
import a3d.entities.Camera3D;
import a3d.core.base.IRenderable;
import a3d.core.managers.Stage3DProxy;

import haxe.ds.WeakMap;


/**
 * ...
 */
class ParticleVelocityState extends ParticleStateBase
{
	private var _particleVelocityNode:ParticleVelocityNode;
	private var _velocity:Vector3D;

	/**
	 * Defines the default velocity vector of the state, used when in global mode.
	 */
	public var velocity(get,set):Vector3D;
	private function get_velocity():Vector3D
	{
		return _velocity;
	}

	private function set_velocity(value:Vector3D):Vector3D
	{
		return _velocity = value;
	}

	/**
	 *
	 */
	public function getVelocities():Vector<Vector3D>
	{
		return _dynamicProperties;
	}

	public function setVelocities(value:Vector<Vector3D>):Void
	{
		_dynamicProperties = value;

		_dynamicPropertiesDirty = new WeakMap<AnimationSubGeometry,Bool>();
	}

	public function new(animator:ParticleAnimator, particleVelocityNode:ParticleVelocityNode)
	{
		super(animator, particleVelocityNode);

		_particleVelocityNode = particleVelocityNode;
		_velocity = _particleVelocityNode.velocity;
	}

	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		if (_particleVelocityNode.mode == ParticlePropertiesMode.LOCAL_DYNAMIC && 
			!_dynamicPropertiesDirty.exists(animationSubGeometry))
		{
			updateDynamicProperties(animationSubGeometry);
		}
			

		var index:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleVelocityNode.VELOCITY_INDEX);

		if (_particleVelocityNode.mode == ParticlePropertiesMode.GLOBAL)
			animationRegisterCache.setVertexConst(index, _velocity.x, _velocity.y, _velocity.z);
		else
			animationSubGeometry.activateVertexBuffer(index, _particleVelocityNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
	}
}
