function ffmpegWrapper(imageFolderIn,nameOut,options)
%> Code Description:
%     A wrapper of the command line tool 'FFMPEG'  for creating a video
%     file from a folder of image frames. Sequential frame patterns (e.g.,
%     %04dFrame.jpg) as well as custom image path lists with per-frame
%     durations via the concat demuxer. Allows control over encoder,
%     preset, profile, pixel format, padding behavior for odd dimensions,
%     trimming, and customs flags.
%
%> Inputs:
%     imageFolderIn:              Folder containing input image frames
%                                 OR location where concat text file will
%                                 be temporarily written
%
%     nameOut:                    Output video filepath (including
%                                 extension). Default: "output.mp4"
%
%     options:                    Name-value encoding and input options:
%
%         .frameRate              Frame rate of input sequence (Default: 30)
%                                 If using customImgPathsOn, set array of per-frame durations.
%
%         .imagePattern           Frame filename pattern for ffmpeg
%                                 (Default: "%04dFrame.jpg")
%
%         .customImgPathsOn       Logical flag to enable concat mode for
%                                 arbitrary image ordering and durations
%                                 (Default: 0)
%
%         .encoder                video encoder (Default: "libx264")
%
%         .preset                 Encoding speed/compression tradeoff (Default: "medium")
%
%         .profile                Codec profile (Default: "high")
%
%         .pixelFormat          Output pixel format (Default: "yuv420p")
%
%         .startNumber          Starting index for image pattern (Default: 0)
%
%         .totalFrames            Limits total frames written using
%                                 -frames:v (Default: 0 -> no limit)
%
%         .trimByTime         Trim output by duration in seconds using
%                                 -t (Default: 0 -> no trim)
%
%         .movFlagOn         Adds "-movflags +faststart" for web
%                                 streaming compatibility (Default: 1)
%
%         .oddDimDivBy2       Video filter string for handling odd
%                                 dimensions (Default pads to even size)
%
%         .paddingBackgroundColor     Hex color (without 0x prefix) used for
%                                 padding background (Default: "FFFFFF")
%
%         .customFlag             Additional custom ffmpeg flags appended
%                                 to command (Default: "")
%
%         .concatFrames        Cell array of full image paths used when
%                                 customImgPathsOn is true. Must match
%                                 length of durations.
%
%> Notes:
%         - "ffmpeg" needs to be added to system path.
%         - Only tested for Windows, customImgPathsOn will for sure break on unix
%
%> Harrison Ross Hibbett (harrison_hibbett@alumni.brown.edu) 2026
    arguments
        imageFolderIn string
        nameOut string = "output.mp4"
        options.frameRate double {mustBeNonnegative} = 30 % if customImgPathsOn input durations array here
        options.imagePattern string {mustBeText} = "%04dFrame.jpg"
        options.customImgPathsOn logical {mustBeNumericOrLogical} = 0
        options.encoder string {mustBeText} = "libx264"
        options.preset string {mustBeText} = "medium"
        options.customFlag string {mustBeText} = "" % check with strlength
        options.profile string {mustBeText} = "high"
        options.pixelFormat string {mustBeText} = "yuv420p"
        options.startNumber double {mustBeInteger} = 0 % will start at lowest number unless otherwise specified
        options.totalFrames double {mustBeInteger} = 0  % If not 0 -> -frames:v
        options.trimByTime double {mustBeNonnegative} = 0 % If not 0 -> -t
        options.movFlagOn logical {mustBeNumericOrLogical} = 1 
        options.oddDimDivBy2 string {mustBeText} = "pad=ceil(iw/2)*2:ceil(ih/2)*2:color=0x" % make sure to include to -vf
        options.paddingBackgroundColor string {mustBeText} = "FFFFFF"
        options.concatFrames cell = {} % If using customImgPathsOn -> this should be a cell array of image paths
    end

    if ~strlength(options.customFlag)
        customAddFlag = '';
    else
        customAddFlag = sprintf(' %s', options.customFlag); 
    end

    if ~options.customImgPathsOn && ~isequal(size(options.frameRate), [1 1])
        error("frameRate should be a single number if customImgPathsOn (Concat Option) is OFF");
    end
    if ~options.customImgPathsOn && ~isempty(options.concatFrames)
        error("concatFrames should be left empty if customImgPathsOn (Concat Option) is OFF");
    end

    if ~options.customImgPathsOn
        % FrameRate Flag (Always on unless custom durations)
        frameRateFlag = sprintf(' -framerate %.4f', options.frameRate);

        % Custom start number check, else default is 0  (in FFMPEG)
        if options.startNumber == 0
            startNumFlag = '';
        else
            startNumFlag = sprintf(' -start_number %.0f', options.startNumber);
        end

        % Custom total frame number check, else defaults to go to end (in FFMPEG)
        if options.totalFrames == 0
            totalFramesFlag = '';
        else
            totalFramesFlag = sprintf(' -frames:v %.0f', options.totalFrames);
        end
        if options.trimByTime ~= 0 && options.totalFrames ~= 0
            error("Either trim by time or total frames, not both");
        else
            if options.trimByTime ~= 0
                trimFlag = sprintf(' -t %.4f', options.trimByTime);
            else
                trimFlag = '';
            end
        end

        inputFramesFlag = sprintf(' -i %s', fullfile(imageFolderIn, options.imagePattern));
    else % Concat with unique frame durations
        frameRateFlag = ' -f concat -safe 0';
        startNumFlag = '';
        totalFramesFlag = '';
        trimFlag = '';
        % Creates text file with image paths and durations, -> call concat w/ FFMPEG
        textFilePath = createConcatFile(imageFolderIn,options.concatFrames,options.frameRate);
        inputFramesFlag = sprintf(' -i %s', textFilePath);
    end

    if options.movFlagOn
        movFlag = ' -movflags +faststart';
    else
        movFlag = '';
    end

    if strlength(options.oddDimDivBy2)
        paddingFlag = sprintf(' -vf "%s%s"', options.oddDimDivBy2, options.paddingBackgroundColor);
    else
        paddingFlag = '';
    end

    % -----Preset-----
    presentOpts = ["ultrafast", "superfast", "veryfast", "superfast", "faster", ...
                            "fast", "medium", "slow", "slower", "veryslow"];
    if any(ismember(presentOpts,options.preset))
        presetFlag = sprintf(' -preset %s', options.preset);
    else
        error("%s is not a valid Preset, please choose from 'ultrafast', 'superfast', 'veryfast', " + ...
            "'faster', 'fast', 'medium', 'slow', slower', or 'veryslow'", options.preset);
    end

    encoderFlag = sprintf(' -c:v %s', options.encoder);
    % -----Profiles (libx264)-----
    profileLibx264Opts = ["baseline", "main", "high", "high10", "high422", "high444"];
    if any(ismember(profileLibx264Opts,options.profile)) && options.encoder == "libx264"
        profileFlag = sprintf(' -profile:v %s', options.profile);
    elseif options.encoder ~= "libx264"
        profileFlag = sprintf(' -profile:v %s', options.profile);
    else
        error("%s is not a valid Profile for the x264 encoder, please choose from 'baseline', " + ...
            "'main', 'high', 'high10', 'high422', 'high444'", options.profile);
    end

    % -----pixel format-----
    pixFmtLibx264Opts = ["yuv420p", "yuvj420p", "yuv422p", "yuvj422p", "yuv444p", "yuvj444p", ...
                            "nv12", "nv16", "nv21", "yuv420p10le", "yuv422p10le", "yuv444p10le", "nv20le"...
                            "gray", "nv20le"];
    if any(ismember(pixFmtLibx264Opts,options.pixelFormat)) && options.encoder == "libx264"
        pixFmtFlag = sprintf(' -pix_fmt %s', options.pixelFormat);
    elseif options.encoder ~= "libx264"
        pixFmtFlag = sprintf(' -pix_fmt %s', options.pixelFormat);
    else
        error("%s is not a valid pixel format for the x264 encoder, please choose from 'yuv420p', " + ...
            "'yuvj420p', 'yuv422p', 'yuvj422p', 'yuv444p', 'yuvj444p', 'nv12', 'nv16', 'nv21', 'yuv420p10le', " + ...
            "'yuv422p10le', 'nv20le', 'gray', 'nv20le'", options.pixelFormat);
    end

    outFileFlag = sprintf(' %s', nameOut);

    if ~options.customImgPathsOn  % Normal Verison
        cmd = ['ffmpeg' frameRateFlag startNumFlag inputFramesFlag totalFramesFlag encoderFlag ...
                            trimFlag presetFlag profileFlag pixFmtFlag movFlag customAddFlag paddingFlag outFileFlag];
        system(cmd);
    else % Concat Verison
        cmd = ['ffmpeg' frameRateFlag inputFramesFlag encoderFlag trimFlag presetFlag profileFlag ...
                            pixFmtFlag movFlag customAddFlag paddingFlag outFileFlag];
        system(cmd);
        deleteFile(textFilePath); % Created .txt file for concat, now delete it
    end

end

function textFilePath = createConcatFile(outputFolder,imgPaths,durations)
% Creates text file with image paths and durations
    if length(imgPaths) ~= length(durations)
        error("Cell array of image paths and array of durations need to be the same length...")
    else
        len = length(imgPaths);
        intermCell = cell([len*2,1]);
        for i = 1:len
            intermCell{i*2-1} = sprintf("file '%s'", imgPaths{i});
            intermCell{i*2} = sprintf('duration %0.8f', durations(i));
        end
        intermCell{len*2+1} = sprintf("file '%s'", imgPaths{end});

        outputTable = cell2table(intermCell);
        outputTxtPath = fullfile(outputFolder,'placeHolder.txt');
        writetable(outputTable,outputTxtPath,'Delimiter','\t','WriteVariableNames', false);
        textFilePath = outputTxtPath;
    end
end

function deleteFile(pathToFile)
% Deletes file via system command -> WINDOWS UNIQUE
% Change 'del' to 'rm' for unix based systems
    if isfile(pathToFile)
        cmd = sprintf('del %s', pathToFile);
        system(cmd);
    else
        error('%s is not a valid path to a file.', pathToFile);
    end
end