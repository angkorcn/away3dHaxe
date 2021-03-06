package away3d.animators.nodes
{
	import flash.geom.Vector3D;

	
	import away3d.animators.IAnimator;
	import away3d.animators.ParticleAnimationSet;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ParticleProperties;
	import away3d.animators.data.ParticlePropertiesMode;
	import away3d.animators.states.ParticleSpriteSheetState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;

	

	/**
	 * A particle animation node used when a spritesheet texture is required to animate the particle.
	 * NB: to enable use of this node, the <code>repeat</code> property on the material has to be set to true.
	 */
	public class ParticleSpriteSheetNode extends ParticleNodeBase
	{
		/** @private */
		public static const UV_INDEX_0:uint = 0;

		/** @private */
		public static const UV_INDEX_1:uint = 1;

		/** @private */
		public var usesCycle:Boolean;

		/** @private */
		public var usesPhase:Boolean;

		/** @private */
		private var _totalFrames:int;
		/** @private */
		public var numColumns:int;
		/** @private */
		public var numRows:int;
		/** @private */
		public var cycleDuration:Number;
		/** @private */
		public var cyclePhase:Number;

		/**
		 * Reference for spritesheet node properties on a single particle (when in local property mode).
		 * Expects a <code>Vector3D</code> representing the cycleDuration (x), optional phaseTime (y).
		 */
		public static const UV_VECTOR3D:String = "UVVector3D";

		/**
		 * Defines the number of columns in the spritesheet, when in global mode. Defaults to 1. Read only.
		 */
		public function get numColumns():Number
		{
			return numColumns;
		}

		/**
		 * Defines the number of rows in the spritesheet, when in global mode. Defaults to 1. Read only.
		 */
		public function get numRows():Number
		{
			return numRows;
		}

		/**
		 * Defines the total number of frames used by the spritesheet, when in global mode. Defaults to the number defined by numColumns and numRows. Read only.
		 */
		public function get totalFrames():Number
		{
			return _totalFrames;
		}

		/**
		 * Creates a new <code>ParticleSpriteSheetNode</code>
		 *
		 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
		 * @param    [optional] numColumns      Defines the number of columns in the spritesheet, when in global mode. Defaults to 1.
		 * @param    [optional] numRows         Defines the number of rows in the spritesheet, when in global mode. Defaults to 1.
		 * @param    [optional] cycleDuration   Defines the default cycle duration in seconds, when in global mode. Defaults to 1.
		 * @param    [optional] cyclePhase      Defines the default cycle phase, when in global mode. Defaults to 0.
		 * @param    [optional] totalFrames     Defines the total number of frames used by the spritesheet, when in global mode. Defaults to the number defined by numColumns and numRows.
		 * @param    [optional] looping         Defines whether the spritesheet animation is set to loop indefinitely. Defaults to true.
		 */
		public function ParticleSpriteSheetNode(mode:uint, usesCycle:Boolean, usesPhase:Boolean, numColumns:int = 1, numRows:uint = 1, cycleDuration:Number = 1, cyclePhase:Number = 0, totalFrames:uint =
			uint.MAX_VALUE)
		{
			var len:int;
			if (usesCycle)
			{
				len = 2;
				if (usesPhase)
					len++;
			}
			super("ParticleSpriteSheet", mode, len, ParticleAnimationSet.POST_PRIORITY + 1);

			_stateClass = ParticleSpriteSheetState;

			this.usesCycle = usesCycle;
			this.usesPhase = usesPhase;

			this.numColumns = numColumns;
			this.numRows = numRows;
			this.cyclePhase = cyclePhase;
			this.cycleDuration = cycleDuration;
			this._totalFrames = Math.min(totalFrames, numColumns * numRows);
		}

		/**
		 * @inheritDoc
		 */
		override public function getAGALUVCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
		{
			pass = pass;

			//get 2 vc
			var uvParamConst1:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
			var uvParamConst2:ShaderRegisterElement = (_mode == ParticlePropertiesMode.GLOBAL) ? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
			animationRegisterCache.setRegisterIndex(this, UV_INDEX_0, uvParamConst1.index);
			animationRegisterCache.setRegisterIndex(this, UV_INDEX_1, uvParamConst2.index);

			var uTotal:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, 0);
			var uStep:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, 1);
			var vStep:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, 2);

			var uSpeed:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst2.regName, uvParamConst2.index, 0);
			var cycle:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst2.regName, uvParamConst2.index, 1);
			var phaseTime:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst2.regName, uvParamConst2.index, 2);


			var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var time:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 0);
			var vOffset:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 1);
			temp = new ShaderRegisterElement(temp.regName, temp.index, 2);
			var temp2:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 3);


			var u:ShaderRegisterElement = new ShaderRegisterElement(animationRegisterCache.uvTarget.regName, animationRegisterCache.uvTarget.index, 0);
			var v:ShaderRegisterElement = new ShaderRegisterElement(animationRegisterCache.uvTarget.regName, animationRegisterCache.uvTarget.index, 1);

			var code:String = "";
			//scale uv
			code += "mul " + u + "," + u + "," + uStep + "\n";
			if (numRows > 1)
				code += "mul " + v + "," + v + "," + vStep + "\n";

			if (usesCycle)
			{
				if (usesPhase)
					code += "add " + time + "," + animationRegisterCache.vertexTime + "," + phaseTime + "\n";
				else
					code += "mov " + time + "," + animationRegisterCache.vertexTime + "\n";
				code += "div " + time + "," + time + "," + cycle + "\n";
				code += "frc " + time + "," + time + "\n";
				code += "mul " + time + "," + time + "," + cycle + "\n";
				code += "mul " + temp + "," + time + "," + uSpeed + "\n";
			}
			else
			{
				code += "mul " + temp.toString() + "," + animationRegisterCache.vertexLife + "," + uTotal + "\n";
			}



			if (numRows > 1)
			{
				code += "frc " + temp2 + "," + temp + "\n";
				code += "sub " + vOffset + "," + temp + "," + temp2 + "\n";
				code += "mul " + vOffset + "," + vOffset + "," + vStep + "\n";
				code += "add " + v + "," + v + "," + vOffset + "\n";
			}

			code += "div " + temp2 + "," + temp + "," + uStep + "\n";
			code += "frc " + temp + "," + temp2 + "\n";
			code += "sub " + temp2 + "," + temp2 + "," + temp + "\n";
			code += "mul " + temp + "," + temp2 + "," + uStep + "\n";

			if (numRows > 1)
				code += "frc " + temp + "," + temp + "\n";
			code += "add " + u + "," + u + "," + temp + "\n";

			return code;
		}

		/**
		 * @inheritDoc
		 */
		public function getAnimationState(animator:IAnimator):ParticleSpriteSheetState
		{
			return animator.getAnimationState(this) as ParticleSpriteSheetState;
		}

		/**
		 * @inheritDoc
		 */
		override public function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):void
		{
			particleAnimationSet.hasUVNode = true;
		}

		/**
		 * @inheritDoc
		 */
		override public function generatePropertyOfOneParticle(param:ParticleProperties):void
		{
			if (usesCycle)
			{
				var uvCycle:Vector3D = param[UV_VECTOR3D];
				if (!uvCycle)
					throw(new Error("there is no " + UV_VECTOR3D + " in param!"));
				if (uvCycle.x <= 0)
					throw(new Error("the cycle duration must be greater than zero"));
				var uTotal:Number = _totalFrames / numColumns;
				_oneData[0] = uTotal / uvCycle.x;
				_oneData[1] = uvCycle.x;
				if (usesPhase)
					_oneData[2] = uvCycle.y;
			}
		}
	}
}
