package a3d.animators.nodes;

import a3d.animators.data.SpriteSheetAnimationFrame;
import a3d.animators.states.SpriteSheetAnimationState;
import flash.Vector;

/**
 * A SpriteSheetClipNode containing time-based animation data as individual sprite sheet animation frames.
 */
class SpriteSheetClipNode extends AnimationClipNodeBase
{
	/**
	 * Returns a vector of SpriteSheetAnimationFrame representing the uv values of each animation frame in the clip.
	 */
	public var frames(get, null):Vector<SpriteSheetAnimationFrame>;
	
	private var _frames:Vector<SpriteSheetAnimationFrame>;

	/**
	 * Creates a new <code>SpriteSheetClipNode</code> object.
	 */
	public function new()
	{
		super();
		_stateClass = SpriteSheetAnimationState;
		_frames = new Vector<SpriteSheetAnimationFrame>();
	}

	
	private function get_frames():Vector<SpriteSheetAnimationFrame>
	{
		return _frames;
	}

	/**
	 * Adds a SpriteSheetAnimationFrame object to the internal timeline of the animation node.
	 *
	 * @param spriteSheetAnimationFrame The frame object to add to the timeline of the node.
	 * @param duration The specified duration of the frame in milliseconds.
	 */
	public function addFrame(spriteSheetAnimationFrame:SpriteSheetAnimationFrame, duration:Int):Void
	{
		_frames.push(spriteSheetAnimationFrame);
		_durations.push(duration);
		_numFrames = _durations.length;

		_stitchDirty = false;
	}
}
