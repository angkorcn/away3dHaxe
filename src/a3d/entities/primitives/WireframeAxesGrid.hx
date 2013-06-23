﻿package a3d.entities.primitives
{
	import flash.geom.Vector3D;
	
	import a3d.entities.SegmentSet;

	/**
	* Class WireframeAxesGrid generates a grid of lines on a given plane<code>WireframeAxesGrid</code>
	* @param	subDivision			[optional] uint . Default is 10;
	* @param	gridSize			[optional] uint . Default is 100;
	* @param	thickness			[optional] Number . Default is 1;
	* @param	colorXY				[optional] uint. Default is 0x0000FF.
	* @param	colorZY				[optional] uint. Default is 0xFF0000. 
	* @param	colorXZ				[optional] uint. Default is 0x00FF00.
	*/

	class WireframeAxesGrid extends SegmentSet
	{
		private static inline var PLANE_ZY:String = "zy";
		private static inline var PLANE_XY:String = "xy";
		private static inline var PLANE_XZ:String = "xz";

		public function WireframeAxesGrid(subDivision:UInt = 10, gridSize:UInt = 100, thickness:Float = 1, colorXY : uint = 0x0000FF, colorZY : uint = 0xFF0000, colorXZ : uint = 0x00FF00) {
			super();

			if(subDivision == 0) subDivision = 1;
			if(thickness <= 0) thickness = 1;
			if(gridSize ==  0) gridSize = 1;

			build(subDivision, gridSize, colorXY, thickness, PLANE_XY);
			build(subDivision, gridSize, colorZY, thickness, PLANE_ZY);
			build(subDivision, gridSize, colorXZ, thickness, PLANE_XZ);
		}

		private function build(subDivision:UInt, gridSize:UInt, color:UInt, thickness:Float, plane:String):Void
		{
			var bound:Float = gridSize *.5;
			var step:Float = gridSize/subDivision;
			var v0 : Vector3D = new Vector3D(0, 0, 0) ;
			var v1 : Vector3D = new Vector3D(0, 0, 0) ;
			var inc:Float = -bound;

			while(inc<=bound){

				switch(plane){
					case PLANE_ZY:
						v0.x = 0;
						v0.y = inc;
						v0.z = bound;
						v1.x = 0;
						v1.y = inc;
						v1.z = -bound;
						addSegment( new LineSegment(v0, v1, color, color, thickness));

						v0.z = inc;
						v0.x = 0;
						v0.y = bound;
						v1.x = 0;
						v1.y = -bound;
						v1.z = inc;
						addSegment(new LineSegment(v0, v1, color, color, thickness ));
						
					case PLANE_XY:
						v0.x = bound;
						v0.y = inc;
						v0.z = 0;
						v1.x = -bound;
						v1.y = inc;
						v1.z = 0;
						addSegment( new LineSegment(v0, v1, color, color, thickness));
						v0.x = inc;
						v0.y = bound;
						v0.z = 0;
						v1.x = inc;
						v1.y = -bound;
						v1.z = 0;
						addSegment(new LineSegment(v0, v1, color, color, thickness ));
						
					default:
						v0.x = bound;
						v0.y = 0;
						v0.z = inc;
						v1.x = -bound;
						v1.y = 0;
						v1.z = inc;
						addSegment( new LineSegment(v0, v1, color, color, thickness));

						v0.x = inc;
						v0.y = 0;
						v0.z = bound;
						v1.x = inc;
						v1.y = 0;
						v1.z = -bound;
						addSegment(new LineSegment(v0, v1, color, color, thickness ));
				}

				inc += step;
			}
		}

	}
}