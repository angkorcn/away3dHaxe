package away3d.animators.nodes
{
	
	import away3d.animators.IAnimator;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ParticleProperties;
	import away3d.animators.data.ParticlePropertiesMode;
	import away3d.animators.states.ParticleTimeState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;

	

	/**
	 * A particle animation node used as the base node for timekeeping inside a particle. Automatically added to a particle animation set on instatiation.
	 */
	public class ParticleTimeNode extends ParticleNodeBase
	{
		/** @private */
		public static const TIME_STREAM_INDEX:uint = 0;

		/** @private */
		public static const TIME_CONSTANT_INDEX:uint = 1;

		/** @private */
		public var usesDuration:Boolean;
		/** @private */
		public var usesDelay:Boolean;
		/** @private */
		public var usesLooping:Boolean;

		/**
		 * Creates a new <code>ParticleTimeNode</code>
		 *
		 * @param    [optional] usesDuration    Defines whether the node uses the <code>duration</code> data in the static properties function to determine how long a particle is visible for. Defaults to false.
		 * @param    [optional] usesDelay       Defines whether the node uses the <code>delay</code> data in the static properties function to determine how long a particle is hidden for. Defaults to false. Requires <code>usesDuration</code> to be true.
		 * @param    [optional] usesLooping     Defines whether the node creates a looping timeframe for each particle determined by the <code>startTime</code>, <code>duration</code> and <code>delay</code> data in the static properties function. Defaults to false. Requires <code>usesLooping</code> to be true.
		 */
		public function ParticleTimeNode(usesDuration:Boolean = false, usesLooping:Boolean = false, usesDelay:Boolean = false)
		{
			_stateClass = ParticleTimeState;

			this.usesDuration = usesDuration;
			this.usesLooping = usesLooping;
			this.usesDelay = usesDelay;

			super("ParticleTime", ParticlePropertiesMode.LOCAL_STATIC, 4, 0);
		}

		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
		{
			pass = pass;
			var timeStreamRegister:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute(); //timeStreamRegister.x is start，timeStreamRegister.y is during time
			animationRegisterCache.setRegisterIndex(this, TIME_STREAM_INDEX, timeStreamRegister.index);
			var timeConst:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, TIME_CONSTANT_INDEX, timeConst.index);

			var code:String = "";
			code += "sub " + animationRegisterCache.vertexTime + "," + timeConst + "," + timeStreamRegister + ".x\n";
			//if time=0,set the position to zero.
			var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexSingleTemp();
			code += "sge " + temp + "," + animationRegisterCache.vertexTime + "," + animationRegisterCache.vertexZeroConst + "\n";
			code += "mul " + animationRegisterCache.scaleAndRotateTarget + ".xyz," + animationRegisterCache.scaleAndRotateTarget + ".xyz," + temp + "\n";
			if (usesDuration)
			{
				if (usesLooping)
				{
					var div:ShaderRegisterElement = animationRegisterCache.getFreeVertexSingleTemp();
					if (usesDelay)
					{
						code += "div " + div + "," + animationRegisterCache.vertexTime + "," + timeStreamRegister + ".z\n";
						code += "frc " + div + "," + div + "\n";
						code += "mul " + animationRegisterCache.vertexTime + "," + div + "," + timeStreamRegister + ".z\n";
						code += "slt " + div + "," + animationRegisterCache.vertexTime + "," + timeStreamRegister + ".y\n";
						code += "mul " + animationRegisterCache.scaleAndRotateTarget + ".xyz," + animationRegisterCache.scaleAndRotateTarget + ".xyz," + div + "\n";
					}
					else
					{
						code += "mul " + div + "," + animationRegisterCache.vertexTime + "," + timeStreamRegister + ".w\n";
						code += "frc " + div + "," + div + "\n";
						code += "mul " + animationRegisterCache.vertexTime + "," + div + "," + timeStreamRegister + ".y\n";
					}
				}
				else
				{
					var sge:ShaderRegisterElement = animationRegisterCache.getFreeVertexSingleTemp();
					code += "sge " + sge + "," + timeStreamRegister + ".y," + animationRegisterCache.vertexTime + "\n";
					code += "mul " + animationRegisterCache.scaleAndRotateTarget + ".xyz," + animationRegisterCache.scaleAndRotateTarget + ".xyz," + sge + "\n";
				}
			}
			code += "mul " + animationRegisterCache.vertexLife + "," + animationRegisterCache.vertexTime + "," + timeStreamRegister + ".w\n";
			return code;
		}

		/**
		 * @inheritDoc
		 */
		public function getAnimationState(animator:IAnimator):ParticleTimeState
		{
			return animator.getAnimationState(this) as ParticleTimeState;
		}

		/**
		 * @inheritDoc
		 */
		override public function generatePropertyOfOneParticle(param:ParticleProperties):void
		{
			_oneData[0] = param.startTime;
			_oneData[1] = param.duration;
			_oneData[2] = param.delay + param.duration;
			_oneData[3] = 1 / param.duration;

		}
	}
}
