/*

Dynamic tree generation and placement in a night-time scene

Demonstrates:

How to create a height map and splat map from scratch to use for realistic terrain
How to use fratacl algorithms to create a custom tree-generating geometry primitive
How to save GPU memory by cloning complex.

Code by Rob Bateman & Alejadro Santander
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk
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

	import com.bit101.components.Label;

	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.BlurFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.ui.Keyboard;
	import flash.utils.Timer;

	import away3d.controllers.HoverController;
	import away3d.entities.Mesh;
	import away3d.entities.extrusions.Elevation;
	import away3d.entities.lights.DirectionalLight;
	import away3d.entities.lights.PointLight;
	import away3d.materials.TextureMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.materials.methods.BasicDiffuseMethod;
	import away3d.materials.methods.BasicSpecularMethod;
	import away3d.materials.methods.FogMethod;
	import away3d.materials.methods.TerrainDiffuseMethod;
	import away3d.entities.primitives.Foliage;
	import away3d.entities.primitives.FractalTreeRound;
	import away3d.entities.primitives.SkyBox;
	import away3d.textures.BitmapCubeTexture;
	import away3d.textures.BitmapTexture;
	import away3d.utils.Cast;

	import uk.co.soulwire.gui.SimpleGUI;

	public class Advanced_FractalTreeDemo extends BasicApplication
	{
		//skybox
		[Embed(source = "../embeds/skybox/grimnight_posX.png")]
		private var EnvPosX:Class;
		[Embed(source = "../embeds/skybox/grimnight_posY.png")]
		private var EnvPosY:Class;
		[Embed(source = "../embeds/skybox/grimnight_posZ.png")]
		private var EnvPosZ:Class;
		[Embed(source = "../embeds/skybox/grimnight_negX.png")]
		private var EnvNegX:Class;
		[Embed(source = "../embeds/skybox/grimnight_negY.png")]
		private var EnvNegY:Class;
		[Embed(source = "../embeds/skybox/grimnight_negZ.png")]
		private var EnvNegZ:Class;

		//tree diffuse map
		[Embed(source = "../embeds/tree/bark0.jpg")]
		public var TrunkDiffuse:Class;

		//tree normal map
		[Embed(source = "../embeds/tree/barkNRM.png")]
		public var TrunkNormals:Class;

		//tree specular map
		[Embed(source = "../embeds/tree/barkSPEC.png")]
		public var TrunkSpecular:Class;

		//leaf diffuse map
		[Embed(source = "../embeds/tree/leaf4.jpg")]
		public var LeafDiffuse:Class;

		//splat texture maps
		[Embed(source = "../embeds/terrain/grass.jpg")]
		private var Grass:Class;
		[Embed(source = "../embeds/terrain/rock.jpg")]
		private var Rock:Class;

		//engine variables
		private var cameraController:HoverController;

		//light objects
		private var moonLight:DirectionalLight;
		private var cameraLight:PointLight;
		private var skyLight:DirectionalLight;
		private var lightPicker:StaticLightPicker;
		private var fogMethod:FogMethod;

		//material objects
		private var heightMapData:BitmapData;
		private var blendBitmapData:BitmapData;
		private var destPoint:Point = new Point();
		private var blendTexture:BitmapTexture;
		private var terrainMethod:TerrainDiffuseMethod;
		private var terrainMaterial:TextureMaterial;
		private var trunkMaterial:TextureMaterial;
		private var leafMaterial:TextureMaterial;
		private var cubeTexture:BitmapCubeTexture;

		//scene objects
		private var terrain:Elevation;
		private var tree:Mesh;
		private var foliage:Mesh;
		private var gui:SimpleGUI;

		//navigation variables
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		private var tiltSpeed:Number = 2;
		private var panSpeed:Number = 2;
		private var distanceSpeed:Number = 1000;
		private var tiltIncrement:Number = 0;
		private var panIncrement:Number = 0;
		private var distanceIncrement:Number = 0;

		//gui objects
		private var treeCountLabel:Label;
		private var polyCountLabel:Label;
		private var terrainPolyCountLabel:Label;
		private var treePolyCountLabel:Label;

		//tree configuration variables
		private var treeLevel:uint = 10;
		private var treeCount:uint = 25;
		private var treeTimer:Timer;
		private var treeDelay:uint = 0;
		private var treeSize:Number = 1000;
		private var treeMin:Number = 0.75;
		private var treeMax:Number = 1.25;

		//foliage configuration variables
		private var leafSize:Number = 300;
		private var leavesPerCluster:uint = 5;
		private var leafClusterRadius:Number = 400;

		//terrain configuration variables
		private var terrainY:Number = -10000;
		private var terrainWidth:Number = 200000;
		private var terrainHeight:Number = 50000;
		private var terrainDepth:Number = 200000;

		private var currentTreeCount:uint;
		private var polyCount:uint;
		private var terrainPolyCount:uint;
		private var treePolyCount:uint;
		private var clonesCreated:Boolean;

		public var minAperture:Number = 0.4;
		public var maxAperture:Number = 0.5;
		public var minTwist:Number = 0.3;
		public var maxTwist:Number = 0.6;

		/**
		 * Constructor
		 */
		public function Advanced_FractalTreeDemo()
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
			initGUI();
			initListeners();
		}

		/**
		 * Initialise the engine
		 */
		override protected function initEngine():void
		{
			super.initEngine();

			camera.lens.far = 1000000;

			//setup controller to be used on the camera
			cameraController = new HoverController(camera, null, 0, 10, 25000, 0, 70);
		}

		/**
		 * Initialise the lights
		 */
		private function initLights():void
		{
			moonLight = new DirectionalLight();
			moonLight.position = new Vector3D(3500, 4500, 10000); // Appear to come from the moon in the sky box.
			moonLight.lookAt(new Vector3D(0, 0, 0));
			moonLight.diffuse = 0.5;
			moonLight.specular = 0.25;
			moonLight.color = 0xFFFFFF;
			scene.addChild(moonLight);
			cameraLight = new PointLight();
			cameraLight.diffuse = 0.25;
			cameraLight.specular = 0.25;
			cameraLight.color = 0xFFFFFF;
			cameraLight.radius = 1000;
			cameraLight.fallOff = 2000;
			scene.addChild(cameraLight);
			skyLight = new DirectionalLight();
			skyLight.diffuse = 0.1;
			skyLight.specular = 0.1;
			skyLight.color = 0xFFFFFF;
			scene.addChild(skyLight);

			lightPicker = new StaticLightPicker([moonLight, cameraLight, skyLight]);

			//create a global fog method
			fogMethod = new FogMethod(0, 200000, 0x000000);
		}

		/**
		 * Initialise the material
		 */
		private function initMaterials():void
		{
			//create skybox texture
			cubeTexture = new BitmapCubeTexture(Cast.bitmapData(EnvPosX), Cast.bitmapData(EnvNegX), Cast.bitmapData(EnvPosY), Cast.bitmapData(EnvNegY), Cast.bitmapData(EnvPosZ), Cast.bitmapData(EnvNegZ));

			//create tree material
			trunkMaterial = new TextureMaterial(Cast.bitmapTexture(TrunkDiffuse));
			trunkMaterial.normalMap = Cast.bitmapTexture(TrunkNormals);
			trunkMaterial.specularMap = Cast.bitmapTexture(TrunkSpecular);
			trunkMaterial.diffuseMethod = new BasicDiffuseMethod();
			trunkMaterial.specularMethod = new BasicSpecularMethod();
			trunkMaterial.addMethod(fogMethod);
			trunkMaterial.lightPicker = lightPicker;

			//create leaf material
			leafMaterial = new TextureMaterial(Cast.bitmapTexture(LeafDiffuse));
			leafMaterial.addMethod(fogMethod);
			leafMaterial.lightPicker = lightPicker;

			//create height map
			heightMapData = new BitmapData(512, 512, false, 0x0);
			heightMapData.perlinNoise(200, 200, 4, uint(1000 * Math.random()), false, true, 7, true);
			heightMapData.draw(createGradientSprite(512, 512, 1, 0));

			//create terrain diffuse method
			blendBitmapData = new BitmapData(heightMapData.width, heightMapData.height, false, 0x000000);
			blendBitmapData.threshold(heightMapData, blendBitmapData.rect, destPoint, ">", 0x444444, 0xFFFF0000, 0xFFFFFF, false);
			blendBitmapData.applyFilter(blendBitmapData, blendBitmapData.rect, destPoint, new BlurFilter(16, 16, 3));
			blendTexture = new BitmapTexture(blendBitmapData);
			terrainMethod = new TerrainDiffuseMethod([Cast.bitmapTexture(Rock)], blendTexture, [20, 20]);

			//create terrain material
			terrainMaterial = new TextureMaterial(Cast.bitmapTexture(Grass));
			terrainMaterial.diffuseMethod = terrainMethod;
			terrainMaterial.addMethod(new FogMethod(0, 200000, 0x000000)); //TODO: global fog method affects splats when updated
			terrainMaterial.lightPicker = lightPicker;
		}

		/**
		 * Initialise the scene objects
		 */
		private function initObjects():void
		{
			//create skybox.
			scene.addChild(new SkyBox(cubeTexture));



			//create terrain
			terrain = new Elevation(terrainMaterial, heightMapData, terrainWidth, terrainHeight, terrainDepth, 65, 65);
			terrain.y = terrainY;
			//terrain.smoothHeightMap();
			scene.addChild(terrain);

			terrainPolyCount = terrain.geometry.subGeometries[0].vertexData.length / 3;
			polyCount += terrainPolyCount;
		}

		/**
		 * Initialise the GUI
		 */
		private function initGUI():void
		{
			gui = new SimpleGUI(this);

			gui.addColumn("Instructions");
			var instr:String = "Click and drag to rotate camera.\n\n";
			instr += "Arrows and WASD also rotate camera.\n\n";
			instr += "Z and X zoom camera.\n\n";
			instr += "Create a tree, then clone it to\n";
			instr += "populate the terrain with trees.\n";
			gui.addLabel(instr);
			gui.addColumn("Tree");
			gui.addSlider("minAperture", 0, 1, {label: "min aperture", tick: 0.01});
			gui.addSlider("maxAperture", 0, 1, {label: "max aperture", tick: 0.01});
			gui.addSlider("minTwist", 0, 1, {label: "min twist", tick: 0.01});
			gui.addSlider("maxTwist", 0, 1, {label: "max twist", tick: 0.01});
			gui.addButton("Generate Fractal Tree", {callback: generateTree, width: 160});
			gui.addColumn("Forest");
			gui.addButton("Clone!", {callback: generateClones});
			treeCountLabel = gui.addControl(Label, {text: "trees: 0"}) as Label;
			polyCountLabel = gui.addControl(Label, {text: "polys: 0"}) as Label;
			treePolyCountLabel = gui.addControl(Label, {text: "polys/tree: 0"}) as Label;
			terrainPolyCountLabel = gui.addControl(Label, {text: "polys/terrain: 0"}) as Label;
			gui.show();

			updateLabels();
		}

		public function generateTree():void
		{
			if (tree)
			{
				currentTreeCount--;
				scene.removeChild(tree);
				tree = null;
			}

			if (foliage)
			{
				scene.removeChild(foliage);
				foliage = null;
			}

			createTreeShadow(0, 0);

			// Create tree.
			var treeGeometry:FractalTreeRound = new FractalTreeRound(treeSize, 10, 3, minAperture, maxAperture, minTwist, maxTwist, treeLevel);
			tree = new Mesh(treeGeometry, trunkMaterial);
			tree.rotationY = 360 * Math.random();
			tree.y = terrain != null ? terrain.y + terrain.getHeightAt(tree.x, tree.z) : 0;
			scene.addChild(tree);

			// Create tree leaves.
			foliage = new Mesh(new Foliage(treeGeometry.leafPositions, leavesPerCluster, leafSize, leafClusterRadius), leafMaterial);
			foliage.x = tree.x;
			foliage.y = tree.y;
			foliage.z = tree.z;
			foliage.rotationY = tree.rotationY;
			scene.addChild(foliage);

			// Count.
			currentTreeCount++;
			treePolyCount = tree.geometry.subGeometries[0].vertexData.length / 3 + foliage.geometry.subGeometries[0].vertexData.length / 3;
			polyCount += treePolyCount;
			updateLabels();
		}

		public function generateClones():void
		{
			if (!tree || clonesCreated)
				return;

			// Start tree creation.
			if (treeCount > 0)
			{
				treeTimer = new Timer(treeDelay, treeCount - 1);
				treeTimer.addEventListener(TimerEvent.TIMER, onTreeTimer);
				treeTimer.start();
			}

			clonesCreated = true;
		}

		private function createTreeShadow(x:Number, z:Number):void
		{
			// Paint on the terrain's shadow blend layer
			var matrix:Matrix = new Matrix();
			var dx:Number = (x / terrainWidth + 0.5) * 512 - 8;
			var dy:Number = (-z / terrainDepth + 0.5) * 512 - 8;
			matrix.translate(dx, dy);
			var treeShadowBitmapData:BitmapData = new BitmapData(16, 16, false, 0x0000FF);
			treeShadowBitmapData.draw(createGradientSprite(16, 16, 0, 1), matrix);
			blendBitmapData.draw(treeShadowBitmapData, matrix, null, BlendMode.ADD);

			// Update the terrain.
			blendTexture.bitmapData = blendBitmapData; // TODO: invalidation routine not active for blending texture
		}

		private function createGradientSprite(width:Number, height:Number, alpha1:Number, alpha2:Number):Sprite
		{
			var gradSpr:Sprite = new Sprite();
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(width, height, 0, 0, 0);
			gradSpr.graphics.beginGradientFill(GradientType.RADIAL, [0xFF000000, 0xFF000000], [alpha1, alpha2], [0, 255], matrix);
			gradSpr.graphics.drawRect(0, 0, width, height);
			gradSpr.graphics.endFill();
			return gradSpr;
		}

		private function updateLabels():void
		{
			treeCountLabel.text = "trees: " + currentTreeCount;
			polyCountLabel.text = "polys: " + polyCount;
			treePolyCountLabel.text = "polys/tree: " + treePolyCount;
			terrainPolyCountLabel.text = "polys/terrain: " + terrainPolyCount;
		}

		/**
		 * Navigation and render loop
		 */
		override protected function render():void
		{
			if (move)
			{
				cameraController.panAngle = 0.3 * (stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3 * (stage.mouseY - lastMouseY) + lastTiltAngle;
			}

			cameraController.panAngle += panIncrement;
			cameraController.tiltAngle += tiltIncrement;
			cameraController.distance += distanceIncrement;

			// Update light.
			cameraLight.transform = camera.transform.clone();

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
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}

		/**
		 * Mouse stage leave listener for navigation
		 */
		private function onStageMouseLeave(event:Event):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}

		/**
		 * stage listener for resize events
		 */
		private function onTreeTimer(event:TimerEvent):void
		{
			//create tree clone.
			var treeClone:Mesh = tree.clone() as Mesh;
			treeClone.x = terrainWidth * Math.random() - terrainWidth / 2;
			treeClone.z = terrainDepth * Math.random() - terrainDepth / 2;
			treeClone.y = terrain != null ? terrain.y + terrain.getHeightAt(treeClone.x, treeClone.z) : 0;
			treeClone.rotationY = 360 * Math.random();
			treeClone.scale((treeMax - treeMin) * Math.random() + treeMin);
			scene.addChild(treeClone);

			//create foliage clone.
			var foliageClone:Mesh = foliage.clone() as Mesh;
			foliageClone.x = treeClone.x;
			foliageClone.y = treeClone.y;
			foliageClone.z = treeClone.z;
			foliageClone.rotationY = treeClone.rotationY;
			foliageClone.scale(treeClone.scaleX);
			scene.addChild(foliageClone);

			//create tree shadow clone.
			createTreeShadow(treeClone.x, treeClone.z);

			//count.
			currentTreeCount++;
			polyCount += treePolyCount;
			updateLabels();
		}

	}
}
