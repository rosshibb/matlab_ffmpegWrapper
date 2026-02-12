# **A MATLAB ffmpeg wrapper _(for windows)_**

The wrapper’s main use case is to take a folder of frames and export a video that is significantly compressed. This is what the default options will create, though it also allows for a great deal of customization in terms of the tool’s flags. The wrapper operates in two modes, the default expects frames in a single folder that are named with some sort of sequential pattern that you then specify, and a single, unchanging frame-rate applied to the whole video. The alternate mode works in such a way that you can specify the image paths in order and apply a unique frame duration for each frame, sort of like this [example](https://www.mathworks.com/help/matlab/import_export/convert-between-image-sequences-and-video.html). This wrapper is built for use on a windows system, so _"C:\ffmpeg\bin_" (or wherever your ffmpeg bin file is located, assuming you have already downloaded ffmpeg) will be needed to be added to your PATH for this run. A to-the-point guide on how to do so can be found [here](https://www.architectryan.com/2018/03/17/add-to-the-path-on-windows-10/).



#### Shared flags

* **_encoder_**: By default the wrapper will use the libx264 encoder which is good for high-compression video that should play on just about anything. The presets and profiles are tied to the encoder, so be aware that if you change the encoder, the same presets and profile flags might not work. (Default: "libx264"
* **_preset_**: controls the tradeoff between encoding speed and compression ratio. Default: “medium”
* **_profile_**: option to change encoder’s feature set. Some devices may support different profiles. The default for the wrapper is “high” which should be supported for all modern devices. Default: "high"
* **_movFlagOn_**: allows for progressive playback (video can start playing before being completely downloaded) Default: 1
* **_oddDimDivBy2_**: The encoder is expecting that the frames’ height and width are divisible by 2. This flag will automatically add padding if needed to the right and/or bottom of the images. If you want to scale the images to the divisible by 2 or otherwise, input that flag here (‘-vf ‘ included automatically). Default: "pad=ceil(iw/2)\*2:ceil(ih/2)\*2:color=0x"
* **_paddingBackgroundColor_**: the color of the background so the padding will blend with the image. Expects hex format. Default: “FFFFFF”
* **_customImgPathsOn_**: Enables alternate (concat) mode. Default: 0
* **_customFlag_**: Any additional flags that you would like to include. Default: ‘’

#### Default Mode (‘_customImgPathsOn_’ set to 0)

This is for when you have a set of images in a folder named with a standardized sequential order, with zero-padding.
* **_imagePattern_**: filename pattern for ffmpeg. Expects a sequential order of frames with zero-padding, starting with the lowest number. Default: "%04dFrame.jpg"
* **_frameRate_**: frames per second of output video. Default: 30
* **_startNumber_**: If you want to start at a frame other than the lowest number, set it here (don’t need leading zeros). Default: 0
* **_Total frames_**: ffmpeg will automatically go to the last number in the pattern sequence that exists in the folder. If you want to limit the last frame, do it here by setting the total number of frames to be used. Default: 0 (no limit)
* **_timeByTime_**: If instead you would like to limit total frames not by number of frames, but rather by total time of the created video \[in seconds], use this argument. Default: 0 (no trim)

#### Alternate Mode (‘_customImgPathsOn_’ set to 1)

In this mode you’ll need to create a cell array of image paths and another array of frame durations, useful if you need to use frames for disparate places or need unique frame durations.

* **_concatFrames_**: This should be a cell array 'nx1’ large, where ‘n’ is the number of image frames, and each cell is a string that is the absolute image path, in order. Default: empty cell array
* **_frameRate_**: This should be an array ‘nx1’ large of the frame durations \[in seconds] in the same order as concatFrames.

_For reference, I am using ffmpeg version 6.1.1 built with gcc 12.2.0._
