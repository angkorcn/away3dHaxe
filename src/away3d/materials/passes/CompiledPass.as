package away3d.materials.passes
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;


	import away3d.entities.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.errors.AbstractMethodError;
	import away3d.events.ShadingMethodEvent;
	import away3d.materials.LightSources;
	import away3d.materials.MaterialBase;
	import away3d.materials.compilation.ShaderCompiler;
	import away3d.materials.methods.BasicAmbientMethod;
	import away3d.materials.methods.BasicDiffuseMethod;
	import away3d.materials.methods.BasicNormalMethod;
	import away3d.materials.methods.BasicSpecularMethod;
	import away3d.materials.methods.MethodVOSet;
	import away3d.materials.methods.ShaderMethodSetup;
	import away3d.materials.methods.ShadowMapMethodBase;
	import away3d.math.Matrix3DUtils;
	import away3d.textures.Texture2DBase;



	public class CompiledPass extends MaterialPassBase
	{
		//internal use
		public var passes:Vector.<MaterialPassBase>;
		public var passesDirty:Boolean;

		protected var _specularLightSources:uint = 0x01;
		protected var _diffuseLightSources:uint = 0x03;

		protected var _vertexCode:String;
		protected var _fragmentLightCode:String;
		protected var _framentPostLightCode:String;

		protected var _vertexConstantData:Vector.<Number> = new Vector.<Number>();
		protected var _fragmentConstantData:Vector.<Number> = new Vector.<Number>();
		protected var _commonsDataIndex:int;
		protected var _probeWeightsIndex:int;
		protected var _uvBufferIndex:int;
		protected var _secondaryUVBufferIndex:int;
		protected var _normalBufferIndex:int;
		protected var _tangentBufferIndex:int;
		protected var _sceneMatrixIndex:int;
		protected var _sceneNormalMatrixIndex:int;
		protected var _lightFragmentConstantIndex:int;
		protected var _cameraPositionIndex:int;
		protected var _uvTransformIndex:int;
		protected var _lightProbeDiffuseIndices:Vector.<uint>;
		protected var _lightProbeSpecularIndices:Vector.<uint>;

		protected var _ambientLightR:Number;
		protected var _ambientLightG:Number;
		protected var _ambientLightB:Number;

		protected var _compiler:ShaderCompiler;

		protected var _methodSetup:ShaderMethodSetup;

		protected var _usingSpecularMethod:Boolean;
		protected var _usesNormals:Boolean;
		protected var _preserveAlpha:Boolean = true;
		protected var _animateUVs:Boolean;

		protected var _numPointLights:uint;
		protected var _numDirectionalLights:uint;
		protected var _numLightProbes:uint;

		protected var _enableLightFallOff:Boolean = true;

		private var _forceSeparateMVP:Boolean;

		public function CompiledPass(material:MaterialBase)
		{
			_material = material;

			init();
		}

		public function get enableLightFallOff():Boolean
		{
			return _enableLightFallOff;
		}

		public function set enableLightFallOff(value:Boolean):void
		{
			if (value != _enableLightFallOff)
				invalidateShaderProgram(true);
			_enableLightFallOff = value;
		}

		public function get forceSeparateMVP():Boolean
		{
			return _forceSeparateMVP;
		}

		public function set forceSeparateMVP(value:Boolean):void
		{
			_forceSeparateMVP = value;
		}

		public function get numPointLights():uint
		{
			return _numPointLights;
		}

		public function get numDirectionalLights():uint
		{
			return _numDirectionalLights;
		}

		public function get numLightProbes():uint
		{
			return _numLightProbes;
		}

		/**
		 * @inheritDoc
		 */
		override public function updateProgram(stage3DProxy:Stage3DProxy):void
		{
			reset(stage3DProxy.profile);
			super.updateProgram(stage3DProxy);
		}

		/**
		 * Resets the compilation state.
		 */
		private function reset(profile:String):void
		{
			initCompiler(profile);
			updateShaderProperties();
			initConstantData();
			cleanUp();
		}

		private function updateUsedOffsets():void
		{
			_numUsedVertexConstants = _compiler.numUsedVertexConstants;
			_numUsedFragmentConstants = _compiler.numUsedFragmentConstants;
			_numUsedStreams = _compiler.numUsedStreams;
			_numUsedTextures = _compiler.numUsedTextures;
			_numUsedVaryings = _compiler.numUsedVaryings;
			_numUsedFragmentConstants = _compiler.numUsedFragmentConstants;
		}

		private function initConstantData():void
		{
			_vertexConstantData.length = _numUsedVertexConstants * 4;
			_fragmentConstantData.length = _numUsedFragmentConstants * 4;

			initCommonsData();
			if (_uvTransformIndex >= 0)
				initUVTransformData();
			if (_cameraPositionIndex >= 0)
				_vertexConstantData[_cameraPositionIndex + 3] = 1;

			updateMethodConstants();
		}

		protected function initCompiler(profile:String):void
		{
			_compiler = createCompiler(profile);
			_compiler.forceSeperateMVP = _forceSeparateMVP;
			_compiler.numPointLights = _numPointLights;
			_compiler.numDirectionalLights = _numDirectionalLights;
			_compiler.numLightProbes = _numLightProbes;
			_compiler.methodSetup = _methodSetup;
			_compiler.diffuseLightSources = _diffuseLightSources;
			_compiler.specularLightSources = _specularLightSources;
			_compiler.setTextureSampling(_smooth, _repeat, _mipmap);
			_compiler.setConstantDataBuffers(_vertexConstantData, _fragmentConstantData);
			_compiler.animateUVs = _animateUVs;
			_compiler.alphaPremultiplied = _alphaPremultiplied && _enableBlending;
			_compiler.preserveAlpha = _preserveAlpha && _enableBlending;
			_compiler.enableLightFallOff = _enableLightFallOff;
			_compiler.compile();
		}

		protected function createCompiler(profile:String):ShaderCompiler
		{
			throw new AbstractMethodError();
		}

		protected function updateShaderProperties():void
		{
			_animatableAttributes = _compiler.animatableAttributes;
			_animationTargetRegisters = _compiler.animationTargetRegisters;
			_vertexCode = _compiler.vertexCode;
			_fragmentLightCode = _compiler.fragmentLightCode;
			_framentPostLightCode = _compiler.fragmentPostLightCode;
			_shadedTarget = _compiler.shadedTarget;
			_usingSpecularMethod = _compiler.usingSpecularMethod;
			_usesNormals = _compiler.usesNormals;
			_needUVAnimation = _compiler.needUVAnimation;
			_UVSource = _compiler.UVSource;
			_UVTarget = _compiler.UVTarget;

			updateRegisterIndices();
			updateUsedOffsets();
		}

		protected function updateRegisterIndices():void
		{
			_uvBufferIndex = _compiler.uvBufferIndex;
			_uvTransformIndex = _compiler.uvTransformIndex;
			_secondaryUVBufferIndex = _compiler.secondaryUVBufferIndex;
			_normalBufferIndex = _compiler.normalBufferIndex;
			_tangentBufferIndex = _compiler.tangentBufferIndex;
			_lightFragmentConstantIndex = _compiler.lightFragmentConstantIndex;
			_cameraPositionIndex = _compiler.cameraPositionIndex;
			_commonsDataIndex = _compiler.commonsDataIndex;
			_sceneMatrixIndex = _compiler.sceneMatrixIndex;
			_sceneNormalMatrixIndex = _compiler.sceneNormalMatrixIndex;
			_probeWeightsIndex = _compiler.probeWeightsIndex;
			_lightProbeDiffuseIndices = _compiler.lightProbeDiffuseIndices;
			_lightProbeSpecularIndices = _compiler.lightProbeSpecularIndices;
		}

		public function get preserveAlpha():Boolean
		{
			return _preserveAlpha;
		}

		public function set preserveAlpha(value:Boolean):void
		{
			if (_preserveAlpha == value)
				return;
			_preserveAlpha = value;
			invalidateShaderProgram();
		}

		public function get animateUVs():Boolean
		{
			return _animateUVs;
		}

		public function set animateUVs(value:Boolean):void
		{
			_animateUVs = value;
			if ((value && !_animateUVs) || (!value && _animateUVs))
				invalidateShaderProgram();
		}

		/**
		 * @inheritDoc
		 */
		override public function set mipmap(value:Boolean):void
		{
			if (_mipmap == value)
				return;
			super.mipmap = value;
		}

		/**
		 * The tangent space normal map to influence the direction of the surface for each texel.
		 */
		public function get normalMap():Texture2DBase
		{
			return _methodSetup.normalMethod.normalMap;
		}

		public function set normalMap(value:Texture2DBase):void
		{
			_methodSetup.normalMethod.normalMap = value;
		}

		public function get normalMethod():BasicNormalMethod
		{
			return _methodSetup.normalMethod;
		}

		public function set normalMethod(value:BasicNormalMethod):void
		{
			_methodSetup.normalMethod = value;
		}

		public function get ambientMethod():BasicAmbientMethod
		{
			return _methodSetup.ambientMethod;
		}

		public function set ambientMethod(value:BasicAmbientMethod):void
		{
			_methodSetup.ambientMethod = value;
		}

		public function get shadowMethod():ShadowMapMethodBase
		{
			return _methodSetup.shadowMethod;
		}

		public function set shadowMethod(value:ShadowMapMethodBase):void
		{
			_methodSetup.shadowMethod = value;
		}

		public function get diffuseMethod():BasicDiffuseMethod
		{
			return _methodSetup.diffuseMethod;
		}

		public function set diffuseMethod(value:BasicDiffuseMethod):void
		{
			_methodSetup.diffuseMethod = value;
		}

		public function get specularMethod():BasicSpecularMethod
		{
			return _methodSetup.specularMethod;
		}

		public function set specularMethod(value:BasicSpecularMethod):void
		{
			_methodSetup.specularMethod = value;
		}

		private function init():void
		{
			_methodSetup = new ShaderMethodSetup();
			_methodSetup.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			super.dispose();
			_methodSetup.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_methodSetup.dispose();
			_methodSetup = null;
		}

		/**
		 * Marks the shader program as invalid, so it will be recompiled before the next render.
		 */
		override public function invalidateShaderProgram(updateMaterial:Boolean = true):void
		{
			var oldPasses:Vector.<MaterialPassBase> = passes;
			passes = new Vector.<MaterialPassBase>();

			if (_methodSetup)
				addPassesFromMethods();

			if (!oldPasses || passes.length != oldPasses.length)
			{
				passesDirty = true;
				return;
			}

			for (var i:int = 0; i < passes.length; ++i)
			{
				if (passes[i] != oldPasses[i])
				{
					passesDirty = true;
					return;
				}
			}

			super.invalidateShaderProgram(updateMaterial);
		}

		protected function addPassesFromMethods():void
		{
			if (_methodSetup.normalMethod && _methodSetup.normalMethod.hasOutput)
				addPasses(_methodSetup.normalMethod.passes);
			if (_methodSetup.ambientMethod)
				addPasses(_methodSetup.ambientMethod.passes);
			if (_methodSetup.shadowMethod)
				addPasses(_methodSetup.shadowMethod.passes);
			if (_methodSetup.diffuseMethod)
				addPasses(_methodSetup.diffuseMethod.passes);
			if (_methodSetup.specularMethod)
				addPasses(_methodSetup.specularMethod.passes);
		}

		/**
		 * Adds passes to the list.
		 */
		protected function addPasses(passes:Vector.<MaterialPassBase>):void
		{
			if (!passes)
				return;

			var len:uint = passes.length;

			for (var i:uint = 0; i < len; ++i)
			{
				passes[i].material = material;
				passes[i].lightPicker = _lightPicker;
				this.passes.push(passes[i]);
			}
		}

		protected function initUVTransformData():void
		{
			_vertexConstantData[_uvTransformIndex] = 1;
			_vertexConstantData[_uvTransformIndex + 1] = 0;
			_vertexConstantData[_uvTransformIndex + 2] = 0;
			_vertexConstantData[_uvTransformIndex + 3] = 0;
			_vertexConstantData[_uvTransformIndex + 4] = 0;
			_vertexConstantData[_uvTransformIndex + 5] = 1;
			_vertexConstantData[_uvTransformIndex + 6] = 0;
			_vertexConstantData[_uvTransformIndex + 7] = 0;
		}

		protected function initCommonsData():void
		{
			_fragmentConstantData[_commonsDataIndex] = .5;
			_fragmentConstantData[_commonsDataIndex + 1] = 0;
			_fragmentConstantData[_commonsDataIndex + 2] = 1 / 255;
			_fragmentConstantData[_commonsDataIndex + 3] = 1;
		}

		protected function cleanUp():void
		{
			_compiler.dispose();
			_compiler = null;
		}

		protected function updateMethodConstants():void
		{
			if (_methodSetup.normalMethod)
				_methodSetup.normalMethod.initConstants(_methodSetup.normalMethodVO);
			if (_methodSetup.diffuseMethod)
				_methodSetup.diffuseMethod.initConstants(_methodSetup.diffuseMethodVO);
			if (_methodSetup.ambientMethod)
				_methodSetup.ambientMethod.initConstants(_methodSetup.ambientMethodVO);
			if (_usingSpecularMethod)
				_methodSetup.specularMethod.initConstants(_methodSetup.specularMethodVO);
			if (_methodSetup.shadowMethod)
				_methodSetup.shadowMethod.initConstants(_methodSetup.shadowMethodVO);
		}

		protected function updateLightConstants():void
		{

		}

		protected function updateProbes(stage3DProxy:Stage3DProxy):void
		{

		}

		private function onShaderInvalidated(event:ShadingMethodEvent):void
		{
			invalidateShaderProgram();
		}


		/**
		 * @inheritDoc
		 */
		override public function getVertexCode():String
		{
			return _vertexCode;
		}

		/**
		 * @inheritDoc
		 */
		override public function getFragmentCode(animatorCode:String):String
		{
			return _fragmentLightCode + animatorCode + _framentPostLightCode;
		}

// RENDER LOOP

		/**
		 * @inheritDoc
		 */
		override public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):void
		{
			super.activate(stage3DProxy, camera);

			if (_usesNormals)
				_methodSetup.normalMethod.activate(_methodSetup.normalMethodVO, stage3DProxy);
			_methodSetup.ambientMethod.activate(_methodSetup.ambientMethodVO, stage3DProxy);
			if (_methodSetup.shadowMethod)
				_methodSetup.shadowMethod.activate(_methodSetup.shadowMethodVO, stage3DProxy);
			_methodSetup.diffuseMethod.activate(_methodSetup.diffuseMethodVO, stage3DProxy);
			if (_usingSpecularMethod)
				_methodSetup.specularMethod.activate(_methodSetup.specularMethodVO, stage3DProxy);
		}

		/**
		 * @inheritDoc
		 */
		override public function render(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):void
		{
			var i:uint;
			var context:Context3D = stage3DProxy.context3D;
			if (_uvBufferIndex >= 0)
				renderable.activateUVBuffer(_uvBufferIndex, stage3DProxy);
			if (_secondaryUVBufferIndex >= 0)
				renderable.activateSecondaryUVBuffer(_secondaryUVBufferIndex, stage3DProxy);
			if (_normalBufferIndex >= 0)
				renderable.activateVertexNormalBuffer(_normalBufferIndex, stage3DProxy);
			if (_tangentBufferIndex >= 0)
				renderable.activateVertexTangentBuffer(_tangentBufferIndex, stage3DProxy);

			if (_animateUVs)
			{
				var uvTransform:Matrix = renderable.uvTransform;
				if (uvTransform)
				{
					_vertexConstantData[_uvTransformIndex] = uvTransform.a;
					_vertexConstantData[_uvTransformIndex + 1] = uvTransform.b;
					_vertexConstantData[_uvTransformIndex + 3] = uvTransform.tx;
					_vertexConstantData[_uvTransformIndex + 4] = uvTransform.c;
					_vertexConstantData[_uvTransformIndex + 5] = uvTransform.d;
					_vertexConstantData[_uvTransformIndex + 7] = uvTransform.ty;
				}
				else
				{
					_vertexConstantData[_uvTransformIndex] = 1;
					_vertexConstantData[_uvTransformIndex + 1] = 0;
					_vertexConstantData[_uvTransformIndex + 3] = 0;
					_vertexConstantData[_uvTransformIndex + 4] = 0;
					_vertexConstantData[_uvTransformIndex + 5] = 1;
					_vertexConstantData[_uvTransformIndex + 7] = 0;
				}
			}

			_ambientLightR = _ambientLightG = _ambientLightB = 0;

			if (usesLights())
				updateLightConstants();

			if (usesProbes())
				updateProbes(stage3DProxy);

			if (_sceneMatrixIndex >= 0)
			{
				renderable.getRenderSceneTransform(camera).copyRawDataTo(_vertexConstantData, _sceneMatrixIndex, true);
				viewProjection.copyRawDataTo(_vertexConstantData, 0, true);
			}
			else
			{
				var matrix3D:Matrix3D = Matrix3DUtils.CALCULATION_MATRIX;
				matrix3D.copyFrom(renderable.getRenderSceneTransform(camera));
				matrix3D.append(viewProjection);
				matrix3D.copyRawDataTo(_vertexConstantData, 0, true);
			}

			if (_sceneNormalMatrixIndex >= 0)
				renderable.inverseSceneTransform.copyRawDataTo(_vertexConstantData, _sceneNormalMatrixIndex, false);

			if (_usesNormals)
				_methodSetup.normalMethod.setRenderState(_methodSetup.normalMethodVO, renderable, stage3DProxy, camera);

			var ambientMethod:BasicAmbientMethod = _methodSetup.ambientMethod;
			ambientMethod.lightAmbientR = _ambientLightR;
			ambientMethod.lightAmbientG = _ambientLightG;
			ambientMethod.lightAmbientB = _ambientLightB;
			ambientMethod.setRenderState(_methodSetup.ambientMethodVO, renderable, stage3DProxy, camera);

			if (_methodSetup.shadowMethod)
				_methodSetup.shadowMethod.setRenderState(_methodSetup.shadowMethodVO, renderable, stage3DProxy, camera);
			_methodSetup.diffuseMethod.setRenderState(_methodSetup.diffuseMethodVO, renderable, stage3DProxy, camera);
			if (_usingSpecularMethod)
				_methodSetup.specularMethod.setRenderState(_methodSetup.specularMethodVO, renderable, stage3DProxy, camera);
			if (_methodSetup.colorTransformMethod)
				_methodSetup.colorTransformMethod.setRenderState(_methodSetup.colorTransformMethodVO, renderable, stage3DProxy, camera);

			var methods:Vector.<MethodVOSet> = _methodSetup.methods;
			var len:uint = methods.length;
			for (i = 0; i < len; ++i)
			{
				var mset:MethodVOSet = methods[i];
				mset.method.setRenderState(mset.data, renderable, stage3DProxy, camera);
			}

			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, _vertexConstantData, _numUsedVertexConstants);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _fragmentConstantData, _numUsedFragmentConstants);

			renderable.activateVertexBuffer(0, stage3DProxy);
			context.drawTriangles(renderable.getIndexBuffer(stage3DProxy), 0, renderable.numTriangles);
		}

		protected function usesProbes():Boolean
		{
			return _numLightProbes > 0 && ((_diffuseLightSources | _specularLightSources) & LightSources.PROBES) != 0;
		}

		protected function usesLights():Boolean
		{
			return (_numPointLights > 0 || _numDirectionalLights > 0) && ((_diffuseLightSources | _specularLightSources) & LightSources.LIGHTS) != 0;
		}

		/**
		 * @inheritDoc
		 */
		override public function deactivate(stage3DProxy:Stage3DProxy):void
		{
			super.deactivate(stage3DProxy);

			if (_usesNormals)
				_methodSetup.normalMethod.deactivate(_methodSetup.normalMethodVO, stage3DProxy);
			_methodSetup.ambientMethod.deactivate(_methodSetup.ambientMethodVO, stage3DProxy);
			if (_methodSetup.shadowMethod)
				_methodSetup.shadowMethod.deactivate(_methodSetup.shadowMethodVO, stage3DProxy);
			_methodSetup.diffuseMethod.deactivate(_methodSetup.diffuseMethodVO, stage3DProxy);
			if (_usingSpecularMethod)
				_methodSetup.specularMethod.deactivate(_methodSetup.specularMethodVO, stage3DProxy);
		}

//		override protected function updateLights() : void
//		{
//			for (var i : int = 0; i < _passes.length; ++i)
//				_passes[i].lightPicker = _lightPicker;
//		}

		public function get specularLightSources():uint
		{
			return _specularLightSources;
		}

		public function set specularLightSources(value:uint):void
		{
			_specularLightSources = value;
		}

		public function get diffuseLightSources():uint
		{
			return _diffuseLightSources;
		}

		public function set diffuseLightSources(value:uint):void
		{
			_diffuseLightSources = value;
		}
	}
}
