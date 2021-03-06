package away3d.controllers
{

	import away3d.entities.Entity;
	import away3d.math.MathUtil;



	/**
	 * Extended camera used to hover round a specified target object.
	 *
	 * @see	away3d.containers.View3D
	 */
	public class FirstPersonController extends ControllerBase
	{
		public var currentPanAngle:Number = 0;
		public var currentTiltAngle:Number = 90;

		private var _panAngle:Number = 0;
		private var _tiltAngle:Number = 90;
		private var _minTiltAngle:Number = -90;
		private var _maxTiltAngle:Number = 90;
		private var _steps:uint = 8;
		private var _walkIncrement:Number = 0;
		private var _strafeIncrement:Number = 0;

		public var fly:Boolean = false;

		/**
		 * Fractional step taken each time the <code>hover()</code> method is called. Defaults to 8.
		 *
		 * Affects the speed at which the <code>tiltAngle</code> and <code>panAngle</code> resolve to their targets.
		 *
		 * @see	#tiltAngle
		 * @see	#panAngle
		 */
		public function get steps():uint
		{
			return _steps;
		}

		public function set steps(val:uint):void
		{
			val = (val < 1) ? 1 : val;

			if (_steps == val)
				return;

			_steps = val;

			notifyUpdate();
		}

		/**
		 * Rotation of the camera in degrees around the y axis. Defaults to 0.
		 */
		public function get panAngle():Number
		{
			return _panAngle;
		}

		public function set panAngle(val:Number):void
		{
			if (_panAngle == val)
				return;

			_panAngle = val;

			notifyUpdate();
		}

		/**
		 * Elevation angle of the camera in degrees. Defaults to 90.
		 */
		public function get tiltAngle():Number
		{
			return _tiltAngle;
		}

		public function set tiltAngle(val:Number):void
		{
			val = Math.max(_minTiltAngle, Math.min(_maxTiltAngle, val));

			if (_tiltAngle == val)
				return;

			_tiltAngle = val;

			notifyUpdate();
		}

		/**
		 * Minimum bounds for the <code>tiltAngle</code>. Defaults to -90.
		 *
		 * @see	#tiltAngle
		 */
		public function get minTiltAngle():Number
		{
			return _minTiltAngle;
		}

		public function set minTiltAngle(val:Number):void
		{
			if (_minTiltAngle == val)
				return;

			_minTiltAngle = val;

			tiltAngle = Math.max(_minTiltAngle, Math.min(_maxTiltAngle, _tiltAngle));
		}

		/**
		 * Maximum bounds for the <code>tiltAngle</code>. Defaults to 90.
		 *
		 * @see	#tiltAngle
		 */
		public function get maxTiltAngle():Number
		{
			return _maxTiltAngle;
		}

		public function set maxTiltAngle(val:Number):void
		{
			if (_maxTiltAngle == val)
				return;

			_maxTiltAngle = val;

			tiltAngle = Math.max(_minTiltAngle, Math.min(_maxTiltAngle, _tiltAngle));
		}

		/**
		 * Creates a new <code>HoverController</code> object.
		 */
		public function FirstPersonController(targetObject:Entity = null, panAngle:Number = 0, tiltAngle:Number = 90, minTiltAngle:Number = -90, maxTiltAngle:Number = 90, steps:uint = 8)
		{
			super(targetObject);

			this.panAngle = panAngle;
			this.tiltAngle = tiltAngle;
			this.minTiltAngle = minTiltAngle;
			this.maxTiltAngle = maxTiltAngle;
			this.steps = steps;

			//values passed in contrustor are applied immediately
			currentPanAngle = _panAngle;
			currentTiltAngle = _tiltAngle;
		}

		/**
		 * Updates the current tilt angle and pan angle values.
		 *
		 * Values are calculated using the defined <code>tiltAngle</code>, <code>panAngle</code> and <code>steps</code> variables.
		 *
		 * @param interpolate   If the update to a target pan- or tiltAngle is interpolated. Default is true.
		 *
		 * @see	#tiltAngle
		 * @see	#panAngle
		 * @see	#steps
		 */
		override public function update(interpolate:Boolean = true):void
		{
			if (_tiltAngle != currentTiltAngle || _panAngle != currentPanAngle)
			{

				notifyUpdate();

				if (interpolate)
				{
					currentTiltAngle += (_tiltAngle - currentTiltAngle) / (steps + 1);
					currentPanAngle += (_panAngle - currentPanAngle) / (steps + 1);
				}
				else
				{
					currentTiltAngle = _tiltAngle;
					currentPanAngle = _panAngle;
				}

				//snap coords if angle differences are close
				if ((Math.abs(tiltAngle - currentTiltAngle) < 0.01) && (Math.abs(_panAngle - currentPanAngle) < 0.01))
				{

					if (Math.abs(_panAngle) > 360)
					{

						if (_panAngle < 0)
							panAngle = (_panAngle % 360) + 360;
						else
							panAngle = _panAngle % 360;
					}

					currentTiltAngle = _tiltAngle;
					currentPanAngle = _panAngle;
				}
			}

			targetObject.rotationX = currentTiltAngle;
			targetObject.rotationY = currentPanAngle;

			if (_walkIncrement)
			{
				if (fly)
				{
					targetObject.moveForward(_walkIncrement);
				}
				else
				{
					targetObject.x += _walkIncrement * Math.sin(panAngle * MathUtil.DEGREES_TO_RADIANS);
					targetObject.z += _walkIncrement * Math.cos(panAngle * MathUtil.DEGREES_TO_RADIANS);
				}
				_walkIncrement = 0;
			}

			if (_strafeIncrement)
			{
				targetObject.moveRight(_strafeIncrement);
				_strafeIncrement = 0;
			}

		}

		public function incrementWalk(val:Number):void
		{
			if (val == 0)
				return;

			_walkIncrement += val;

			notifyUpdate();
		}


		public function incrementStrafe(val:Number):void
		{
			if (val == 0)
				return;

			_strafeIncrement += val;

			notifyUpdate();
		}

	}
}
