package a3d.animators.data;


/**
 * A value object for a single frame of animation in a <code>SpriteSheetClipNode</code> object.
 *
 * @see a3d.animators.nodes.SpriteSheetClipNode
 */
class SpriteSheetAnimationFrame
{
	/**
	 * The u-component offset of the spritesheet frame.
	 */
	public var offsetU:Float;

	/**
	 * The v-component offset of the spritesheet frame.
	 */
	public var offsetV:Float;

	/**
	 * The u-component scale of the spritesheet frame.
	 */
	public var scaleU:Float;

	/**
	 * The v-component scale of the spritesheet frame.
	 */
	public var scaleV:Float;

	/**
	 * The mapID, zero based, if the animation is spreaded over more bitmapData's
	 */
	public var mapID:UInt;

	/**
	 * Creates a new <code>SpriteSheetAnimationFrame</code> object.
	 *
	 * @param offsetU 	The u-component offset of the spritesheet frame.
	 * @param offsetV 	The v-component offset of the spritesheet frame.
	 * @param scaleU 	The u-component scale of the spritesheet frame.
	 * @param scaleV 	The v-component scale of the spritesheet frame.
	 * @param mapID 	The v-component scale of the spritesheet frame.
	 */
	public function SpriteSheetAnimationFrame(offsetU:Float = 0, offsetV:Float = 0, scaleU:Float = 1, scaleV:Float = 1, mapID:UInt = 0)
	{
		this.offsetU = offsetU;
		this.offsetV = offsetV;
		this.scaleU = scaleU;
		this.scaleV = scaleV;
		this.mapID = mapID;
	}
}
