/*

Interactive pool using the Shallow Water Equations

Demonstrates:

How to create and deform a surface
How to apply an enviroment map to a material.
How to use 3D mouse events to return the local coordinate of a surface.
How to use the Shallow Water Equations to produce a convincing water effect.

Code by Rob Bateman, David Lenaerts & Alejadro Santander
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk
david.lenaerts@gmail.com
http://www.derschmale.com
Alejandro Santander
http://www.lidev.com.ar/

This code is distributed under the MIT License

Copyright (c) The Away Foundation http://www.theawayfoundation.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

package example
{
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.ColorTransform;
	import flash.ui.Keyboard;
	import flash.utils.Timer;

	import away3d.controllers.HoverController;
	import away3d.core.base.SubGeometry;
	import away3d.core.pick.PickingColliderType;
	import away3d.entities.Mesh;
	import away3d.events.MouseEvent3D;
	import away3d.entities.lights.PointLight;
	import away3d.materials.ColorMaterial;
	import away3d.materials.TextureMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.materials.methods.BasicDiffuseMethod;
	import away3d.materials.methods.EnvMapMethod;
	import away3d.materials.methods.FogMethod;
	import away3d.entities.primitives.CubeGeometry;
	import away3d.entities.primitives.PlaneGeometry;
	import away3d.entities.primitives.SkyBox;
	import away3d.textures.BitmapCubeTexture;
	import away3d.textures.BitmapTexture;
	import away3d.utils.Cast;

	import example.shallowwater.DisturbanceBrush;
	import example.shallowwater.FluidDisturb;
	import example.shallowwater.ShallowFluid;

	import uk.co.soulwire.gui.SimpleGUI;

	public class Advanced_ShallowWaterDemo extends BasicApplication
	{
		// Environment map.
		[Embed(source = "../embeds/skybox/snow_positive_x.jpg")]
		private var EnvPosX:Class;
		[Embed(source = "../embeds/skybox/snow_positive_y.jpg")]
		private var EnvPosY:Class;
		[Embed(source = "../embeds/skybox/snow_positive_z.jpg")]
		private var EnvPosZ:Class;
		[Embed(source = "../embeds/skybox/snow_negative_x.jpg")]
		private var EnvNegX:Class;
		[Embed(source = "../embeds/skybox/snow_negative_y.jpg")]
		private var EnvNegY:Class;
		[Embed(source = "../embeds/skybox/snow_negative_z.jpg")]
		private var EnvNegZ:Class;

		// Liquid image assets.
		[Embed(source = "../embeds/assets.swf", symbol = "ImageClip")]
		private var ImageClip:Class;
		[Embed(source = "../embeds/assets.swf", symbol = "ImageClip1")]
		private var ImageClip1:Class;
		[Embed(source = "../embeds/assets.swf", symbol = "ImageClip2")]
		private var ImageClip2:Class;

		// Disturbance brushes.
		[Embed(source = "../embeds/assets.swf", symbol = "Brush1")]
		private var Brush1:Class;
		[Embed(source = "../embeds/assets.swf", symbol = "Brush2")]
		private var Brush2:Class;
		[Embed(source = "../embeds/assets.swf", symbol = "Brush3")]
		private var Brush3:Class;
		[Embed(source = "../embeds/assets.swf", symbol = "Brush4")]
		private var Brush4:Class;
		[Embed(source = "../embeds/assets.swf", symbol = "Brush5")]
		private var Brush5:Class;
		[Embed(source = "../embeds/assets.swf", symbol = "Brush6")]
		private var Brush6:Class;

		//engine variables
		private var cameraController:HoverController;

		//light objects
		private var skyLight:PointLight;
		private var lightPicker:StaticLightPicker;
		private var fogMethod:FogMethod;

		//material objects
		private var colorMaterial:ColorMaterial;
		private var liquidMaterial:ColorMaterial;
		private var poolMaterial:TextureMaterial;
		private var cubeTexture:BitmapCubeTexture;

		//fluid simulation variables
		private var gridDimension:uint = 200;
		private var gridSpacing:uint = 2;
		private var planeSize:Number;


		//scene objects
		public var fluid:ShallowFluid;
		private var plane:Mesh;
		private var fluidDisturb:FluidDisturb;
		private var gui:SimpleGUI;

		//gui variables

		private var rainBrush:DisturbanceBrush;
		private var imageBrush:DisturbanceBrush;
		private var mouseBrush:DisturbanceBrush;
		private var showingLiquidImage:Boolean;
		private var showingLiquidImage1:Boolean;
		private var showingLiquidImage2:Boolean;
		private var aMouseBrushClip:Sprite;


		//interaction variables
		private var dropTmr:Timer;
		private var rain:Boolean;
		private var liquidShading:Boolean = true;
		private var planeDisturb:Boolean = false;
		private var planeX:Number;
		private var planeY:Number;

		//navigation variables
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		private var tiltSpeed:Number = 2;
		private var panSpeed:Number = 2;
		private var distanceSpeed:Number = 2;
		private var tiltIncrement:Number = 0;
		private var panIncrement:Number = 0;
		private var distanceIncrement:Number = 0;

		/**
		 * GUI property for controlling the strength of the displacement brush on the mouse
		 */
		public var mouseBrushStrength:Number = 5;

		/**
		 * GUI property for controlling the life of the displacement brush on the mouse
		 */
		public var mouseBrushLife:uint = 0;

		/**
		 * GUI property for controlling the strength of the displacement brush on the rain
		 */
		public var rainBrushStrength:Number = 10;

		/**
		 * GUI property for controlling the active displacement brush on the mouse
		 */
		public function set activeMouseBrushClip(value:Sprite):void
		{
			aMouseBrushClip = value;
			mouseBrush.fromSprite(aMouseBrushClip, 2);
		}

		public function get activeMouseBrushClip():Sprite
		{
			return aMouseBrushClip;
		}

		/**
		 * GUI property for controlling the rate of rain
		 */
		public function set rainTime(delay:uint):void
		{
			dropTmr.delay = delay;
		}

		public function get rainTime():uint
		{
			return dropTmr.delay;
		}

		/**
		 * GUI property for toggling shading on the water plane
		 */
		public function set toggleShading(value:Boolean):void
		{
			liquidShading = value;
			if (liquidShading)
				plane.material = liquidMaterial;
			else
				plane.material = colorMaterial;
		}

		public function get toggleShading():Boolean
		{
			return liquidShading;
		}

		/**
		 * GUI property for toggling Away3D text image
		 */
		public function set toggleLiquidImage(value:Boolean):void
		{
			showingLiquidImage = value;
			if (showingLiquidImage)
			{
				imageBrush.fromSprite(new ImageClip() as Sprite);
				fluidDisturb.disturbBitmapMemory(0.5, 0.5, -10, imageBrush.bitmapData, -1, 0.01);
			}
			else
				fluidDisturb.releaseMemoryDisturbances();
		}

		public function get toggleLiquidImage():Boolean
		{
			return showingLiquidImage;
		}

		/**
		 * GUI property for toggling Winston Churchill image
		 */
		public function set toggleLiquidImage1(value:Boolean):void
		{
			showingLiquidImage1 = value;
			if (showingLiquidImage1)
			{
				imageBrush.fromSprite(new ImageClip1() as Sprite);
				fluidDisturb.disturbBitmapMemory(0.5, 0.5, -15, imageBrush.bitmapData, -1, 0.01);
			}
			else
				fluidDisturb.releaseMemoryDisturbances();
		}

		public function get toggleLiquidImage1():Boolean
		{
			return showingLiquidImage1;
		}

		/**
		 * GUI property for toggling Mustang image
		 */

		public function set toggleLiquidImage2(value:Boolean):void
		{
			showingLiquidImage2 = value;
			if (showingLiquidImage2)
			{
				imageBrush.fromSprite(new ImageClip2() as Sprite);
				fluidDisturb.disturbBitmapMemory(0.5, 0.5, -15, imageBrush.bitmapData, -1, 0.01);
			}
			else
			{
				fluidDisturb.releaseMemoryDisturbances();
			}
		}

		public function get toggleLiquidImage2():Boolean
		{
			return showingLiquidImage2;
		}

		/**
		 * GUI property for toggling rain
		 */
		public function set toggleRain(value:Boolean):void
		{
			rain = value;
			if (rain)
				dropTmr.start();
			else
				dropTmr.stop();
		}

		public function get toggleRain():Boolean
		{
			return rain;
		}

		/**
		 * Constructor
		 */
		public function Advanced_ShallowWaterDemo()
		{
			init();
		}

		/**
		 * Global initialise function
		 */
		private function init():void
		{
			initEngine();
			initLights();
			initMaterials();
			initObjects();
			initFluid();
			initGUI();
			initListeners();
		}

		/**
		 * Initialise the engine
		 */
		override protected function initEngine():void
		{
			super.initEngine();

			//setup controller to be used on the camera
			cameraController = new HoverController(camera, null, 180, 20, 320, 5);
		}

		/**
		 * Initialise the lights
		 */
		private function initLights():void
		{
			skyLight = new PointLight();
			skyLight.color = 0x0000FF;
			skyLight.specular = 0.5;
			skyLight.diffuse = 2;
			scene.addChild(skyLight);

			lightPicker = new StaticLightPicker([skyLight]);

			//create a global fog method
			fogMethod = new FogMethod(0, 2500, 0x000000);
		}

		/**
		 * Initialise the material
		 */
		private function initMaterials():void
		{
			cubeTexture = new BitmapCubeTexture(Cast.bitmapData(EnvPosX), Cast.bitmapData(EnvNegX), Cast.bitmapData(EnvPosY), Cast.bitmapData(EnvNegY), Cast.bitmapData(EnvPosZ), Cast.bitmapData(EnvNegZ));

			liquidMaterial = new ColorMaterial(0xFFFFFF);
			liquidMaterial.specular = 0.5;
			liquidMaterial.ambient = 0.25;
			liquidMaterial.ambientColor = 0x111199;
			liquidMaterial.ambient = 1;
			liquidMaterial.addMethod(new EnvMapMethod(cubeTexture, 1));
			liquidMaterial.lightPicker = lightPicker;

			colorMaterial = new ColorMaterial(liquidMaterial.color);
			colorMaterial.specular = 0.5;
			colorMaterial.ambient = 0.25;
			colorMaterial.ambientColor = 0x555555;
			colorMaterial.ambient = 1;
			colorMaterial.diffuseMethod = new BasicDiffuseMethod();
			colorMaterial.lightPicker = lightPicker;

			var tex:BitmapData = new BitmapData(512, 512, false, 0);
			tex.perlinNoise(25, 25, 8, 1, false, true, 7, true);
			tex.colorTransform(tex.rect, new ColorTransform(0.1, 0.1, 0.1, 1, 0, 0, 0, 0));
			poolMaterial = new TextureMaterial(new BitmapTexture(tex));
			poolMaterial.addMethod(fogMethod);

		}

		/**
		 * Initialise the scene objects
		 */
		private function initObjects():void
		{
			//create skybox.
			scene.addChild(new SkyBox(cubeTexture));

			//create water plane.
			var planeSegments:uint = (gridDimension - 1);
			planeSize = planeSegments * gridSpacing;
			plane = new Mesh(new PlaneGeometry(planeSize, planeSize, planeSegments, planeSegments), liquidMaterial);
			plane.rotationX = 90;
			plane.x -= planeSize / 2;
			plane.z -= planeSize / 2;
			plane.mouseEnabled = true;
			plane.pickingCollider = PickingColliderType.BOUNDS_ONLY;
			plane.geometry.convertToSeparateBuffers();
			plane.geometry.subGeometries[0].autoDeriveVertexNormals = false;
			plane.geometry.subGeometries[0].autoDeriveVertexTangents = false;
			scene.addChild(plane);

			//create pool
			var poolHeight:Number = 500000;
			var poolThickness:Number = 5;
			var poolVOffset:Number = 5 - poolHeight / 2;
			var poolHOffset:Number = planeSize / 2 + poolThickness / 2;

			var left:Mesh = new Mesh(new CubeGeometry(poolThickness, poolHeight, planeSize + poolThickness * 2), poolMaterial);
			left.x = -poolHOffset;
			left.y = poolVOffset;
			scene.addChild(left);

			var right:Mesh = new Mesh(new CubeGeometry(poolThickness, poolHeight, planeSize + poolThickness * 2), poolMaterial);
			right.x = poolHOffset;
			right.y = poolVOffset;
			scene.addChild(right);

			var back:Mesh = new Mesh(new CubeGeometry(planeSize, poolHeight, poolThickness), poolMaterial);
			back.z = poolHOffset;
			back.y = poolVOffset;
			scene.addChild(back);

			var front:Mesh = new Mesh(new CubeGeometry(planeSize, poolHeight, poolThickness), poolMaterial);
			front.z = -poolHOffset;
			front.y = poolVOffset;
			scene.addChild(front);
		}

		/**
		 * Initialise the fluid
		 */
		private function initFluid():void
		{
			// Fluid.
			var dt:Number = 1 / stage.frameRate;
			var viscosity:Number = 0.3;
			var waveVelocity:Number = 0.99; // < 1 or the sim will collapse.
			fluid = new ShallowFluid(gridDimension, gridDimension, gridSpacing, dt, waveVelocity, viscosity);

			// Disturbance util.
			fluidDisturb = new FluidDisturb(fluid);

		}

		/**
		 * Initialise the GUI
		 */
		private function initGUI():void
		{
			// Init brush clips.
			var drop:Sprite = new Brush3() as Sprite;

			var brushClips:Array = [
				{label: "drop", data: drop},
				{label: "star", data: new Brush1()},
				{label: "box", data: new Brush2()},
				{label: "triangle", data: new Brush4()},
				{label: "stamp", data: new Brush5()},
				{label: "butter", data: new Brush6()}
				];

			aMouseBrushClip = drop;

			// Init brushes.
			rainBrush = new DisturbanceBrush();
			rainBrush.fromSprite(drop);
			mouseBrush = new DisturbanceBrush();
			mouseBrush.fromSprite(aMouseBrushClip);
			imageBrush = new DisturbanceBrush();
			imageBrush.fromSprite(new ImageClip() as Sprite);

			// Rain.
			dropTmr = new Timer(50);
			dropTmr.addEventListener(TimerEvent.TIMER, onRainTimer);

			gui = new SimpleGUI(this, "");

			gui.addColumn("Instructions");
			var instr:String = "Click and drag on the stage to rotate camera.\n";
			instr += "Click on the fluid to disturb it.\n";
			instr += "Keyboard arrows and WASD also rotate camera.\n";
			instr += "Keyboard Z and X zoom camera.\n";
			gui.addLabel(instr);

			gui.addColumn("Simulation");
			gui.addSlider("fluid.speed", 0.0, 0.95, {label: "speed", tick: 0.01});
			gui.addSlider("fluid.viscosity", 0.0, 1.7, {label: "viscosity", tick: 0.01});
			gui.addToggle("toggleShading", {label: "reflective shading"});


			gui.addColumn("Rain");
			gui.addToggle("toggleRain", {label: "enabled"});
			gui.addSlider("rainTime", 10, 1000, {label: "speed", tick: 10});
			gui.addSlider("rainBrushStrength", 1, 50, {label: "strength", tick: 0.01});

			gui.addColumn("Mouse Brush");
			gui.addComboBox("activeMouseBrushClip", brushClips, {label: "brush"});
			gui.addSlider("mouseBrushStrength", -10, 10, {label: "strength", tick: 0.01});
			gui.addSlider("mouseBrushLife", 0, 10000, {label: "life", tick: 10});

			gui.addColumn("Liquid Image");
			gui.addToggle("toggleLiquidImage", {label: "away"});
			gui.addToggle("toggleLiquidImage2", {label: "mustang"});
			gui.addToggle("toggleLiquidImage1", {label: "winston"});
			gui.show();
		}

		/**
		 * Initialise the listeners
		 */
		override protected function initListeners():void
		{
			super.initListeners();

			plane.addEventListener(MouseEvent3D.MOUSE_MOVE, onPlaneMouseMove);
			plane.addEventListener(MouseEvent3D.MOUSE_DOWN, onPlaneMouseDown);
		}

		private function updatePlaneCoords(x:Number, y:Number):void
		{
			planeX = x / planeSize;
			planeY = y / planeSize;
		}

		/**
		 * Navigation and render loop
		 */
		override protected function render():void
		{
			// Update fluid.
			fluid.evaluate();

			// Update memory disturbances.
			fluidDisturb.updateMemoryDisturbances();

			// Update plane to fluid.
			var subGeometry:SubGeometry = plane.geometry.subGeometries[0] as SubGeometry;
			subGeometry.updateVertexData(fluid.points);
			subGeometry.updateVertexNormalData(fluid.normals);
			subGeometry.updateVertexTangentData(fluid.tangents);

			if (planeDisturb)
			{
				if (mouseBrushLife == 0)
					fluidDisturb.disturbBitmapInstant(planeX, planeY, -mouseBrushStrength, mouseBrush.bitmapData);
				else
					fluidDisturb.disturbBitmapMemory(planeX, planeY, -5 * mouseBrushStrength, mouseBrush.bitmapData, mouseBrushLife, 0.2);
			}
			else if (move)
			{
				cameraController.panAngle = 0.3 * (stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3 * (stage.mouseY - lastMouseY) + lastTiltAngle;
			}

			cameraController.panAngle += panIncrement;
			cameraController.tiltAngle += tiltIncrement;
			cameraController.distance += distanceIncrement;

			// Update light.
			skyLight.transform = camera.transform.clone();

			super.render();
		}

		/**
		 * Key down listener for camera control
		 */
		override protected function onKeyDown(event:KeyboardEvent):void
		{
			switch (event.keyCode)
			{
				case Keyboard.UP:
				case Keyboard.W:
					tiltIncrement = tiltSpeed;
					break;
				case Keyboard.DOWN:
				case Keyboard.S:
					tiltIncrement = -tiltSpeed;
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
					panIncrement = panSpeed;
					break;
				case Keyboard.RIGHT:
				case Keyboard.D:
					panIncrement = -panSpeed;
					break;
				case Keyboard.Z:
					distanceIncrement = distanceSpeed;
					break;
				case Keyboard.X:
					distanceIncrement = -distanceSpeed;
					break;
			}
		}

		/**
		 * Key up listener for camera control
		 */
		override protected function onKeyUp(event:KeyboardEvent):void
		{
			switch (event.keyCode)
			{
				case Keyboard.UP:
				case Keyboard.W:
				case Keyboard.DOWN:
				case Keyboard.S:
					tiltIncrement = 0;
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
				case Keyboard.RIGHT:
				case Keyboard.D:
					panIncrement = 0;
					break;
				case Keyboard.Z:
				case Keyboard.X:
					distanceIncrement = 0;
					break;
			}
		}

		/**
		 * mesh listener for fluid interaction with the mouse
		 */
		private function onPlaneMouseMove(event:MouseEvent3D):void
		{
			if (planeDisturb)
				updatePlaneCoords(event.localPosition.x, event.localPosition.y);
		}

		/**
		 * mesh listener for fluid interaction with the mouse
		 */
		private function onPlaneMouseDown(event:MouseEvent3D):void
		{
			planeDisturb = true;
			updatePlaneCoords(event.localPosition.x, event.localPosition.y);
		}

		/**
		 * Mouse down listener for navigation
		 */
		override protected function onMouseDown(event:MouseEvent):void
		{
			move = true;
			lastPanAngle = cameraController.panAngle;
			lastTiltAngle = cameraController.tiltAngle;
			lastMouseX = stage.mouseX;
			lastMouseY = stage.mouseY;
			stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}

		/**
		 * Mouse up listener for navigation
		 */
		override protected function onMouseUp(event:MouseEvent):void
		{
			move = false;
			planeDisturb = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}

		/**
		 * Mouse stage leave listener for navigation
		 */
		private function onStageMouseLeave(event:Event):void
		{
			move = false;
			planeDisturb = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}

		/**
		 * Timer listener for simulating rain
		 */
		private function onRainTimer(event:TimerEvent):void
		{
			fluidDisturb.disturbBitmapInstant(0.8 * Math.random() + 0.1, 0.8 * Math.random() + 0.1, rainBrushStrength, rainBrush.bitmapData);
		}
	}
}
