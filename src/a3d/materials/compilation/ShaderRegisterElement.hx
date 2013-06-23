package a3d.materials.compilation
{

	/**
	 * A single register element (an entire register or a single register's component) used by the RegisterPool.
	 */
	class ShaderRegisterElement
	{
		private var _regName:String;
		private var _index:Int;
		private var _toStr:String;

		private static inline var COMPONENTS:Array = ["x", "y", "z", "w"];

		internal var _component:Int;

		/**
		 * Creates a new ShaderRegisterElement object.
		 * @param regName The name of the register.
		 * @param index The index of the register.
		 * @param component The register's component, if not the entire register is represented.
		 */
		public function ShaderRegisterElement(regName:String, index:Int, component:Int = -1)
		{
			_component = component;
			_regName = regName;
			_index = index;

			_toStr = _regName;

			if (_index >= 0)
				_toStr += _index;

			if (component > -1)
				_toStr += "." + COMPONENTS[component];
		}

		/**
		 * Converts the register or the components AGAL string representation.
		 */
		public function toString():String
		{
			return _toStr;
		}

		/**
		 * The register's name.
		 */
		private inline function get_regName():String
		{
			return _regName;
		}

		/**
		 * The register's index.
		 */
		private inline function get_index():Int
		{
			return _index;
		}

	/**
	 * The register's component, if not the entire register is represented.
	 */
	}
}
