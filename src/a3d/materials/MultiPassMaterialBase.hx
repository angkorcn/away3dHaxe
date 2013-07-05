﻿package a3d.materials;

import flash.display3D.Context3D;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DCompareMode;
import flash.errors.Error;
import flash.events.Event;
import flash.Vector;


import a3d.entities.Camera3D;
import a3d.core.managers.Stage3DProxy;
import a3d.materials.lightpickers.LightPickerBase;
import a3d.materials.lightpickers.StaticLightPicker;
import a3d.materials.methods.BasicAmbientMethod;
import a3d.materials.methods.BasicDiffuseMethod;
import a3d.materials.methods.BasicNormalMethod;
import a3d.materials.methods.BasicSpecularMethod;
import a3d.materials.methods.EffectMethodBase;
import a3d.materials.methods.ShadowMapMethodBase;
import a3d.materials.passes.CompiledPass;
import a3d.materials.passes.LightingPass;
import a3d.materials.passes.ShadowCasterPass;
import a3d.materials.passes.SuperShaderPass;
import a3d.textures.Texture2DBase;



/**
 * MultiPassMaterialBase forms an abstract base class for the default multi-pass materials provided by Away3D, using material methods
 * to define their appearance.
 */
class MultiPassMaterialBase extends MaterialBase
{
	private var _casterLightPass:ShadowCasterPass;
	private var _nonCasterLightPasses:Vector<LightingPass>;
	private var _effectsPass:SuperShaderPass;

	private var _alphaThreshold:Float = 0;
	private var _specularLightSources:UInt = 0x01;
	private var _diffuseLightSources:UInt = 0x03;

	private var _ambientMethod:BasicAmbientMethod;
	private var _shadowMethod:ShadowMapMethodBase;
	private var _diffuseMethod:BasicDiffuseMethod;
	private var _normalMethod:BasicNormalMethod;
	private var _specularMethod:BasicSpecularMethod;

	private var _screenPassesInvalid:Bool = true;
	private var _enableLightFallOff:Bool = true;

	/**
	 * Creates a new MultiPassMaterialBase object.
	 */
	public function new()
	{
		super();
		_ambientMethod = new BasicAmbientMethod();
		_diffuseMethod = new BasicDiffuseMethod();
		_normalMethod= new BasicNormalMethod();
		_specularMethod = new BasicSpecularMethod();
	}

	/**
	 * Whether or not to use fallOff and radius properties for lights.
	 */
	public var enableLightFallOff(get,set):Bool;
	private function get_enableLightFallOff():Bool
	{
		return _enableLightFallOff;
	}

	private function set_enableLightFallOff(value:Bool):Bool
	{
		if (_enableLightFallOff != value)
			invalidateScreenPasses();
		_enableLightFallOff = value;
		return _enableLightFallOff;
	}

	/**
	 * The minimum alpha value for which pixels should be drawn. This is used for transparency that is either
	 * invisible or entirely opaque, often used with textures for foliage, etc.
	 * Recommended values are 0 to disable alpha, or 0.5 to create smooth edges. Default value is 0 (disabled).
	 */
	public var alphaThreshold(get,set):Float;
	private function get_alphaThreshold():Float
	{
		return _alphaThreshold;
	}

	private function set_alphaThreshold(value:Float):Float
	{
		_alphaThreshold = value;
		_diffuseMethod.alphaThreshold = value;
		_depthPass.alphaThreshold = value;
		_distancePass.alphaThreshold = value;
		return _alphaThreshold;
	}

	override private function set_depthCompareMode(value:Context3DCompareMode):Context3DCompareMode
	{
		super.depthCompareMode = value;
		invalidateScreenPasses();
		return depthCompareMode;
	}

	override private function set_blendMode(value:BlendMode):BlendMode
	{
		super.blendMode = value;
		invalidateScreenPasses();
		return blendMode;
	}

	override public function activateForDepth(stage3DProxy:Stage3DProxy, camera:Camera3D, distanceBased:Bool = false):Void
	{
		if (distanceBased)
			_distancePass.alphaMask = _diffuseMethod.texture;
		else
			_depthPass.alphaMask = _diffuseMethod.texture;

		super.activateForDepth(stage3DProxy, camera, distanceBased);
	}

	public var specularLightSources(get,set):Int;
	private function get_specularLightSources():Int
	{
		return _specularLightSources;
	}

	private function set_specularLightSources(value:Int):Int
	{
		return _specularLightSources = value;
	}

	public var diffuseLightSources(get,set):Int;
	private function get_diffuseLightSources():Int
	{
		return _diffuseLightSources;
	}

	private function set_diffuseLightSources(value:Int):Int
	{
		return _diffuseLightSources = value;
	}

	override private function set_lightPicker(value:LightPickerBase):LightPickerBase
	{
		if (_lightPicker != null)
			_lightPicker.removeEventListener(Event.CHANGE, onLightsChange);
		super.lightPicker = value;
		if (_lightPicker != null)
			_lightPicker.addEventListener(Event.CHANGE, onLightsChange);
		invalidateScreenPasses();
		return lightPicker;
	}

	/**
	 * @inheritDoc
	 */
	override private function get_requiresBlending():Bool
	{
		return false;
	}

	/**
	 * The method to perform ambient shading. Note that shading methods cannot
	 * be reused across materials.
	 */
	public var ambientMethod(get,set):BasicAmbientMethod;
	private function get_ambientMethod():BasicAmbientMethod
	{
		return _ambientMethod;
	}

	private function set_ambientMethod(value:BasicAmbientMethod):BasicAmbientMethod
	{
		value.copyFrom(_ambientMethod);
		_ambientMethod = value;
		invalidateScreenPasses();
		return _ambientMethod;
	}

	/**
	 * The method to render shadows cast on this surface. Note that shading methods can not
	 * be reused across materials.
	 */
	public var shadowMethod(get,set):ShadowMapMethodBase;
	private function get_shadowMethod():ShadowMapMethodBase
	{
		return _shadowMethod;
	}

	private function set_shadowMethod(value:ShadowMapMethodBase):ShadowMapMethodBase
	{
		if (value != null && _shadowMethod != null)
			value.copyFrom(_shadowMethod);
		_shadowMethod = value;
		invalidateScreenPasses();
		return _shadowMethod;
	}

	/**
	 * The method to perform diffuse shading. Note that shading methods can not
	 * be reused across materials.
	 */
	public var diffuseMethod(get,set):BasicDiffuseMethod;
	private function get_diffuseMethod():BasicDiffuseMethod
	{
		return _diffuseMethod;
	}

	private function set_diffuseMethod(value:BasicDiffuseMethod):BasicDiffuseMethod
	{
		value.copyFrom(_diffuseMethod);
		_diffuseMethod = value;
		invalidateScreenPasses();
		return _diffuseMethod;
	}

	/**
	 * The method to generate the (tangent-space) normal. Note that shading methods can not
	 * be reused across materials.
	 */
	public var normalMethod(get,set):BasicNormalMethod;
	private function get_normalMethod():BasicNormalMethod
	{
		return _normalMethod;
	}

	private function set_normalMethod(value:BasicNormalMethod):BasicNormalMethod
	{
		value.copyFrom(_normalMethod);
		_normalMethod = value;
		invalidateScreenPasses();
		return _normalMethod;
	}

	/**
	 * The method to perform specular shading. Note that shading methods can not
	 * be reused across materials.
	 */
	public var specularMethod(get,set):BasicSpecularMethod;
	private function get_specularMethod():BasicSpecularMethod
	{
		return _specularMethod;
	}

	private function set_specularMethod(value:BasicSpecularMethod):BasicSpecularMethod
	{
		if (value != null && _specularMethod != null )
			value.copyFrom(_specularMethod);
		_specularMethod = value;
		invalidateScreenPasses();
		return _specularMethod;
	}

	/**
		 * Adds a shading method to the end of the shader. Note that shading methods can
		 * not be reused across materials.
		*/
	public function addMethod(method:EffectMethodBase):Void
	{
		if (_effectsPass == null)
			_effectsPass = new SuperShaderPass(this);
		_effectsPass.addMethod(method);
		invalidateScreenPasses();
	}

	public var numMethods(get,null):Int;
	private function get_numMethods():Int
	{
		return _effectsPass != null ? _effectsPass.numMethods : 0;
	}

	public function hasMethod(method:EffectMethodBase):Bool
	{
		return _effectsPass != null ? _effectsPass.hasMethod(method) : false;
	}

	public function getMethodAt(index:Int):EffectMethodBase
	{
		return _effectsPass.getMethodAt(index);
	}

	/**
	 * Adds a shading method to the end of a shader, at the specified index amongst
	 * the methods in that section of the shader. Note that shading methods can not
	 * be reused across materials.
	*/
	public function addMethodAt(method:EffectMethodBase, index:Int):Void
	{
		if (_effectsPass == null)
			_effectsPass = new SuperShaderPass(this);
		_effectsPass.addMethodAt(method, index);
		invalidateScreenPasses();
	}

	public function removeMethod(method:EffectMethodBase):Void
	{
		if (_effectsPass == null)
			return;
			
		_effectsPass.removeMethod(method);

		// reconsider
		if (_effectsPass.numMethods == 0)
			invalidateScreenPasses();
	}

	/**
	 * @inheritDoc
	 */
	override private function set_mipmap(value:Bool):Bool
	{
		if (_mipmap == value)
			return mipmap;
		return super.mipmap = value;
	}

	/**
	 * The tangent space normal map to influence the direction of the surface for each texel.
	 */
	public var normalMap(get,set):Texture2DBase;
	private function get_normalMap():Texture2DBase
	{
		return _normalMethod.normalMap;
	}

	private function set_normalMap(value:Texture2DBase):Texture2DBase
	{
		return _normalMethod.normalMap = value;
	}

	/**
	 * A specular map that defines the strength of specular reflections for each texel in the red channel, and the gloss factor in the green channel.
	 * You can use SpecularBitmapTexture if you want to easily set specular and gloss maps from greyscale images, but prepared images are preffered.
	 */
	public var specularMap(get,set):Texture2DBase;
	private function get_specularMap():Texture2DBase
	{
		return _specularMethod.texture;
	}

	private function set_specularMap(value:Texture2DBase):Texture2DBase
	{
		if (_specularMethod != null)
			_specularMethod.texture = value;
		else
			throw new Error("No specular method was set to assign the specularGlossMap to");
		return _specularMethod.texture;
	}

	/**
	 * The sharpness of the specular highlight.
	 */
	public var gloss(get,set):Float;
	private function get_gloss():Float
	{
		return _specularMethod != null ? _specularMethod.gloss : 0;
	}

	private function set_gloss(value:Float):Float
	{
		if (_specularMethod != null)
			_specularMethod.gloss = value;
		return gloss;
	}

	/**
	 * The strength of the ambient reflection.
	 */
	public var ambient(get,set):Float;
	private function get_ambient():Float
	{
		return _ambientMethod.ambient;
	}

	private function set_ambient(value:Float):Float
	{
		return _ambientMethod.ambient = value;
	}

	/**
	 * The overall strength of the specular reflection.
	 */
	public var specular(get,set):Float;
	private function get_specular():Float
	{
		return _specularMethod != null ? _specularMethod.specular : 0;
	}

	private function set_specular(value:Float):Float
	{
		if (_specularMethod != null)
			_specularMethod.specular = value;
		return specular;
	}

	/**
	 * The colour of the ambient reflection.
	 */
	public var ambientColor(get,set):UInt;
	private function get_ambientColor():UInt
	{
		return _ambientMethod.ambientColor;
	}

	private function set_ambientColor(value:UInt):UInt
	{
		return _ambientMethod.ambientColor = value;
	}

	/**
	 * The colour of the specular reflection.
	 */
	public var specularColor(get,set):UInt;
	private function get_specularColor():UInt
	{
		return _specularMethod.specularColor;
	}

	private function set_specularColor(value:UInt):UInt
	{
		return _specularMethod.specularColor = value;
	}

	/**
	 * @inheritDoc
	 */
	override public function updateMaterial(context:Context3D):Void
	{
		var passesInvalid:Bool = false;

		if (_screenPassesInvalid)
		{
			updateScreenPasses();
			passesInvalid = true;
		}

		if (passesInvalid || isAnyScreenPassInvalid())
		{
			clearPasses();

			addChildPassesFor(_casterLightPass);
			if (_nonCasterLightPasses != null)
				for (i in 0..._nonCasterLightPasses.length)
					addChildPassesFor(_nonCasterLightPasses[i]);
			addChildPassesFor(_effectsPass);

			addScreenPass(_casterLightPass);
			if (_nonCasterLightPasses != null)
				for (i in 0..._nonCasterLightPasses.length)
					addScreenPass(_nonCasterLightPasses[i]);
			addScreenPass(_effectsPass);
		}
	}

	private function addScreenPass(pass:CompiledPass):Void
	{
		if (pass != null)
		{
			addPass(pass);
			pass.passesDirty = false;
		}
	}

	private function isAnyScreenPassInvalid():Bool
	{
		if ((_casterLightPass != null && _casterLightPass.passesDirty) ||
			(_effectsPass != null && _effectsPass.passesDirty))
			return true;

		if (_nonCasterLightPasses != null)
			for (i in 0..._nonCasterLightPasses.length)
				if (_nonCasterLightPasses[i].passesDirty)
					return true;

		return false;
	}

	private function addChildPassesFor(pass:CompiledPass):Void
	{
		if (pass == null)
			return;

		if (pass.passes != null)
		{
			var len:Int = pass.passes.length;
			for (i in 0...len)
				addPass(pass.passes[i]);
		}
	}

	override public function activatePass(index:UInt, stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		if (index == 0)
			stage3DProxy.context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
		super.activatePass(index, stage3DProxy, camera);
	}

	override public function deactivate(stage3DProxy:Stage3DProxy):Void
	{
		super.deactivate(stage3DProxy);
		stage3DProxy.context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
	}

	private function updateScreenPasses():Void
	{
		initPasses();
		setBlendAndCompareModes();

		_screenPassesInvalid = false;
	}

	private function initPasses():Void
	{
		// effects pass will be used to render unshaded diffuse
		if (numLights == 0 || numMethods > 0)
			initEffectsPass();
		else if (_effectsPass != null && numMethods == 0)
			removeEffectsPass();

		if (_shadowMethod != null)
			initCasterLightPass();
		else
			removeCasterLightPass();

		if (numNonCasters > 0)
			initNonCasterLightPasses();
		else
			removeNonCasterLightPasses();
	}

	private function setBlendAndCompareModes():Void
	{
		var forceSeparateMVP:Bool = (_casterLightPass != null || _effectsPass != null);

		if (_casterLightPass != null)
		{
			_casterLightPass.setBlendMode(BlendMode.NORMAL);
			_casterLightPass.depthCompareMode = depthCompareMode;
			_casterLightPass.forceSeparateMVP = forceSeparateMVP;
		}

		if (_nonCasterLightPasses != null)
		{
			var firstAdditiveIndex:Int = 0;
			if (_casterLightPass == null)
			{
				_nonCasterLightPasses[0].forceSeparateMVP = forceSeparateMVP;
				_nonCasterLightPasses[0].setBlendMode(BlendMode.NORMAL);
				_nonCasterLightPasses[0].depthCompareMode = depthCompareMode;
				firstAdditiveIndex = 1;
			}
			for (i in firstAdditiveIndex..._nonCasterLightPasses.length)
			{
				_nonCasterLightPasses[i].forceSeparateMVP = forceSeparateMVP;
				_nonCasterLightPasses[i].setBlendMode(BlendMode.ADD);
				_nonCasterLightPasses[i].depthCompareMode = Context3DCompareMode.LESS_EQUAL;
			}
		}

		if (_casterLightPass != null || _nonCasterLightPasses != null)
		{
			if (_effectsPass != null)
			{
				_effectsPass.ignoreLights = true;
				_effectsPass.depthCompareMode = Context3DCompareMode.LESS_EQUAL;
				_effectsPass.setBlendMode(BlendMode.LAYER);
				_effectsPass.forceSeparateMVP = forceSeparateMVP;
			}
		}
		else if (_effectsPass != null)
		{
			_effectsPass.ignoreLights = false;
			_effectsPass.depthCompareMode = depthCompareMode;
			_effectsPass.setBlendMode(BlendMode.NORMAL);
			_effectsPass.forceSeparateMVP = false;
		}
	}

	private function initCasterLightPass():Void
	{
		if (_casterLightPass == null)
			_casterLightPass = new ShadowCasterPass(this);
		_casterLightPass.diffuseMethod = null;
		_casterLightPass.ambientMethod = null;
		_casterLightPass.normalMethod = null;
		_casterLightPass.specularMethod = null;
		_casterLightPass.shadowMethod = null;
		_casterLightPass.enableLightFallOff = _enableLightFallOff;
		_casterLightPass.lightPicker = new StaticLightPicker([_shadowMethod.castingLight]);
		_casterLightPass.shadowMethod = _shadowMethod;
		_casterLightPass.diffuseMethod = _diffuseMethod;
		_casterLightPass.ambientMethod = _ambientMethod;
		_casterLightPass.normalMethod = _normalMethod;
		_casterLightPass.specularMethod = _specularMethod;
		_casterLightPass.diffuseLightSources = _diffuseLightSources;
		_casterLightPass.specularLightSources = _specularLightSources;
	}

	private function removeCasterLightPass():Void
	{
		if (_casterLightPass == null)
			return;
		_casterLightPass.dispose();
		removePass(_casterLightPass);
		_casterLightPass = null;
	}

	private function initNonCasterLightPasses():Void
	{
		removeNonCasterLightPasses();
		var pass:LightingPass;
		var numDirLights:Int = _lightPicker.numDirectionalLights;
		var numPointLights:Int = _lightPicker.numPointLights;
		var numLightProbes:Int = _lightPicker.numLightProbes;
		var dirLightOffset:Int = 0;
		var pointLightOffset:Int = 0;
		var probeOffset:Int = 0;

		if (_casterLightPass == null)
		{
			numDirLights += _lightPicker.numCastingDirectionalLights;
			numPointLights += _lightPicker.numCastingPointLights;
		}

		_nonCasterLightPasses = new Vector<LightingPass>();
		while (dirLightOffset < numDirLights || 
				pointLightOffset < numPointLights || 
				probeOffset < numLightProbes)
		{
			pass = new LightingPass(this);
			pass.enableLightFallOff = _enableLightFallOff;
			pass.includeCasters = _shadowMethod == null;
			pass.directionalLightsOffset = dirLightOffset;
			pass.pointLightsOffset = pointLightOffset;
			pass.lightProbesOffset = probeOffset;
			pass.diffuseMethod = null;
			pass.ambientMethod = null;
			pass.normalMethod = null;
			pass.specularMethod = null;
			pass.lightPicker = _lightPicker;
			pass.diffuseMethod = _diffuseMethod;
			pass.ambientMethod = _ambientMethod;
			pass.normalMethod = _normalMethod;
			pass.specularMethod = _specularMethod;
			pass.diffuseLightSources = _diffuseLightSources;
			pass.specularLightSources = _specularLightSources;
			_nonCasterLightPasses.push(pass);

			dirLightOffset += pass.numDirectionalLights;
			pointLightOffset += pass.numPointLights;
			probeOffset += pass.numLightProbes;
		}
	}

	private function removeNonCasterLightPasses():Void
	{
		if (_nonCasterLightPasses == null)
			return;
			
		for (i in 0..._nonCasterLightPasses.length)
		{
			removePass(_nonCasterLightPasses[i]);
			_nonCasterLightPasses[i].dispose();
		}
		_nonCasterLightPasses = null;
	}

	private function removeEffectsPass():Void
	{
		if (_effectsPass.diffuseMethod != _diffuseMethod)
			_effectsPass.diffuseMethod.dispose();
		removePass(_effectsPass);
		_effectsPass.dispose();
		_effectsPass = null;
	}

	private function initEffectsPass():SuperShaderPass
	{
		if (_effectsPass == null)
			_effectsPass = new SuperShaderPass(this);
		_effectsPass.enableLightFallOff = _enableLightFallOff;
		if (numLights == 0)
		{
			_effectsPass.diffuseMethod = null;
			_effectsPass.diffuseMethod = _diffuseMethod;
		}
		else
		{
			_effectsPass.diffuseMethod = null;
			_effectsPass.diffuseMethod = new BasicDiffuseMethod();
			_effectsPass.diffuseMethod.diffuseColor = 0x000000;
			_effectsPass.diffuseMethod.diffuseAlpha = 0;
		}
		_effectsPass.preserveAlpha = false;
		_effectsPass.normalMethod = null;
		_effectsPass.normalMethod = _normalMethod;

		return _effectsPass;
	}

	public var numLights(get, null):Int;
	private function get_numLights():Int
	{
		return _lightPicker != null ? _lightPicker.numLightProbes + _lightPicker.numDirectionalLights + _lightPicker.numPointLights +
			_lightPicker.numCastingDirectionalLights + _lightPicker.numCastingPointLights : 0;
	}

	public var numNonCasters(get, null):Int;
	private function get_numNonCasters():Int
	{
		return _lightPicker != null ? _lightPicker.numLightProbes + _lightPicker.numDirectionalLights + _lightPicker.numPointLights : 0;
	}

	private function invalidateScreenPasses():Void
	{
		_screenPassesInvalid = true;
	}

	private function onLightsChange(event:Event):Void
	{
		invalidateScreenPasses();
	}
}
