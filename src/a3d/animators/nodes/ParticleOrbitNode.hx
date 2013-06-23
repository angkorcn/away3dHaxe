package a3d.animators.nodes
{
	import flash.geom.Vector3D;

	
	import a3d.animators.IAnimator;
	import a3d.animators.data.AnimationRegisterCache;
	import a3d.animators.data.ParticleProperties;
	import a3d.animators.data.ParticlePropertiesMode;
	import a3d.animators.states.ParticleOrbitState;
	import a3d.materials.compilation.ShaderRegisterElement;
	import a3d.materials.passes.MaterialPassBase;

	

	/**
	 * A particle animation node used to control the position of a particle over time around a circular orbit.
	 */
	class ParticleOrbitNode extends ParticleNodeBase
	{
		/** @private */
		public static inline var ORBIT_INDEX:UInt = 0;

		/** @private */
		public static inline var EULERS_INDEX:UInt = 1;

		/** @private */
		public var usesEulers:Bool;

		/** @private */
		public var usesCycle:Bool;

		/** @private */
		public var usesPhase:Bool;

		/** @private */
		public var radius:Float;
		/** @private */
		public var cycleDuration:Float;
		/** @private */
		public var cyclePhase:Float;
		/** @private */
		public var eulers:Vector3D;

		/**
		 * Reference for orbit node properties on a single particle (when in local property mode).
		 * Expects a <code>Vector3D</code> object representing the radius (x), cycle speed (y) and cycle phase (z) of the motion on the particle.
		 */
		public static inline var ORBIT_VECTOR3D:String = "OrbitVector3D";

		/**
		 * Creates a new <code>ParticleOrbitNode</code> object.
		 *
		 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
		 * @param    [optional] usesEulers      Defines whether the node uses the <code>eulers</code> property in the shader to calculate a rotation on the orbit. Defaults to true.
		 * @param    [optional] usesCycle       Defines whether the node uses the <code>cycleDuration</code> property in the shader to calculate the period of the orbit independent of particle duration. Defaults to false.
		 * @param    [optional] usesPhase       Defines whether the node uses the <code>cyclePhase</code> property in the shader to calculate a starting offset to the cycle rotation of the particle. Defaults to false.
		 * @param    [optional] radius          Defines the radius of the orbit when in global mode. Defaults to 100.
		 * @param    [optional] cycleDuration   Defines the duration of the orbit in seconds, used as a period independent of particle duration when in global mode. Defaults to 1.
		 * @param    [optional] cyclePhase      Defines the phase of the orbit in degrees, used as the starting offset of the cycle when in global mode. Defaults to 0.
		 * @param    [optional] eulers          Defines the euler rotation in degrees, applied to the orientation of the orbit when in global mode.
		 */
		public function ParticleOrbitNode(mode:UInt, usesEulers:Bool = true, usesCycle:Bool = false, usesPhase:Bool = false, radius:Float = 100, cycleDuration:Float = 1, cyclePhase:Float =
			0, eulers:Vector3D = null)
		{
			var len:Int = 3;
			if (usesPhase)
				len++;
			super("ParticleOrbit", mode, len);

			_stateClass = ParticleOrbitState;

			this.usesEulers = usesEulers;
			this.usesCycle = usesCycle;
			this.usesPhase = usesPhase;

			this.radius = radius;
			this.cycleDuration = cycleDuration;
			this.cyclePhase = cyclePhase;
			this.eulers = eulers || new Vector3D();
		}

		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
		{
			pass = pass;

			var orbitRegister:ShaderRegisterElement = (_mode == ParticlePropertiesMode.GLOBAL) ? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
			animationRegisterCache.setRegisterIndex(this, ORBIT_INDEX, orbitRegister.index);

			var eulersMatrixRegister:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, EULERS_INDEX, eulersMatrixRegister.index);
			animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.getFreeVertexConstant();

			var temp1:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			animationRegisterCache.addVertexTempUsages(temp1, 1);
			var distance:ShaderRegisterElement = new ShaderRegisterElement(temp1.regName, temp1.index);


			var temp2:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var cos:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, 0);
			var sin:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, 1);
			var degree:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, 2);
			animationRegisterCache.removeVertexTempUsage(temp1);

			var code:String = "";

			if (usesCycle)
			{
				code += "mul " + degree + "," + animationRegisterCache.vertexTime + "," + orbitRegister + ".y\n";

				if (usesPhase)
					code += "add " + degree + "," + degree + "," + orbitRegister + ".w\n";
			}
			else
			{
				code += "mul " + degree + "," + animationRegisterCache.vertexLife + "," + orbitRegister + ".y\n";
			}

			code += "cos " + cos + "," + degree + "\n";
			code += "sin " + sin + "," + degree + "\n";
			code += "mul " + distance + ".x," + cos + "," + orbitRegister + ".x\n";
			code += "mul " + distance + ".y," + sin + "," + orbitRegister + ".x\n";
			code += "mov " + distance + ".wz" + animationRegisterCache.vertexZeroConst + "\n";
			if (usesEulers)
				code += "m44 " + distance + "," + distance + "," + eulersMatrixRegister + "\n";
			code += "add " + animationRegisterCache.positionTarget + ".xyz," + distance + ".xyz," + animationRegisterCache.positionTarget + ".xyz\n";

			if (animationRegisterCache.needVelocity)
			{
				code += "neg " + distance + ".x," + sin + "\n";
				code += "mov " + distance + ".y," + cos + "\n";
				code += "mov " + distance + ".zw," + animationRegisterCache.vertexZeroConst + "\n";
				if (usesEulers)
					code += "m44 " + distance + "," + distance + "," + eulersMatrixRegister + "\n";
				code += "mul " + distance + "," + distance + "," + orbitRegister + ".z\n";
				code += "div " + distance + "," + distance + "," + orbitRegister + ".y\n";
				if (!usesCycle)
					code += "div " + distance + "," + distance + "," + animationRegisterCache.vertexLife + "\n";
				code += "add " + animationRegisterCache.velocityTarget + ".xyz," + animationRegisterCache.velocityTarget + ".xyz," + distance + ".xyz\n";
			}
			return code;
		}

		/**
		 * @inheritDoc
		 */
		public function getAnimationState(animator:IAnimator):ParticleOrbitState
		{
			return animator.getAnimationState(this) as ParticleOrbitState;
		}

		/**
		 * @inheritDoc
		 */
		override public function generatePropertyOfOneParticle(param:ParticleProperties):Void
		{
			//Vector3D.x is radius, Vector3D.y is cycle duration, Vector3D.z is phase
			var orbit:Vector3D = param[ORBIT_VECTOR3D];
			if (orbit == null)
				throw new Error("there is no " + ORBIT_VECTOR3D + " in param!");

			_oneData[0] = orbit.x;
			if (usesCycle && orbit.y <= 0)
				throw(new Error("the cycle duration must be greater than zero"));
			_oneData[1] = Math.PI * 2 / (!usesCycle ? 1 : orbit.y);
			_oneData[2] = orbit.x * Math.PI * 2;
			if (usesPhase)
				_oneData[3] = orbit.z * Math.PI / 180;
		}
	}
}
