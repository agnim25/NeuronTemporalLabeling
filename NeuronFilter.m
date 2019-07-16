%
% NeuronFilter - Temporal Labeling GUI for calcium imaging videos of active neurons
% Last updated 07/16/2019 by Agnim Agarwal
%

function NeuronFilter(vid, Mask)
global i previous;
global result resultString resultSpTimes;
global CallBackInterrupted;
CallBackInterrupted = 0;
global IsPlaying
global timeline;
timeline = [];
global gui;
global Trace;
Trace = 0;
global spikeCheck spikeArray spikeCount spikeTotal onSpike yesNoArray meanAc std;
spikeArray = [];
spikeCheck = false;
onSpike = false;
spikeCount = 1;
yesNoArray = [];
meanAc = 0;
std = 0;

global fileout;
fileout = fopen('results/out.txt', 'w');

%% Get traces for each mask
if (Trace == 0)
    [x, y, T] = size(vid);
    v = reshape(vid, [], T);
    guimask = Mask;
    guitrace = zeros(size(guimask, 3), T);
    for k = 1:size(guimask, 3)
        guitrace(k, :) = sum(v(reshape(guimask(:, :, k), [], 1) == 1, :), 1);
    end
    guitrace = guitrace ./ median(guitrace, 2) - 1;

    Trace = guitrace;
end
assignin('base', 'ans', Trace);
%bin input video f    global gui data1; or faster visualization
global data1;
scale = 1;
%     FR = 6/scale;
vid = uint16(binVideo_temporal(vid, scale));
Trace = double(binTraces_temporal(Trace, scale));

%% Get mean and std deviation for trace
for l = 1:size(vid, 3)
    meanAc = meanAc + Trace(1, l);
end
meanAc = meanAc / size(vid, 3);
for l = 1:size(vid, 3)
    std = std + abs(Trace(1, l)-meanAc);
end
std = std / size(vid, 3);
%     disp(meanAc);
%     disp(std);


%%adjust contrast of frames
for ii = 1:size(vid, 3)
    vid(:, :, ii) = imadjust(vid(:, :, ii), [], [], 0.5);
end

[data1.d1, data1.d2, data1.T] = size(vid);
data1.T = size(Trace, 2);
data1.tracelimitx = [1, data1.T];
data1.tracelimity = [floor(min(Trace(:))), ceil(max(Trace(:)))];
data1.green = cat(3, zeros(data1.d1, data1.d2), ones(data1.d1, data1.d2), zeros(data1.d1, data1.d2));

MAXImg = imadjust(max(vid, [], 3), [], [], 1.2);
data1.maxImg = imadjust(max(vid, [], 3), [], [], 1.2);

i = 1; %i = current neuron

createInterface();
updateInterface();
ResetSpikeArray();
setListBox();
%-------------------------------------------------------------------------%

%% createInterface - initialize GUI
    function createInterface()

        gui = struct();
        screensize = get(groot, 'ScreenSize');
        gui.Window = figure( ...
            'Name', 'Select Neurons', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'off', ...
            'Position', [screensize(3) / 9, screensize(4) / 9, screensize(3) * 7 / 9, screensize(4) * 7 / 9] ...
            );

        % Arrange the main interface
        mainLayout = uix.VBoxFlex( ...
            'Parent', gui.Window, ...
            'Spacing', 3);
        upperLayout = uix.HBoxFlex( ...
            'Parent', mainLayout, ...
            'Padding', 3);
        lowerLayout = uix.HBoxFlex( ...
            'Parent', mainLayout, ...
            'Padding', 3);

        % Upper Layout Design
        gui.MaskPanel = uix.BoxPanel( ...
            'Parent', upperLayout, ...
            'Padding', 3, ...
            'Title', 'Mask');
        gui.MaskAxes = axes('Parent', gui.MaskPanel);

        gui.VideoPanel = uix.BoxPanel( ...
            'Parent', upperLayout, ...
            'Title', 'Video');
        gui.VideoAxes = axes( ...
            'Parent', gui.VideoPanel, ...
            'ButtonDownFcn', @PlayVideo, ...
            'HitTest', 'on');

        gui.ListPanel = uix.VBoxFlex( ...
            'Parent', upperLayout);
        gui.ListBox = uicontrol( ...
            'Style', 'ListBox', ...
            'Parent', gui.ListPanel, ...
            'FontSize', 10, ...
            'String', {1, 2, 3, 4, 5, 6, 7, 8, 9, 10});
        gui.ListFB = uix.HBoxFlex( ...
            'Parent', gui.ListPanel, ...
            'Padding', 3);
        gui.ListForward = uicontrol( ...
            'Parent', gui.ListFB, ...
            'Style', 'PushButton', ...
            'String', 'Forward', ...
            'CallBack', @Forward);
        gui.ListBackward = uicontrol( ...
            'Parent', gui.ListFB, ...
            'Style', 'PushButton', ...
            'String', 'Backward', ...
            'CallBack', @Backward);
        set(gui.ListPanel, 'Heights', [-5, -1]);

        set(upperLayout, 'Widths', [-2, -2, -1]);

        % Lower Layout Design
        gui.TracePanel = uix.BoxPanel( ...
            'Parent', lowerLayout, ...
            'Title', 'Trace');
        gui.TraceAxes = axes('Parent', gui.TracePanel);

        gui.ControlPanel = uix.VBoxFlex( ...
            'Parent', lowerLayout);
        gui.ControlPanel2 = uix.VBoxFlex( ...
            'Parent', lowerLayout);
        gui.PlayButton = uicontrol( ...
            'Style', 'PushButton', ...
            'Parent', gui.ControlPanel, ...
            'String', 'Play Video', ...
            'CallBack', @PlayVideo);
        gui.YesButton = uicontrol( ...
            'Style', 'PushButton', ...
            'Parent', gui.ControlPanel, ...
            'String', 'Yes Active', ...
            'CallBack', @YesActive);
        gui.NoButton = uicontrol( ...
            'Style', 'PushButton', ...
            'Parent', gui.ControlPanel, ...
            'String', 'No Active', ...
            'CallBack', @NoActive);

        set(lowerLayout, 'Widths', [-2.5, -1, -1]);
        gui.SetSpikeButton = uicontrol( ...
            'Style', 'PushButton', ...
            'Parent', gui.ControlPanel2, ...
            'String', 'Select Spike', ...
            'CallBack', @PushSpikeButton);
        gui.YesSpikeButton = uicontrol( ...
            'Style', 'PushButton', ...
            'Parent', gui.ControlPanel2, ...
            'String', 'Yes Spike', ...
            'CallBack', @YesSpike);
        gui.NoSpikeButton = uicontrol( ...
            'Style', 'PushButton', ...
            'Parent', gui.ControlPanel2, ...
            'String', 'No Spike', ...
            'CallBack', @NoSpike);
        gui.SaveTraceButton = uicontrol( ...
            'Style', 'PushButton', ...
            'Parent', gui.ControlPanel2, ...
            'String', 'Save Changes', ...
            'CallBack', @SaveTrace);
    end % createInterface

%-------------------------------------------------------------------------%

%% updateInterface - update GUI for new trace
    function updateInterface()
        % Update the Trace
        cla(gui.TraceAxes);
        data1.trace = Trace(i, :);
        plot(gui.TraceAxes, data1.trace);
        hold(gui.TraceAxes, 'on');

        [data1.pk, data1.lk] = findpeaks(data1.trace, 1:data1.T, 'MinPeakDistance', 50, 'MinPeakProminence', 1);
        if ~isempty(data1.lk)
            plot(gui.TraceAxes, data1.lk, data1.pk, 'v');
            mm = normalizeValues(mean(vid(:, :, data1.lk), 3));
            mm = imadjust(mm, stretchlim(mm, 0.002), []);
            data1.maxImg = imadjust(mm, [], [], 0.5);
        else
            data1.maxImg = MAXImg;
        end
        xlabel(gui.TraceAxes, 'time(s)');
        ylabel(gui.TraceAxes, 'deltaf/f*100');
        set(gui.TraceAxes, ...
            'Xlim', data1.tracelimitx, 'Ylim', [floor(min(data1.trace)), ceil(max(data1.trace))], ...
            'Units', 'normalized', 'Position', [0.1, 0.15, 0.8, 0.7]);

        % Update Video
        cla(gui.VideoAxes);
        mask = Mask(:, :, i);
        %             data1.mask = mask;
        data1.mask = mat2gray(mask);
        bw = mask;
        bw(bw > 0) = 1;
        temp = regionprops(bw, data1.mask, 'WeightedCentroid');
        if isempty(temp)
            temp1 = reshape((mean(data1.mask, 1) > 0), 1, []);
            size(temp1)
            [~, temp2] = find(temp1, 1);
            [~, temp3] = find(temp1, 1, 'last');

            data1.center(1) = mean([temp2, temp3]);
            temp1 = reshape((mean(mask, 2) > 0), 1, []);
            size(temp1)
            [~, temp2] = find(temp1, 1);
            [~, temp3] = find(temp1, 1, 'last');

            data1.center(2) = mean([temp2, temp3]);
        else
            data1.center = round(temp.WeightedCentroid);
        end
        data1.boxy1 = max(data1.center(1)-60, 1);
        data1.boxy2 = min(data1.center(1)+60, data1.d2);
        data1.boxx1 = max(data1.center(2)-60, 1);
        data1.boxx2 = min(data1.center(2)+60, data1.d1);

        if ~isempty(data1.lk)
            imagesc(gui.VideoAxes, vid(data1.boxx1:data1.boxx2, data1.boxy1:data1.boxy2, max(data1.lk(1)-30, 1)));
        else
            imagesc(gui.VideoAxes, vid(data1.boxx1:data1.boxx2, data1.boxy1:data1.boxy2, 1));
        end

        colormap(gui.VideoAxes, gray);
        hold(gui.VideoAxes, 'on');

        data1.videomask = data1.mask(data1.boxx1:data1.boxx2, data1.boxy1:data1.boxy2);
        data1.smallgreen = data1.green(data1.boxx1:data1.boxx2, data1.boxy1:data1.boxy2, :);
        gui.smallgreen = image(gui.VideoAxes, data1.smallgreen, 'Alphadata', data1.videomask);

        set(gui.VideoAxes, 'DataAspectRatio', [1, 1, 1], ...
            'Xlim', [1, size(data1.videomask, 2)], 'Ylim', [1, size(data1.videomask, 1)], ...
            'XTick', 1:20:size(data1.videomask, 2), 'YTick', size(data1.videomask, 1), ...
            'XTickLabel', data1.boxy1:20:data1.boxy2, 'YTickLabel', data1.boxx1:20:data1.boxx2);

        gui.rectangle = rectangle(gui.VideoAxes, 'Position', [data1.center(1) - data1.boxy1 - 6, data1.center(2) - data1.boxx1 - 6, 13, 13], 'EdgeColor', 'yellow');
        hold(gui.VideoAxes, 'off');

        % Update the Mask
        data1.masky1 = max(data1.center(1)-30, 1);
        data1.masky2 = min(data1.center(1)+30, data1.d2);
        data1.maskx1 = max(data1.center(2)-30, 1);
        data1.maskx2 = min(data1.center(2)+30, data1.d1);

        mask = data1.mask(data1.maskx1:data1.maskx2, data1.masky1:data1.masky2);
        axes(gui.MaskAxes);
        mm = data1.maxImg(data1.maskx1:data1.maskx2, data1.masky1:data1.masky2);
        imshow(mm, 'Parent', gui.MaskAxes, 'DisplayRange', []);
        colormap(gui.MaskAxes, gray);
        hold(gui.MaskAxes, 'on');
        contour(gui.MaskAxes, mask, 1, 'LineColor', 'y', 'linewidth', 1);
        set(gui.MaskAxes, ...
            'DataAspectRatio', [1, 1, 1], ...
            'XLim', [1, data1.masky2 - data1.masky1 + 1], 'YLim', [1, data1.maskx2 - data1.maskx1 + 1], ...
            'Units', 'normalized', 'Position', [0.1, 0.15, 0.8, 0.7]);
        hold(gui.MaskAxes, 'on');
        IsPlaying = 0;

    end

%% SaveTrace - saves labeling output file and closes GUI window
    function SaveTrace(~, ~)
        %         save('FinalTrace.mat', Trace);
        fclose(fileout);
        close(gui.Window);
    end

%% ResetSpikeArray - Reset spike variables, calculate mean and standard
%deviation for trace, loop through trace to check for spikes of
%activity
    function ResetSpikeArray(~, ~)
        spikeArray = [];
        spikeCheck = false;
        onSpike = false;
        spikeCount = 1;
        yesNoArray = [];
        meanAc = 0;
        std = 0;
        for m = 1:size(vid, 3)
            meanAc = meanAc + Trace(1, m);
        end
        meanAc = meanAc / size(vid, 3);
        for s = 1:size(vid, 3)
            std = std + abs(Trace(1, s)-meanAc);
        end
        std = std / size(vid, 3);
        %           for n = 1:size(Mask, 3)
        foundPeak = false;
        for j = 1:size(vid, 3)
            if (Trace(i, j) - meanAc) / std > 5
                %                    gui.rectangle = rectangle(gui.VideoAxes,'Position',[data1.center(1)-data1.boxy1-6,data1.center(2)-data1.boxx1-6,13,13],'EdgeColor','red');
                if ~onSpike
                    spikeArray = [spikeArray, j];
                    onSpike = true;
                end
                if Trace(i, j+1) < Trace(i, j) && ~foundPeak
                    plot(gui.TraceAxes, j, Trace(i, j), '-s', 'MarkerSize', 10, ...
                        'MarkerEdgeColor', 'red');
                    foundPeak = true;
                end
                %disp((Trace(1, j) - meanAc)/std);
            else
                if onSpike
                    spikeArray = [spikeArray, j];
                    onSpike = false;
                end
                foundPeak = false;
            end
        end
        %           end
        %           for n = 1:size(Mask, 3)

        %           end
        spikeTotal = size(spikeArray, 2) / 2;
        %disp(spikeTotal);
        disp(strcat('Neuron #', int2str(i)));
        if (spikeTotal == 0)
            disp('No spikes found');
        else
            disp(strcat('Total Spikes: ', int2str(spikeTotal)));
        end
    end

%% PlayVideo - play full video for selected neuron
    function PlayVideo(~, ~)

        %             if ishandle(timeline); delete(timeline); end
        if ~isempty(data1.lk)
            playduration = [max(data1.lk(1)-60, 1), min(data1.lk(end)+60, size(Trace, 2))];
        else
            playduration = [1, data1.T];
        end

        hold(gui.VideoAxes, 'on');
        gui.rectangle = rectangle(gui.VideoAxes, 'Position', [data1.center(1) - data1.boxy1 - 6, data1.center(2) - data1.boxx1 - 6, 13, 13], 'EdgeColor', 'yellow');
        gui.smallgreen = image(gui.VideoAxes, data1.smallgreen, 'Alphadata', data1.videomask);

        pause(0.4);
        delete(gui.smallgreen);
        pause(0.4);
        hold(gui.VideoAxes, 'off');
        currentylim = get(gui.TraceAxes, 'Ylim');
        temp = vid(data1.boxx1:data1.boxx2, data1.boxy1:data1.boxy2, :);
        cmin = min(temp(:));
        %cmax = max([0.6*max(temp(:)) cmin]);
        cmax = max([0.9 * max(temp(:)), cmin]);

        % disp(cmin); disp(cmax);
        for j = playduration(1):playduration(2)

            IsPlaying = 1;
            imgShow = vid(data1.boxx1:data1.boxx2, data1.boxy1:data1.boxy2, j);
            imagesc(gui.VideoAxes, imgShow);
            set(gui.VideoAxes, 'clim', [cmin, cmax]);
            hold(gui.VideoAxes, 'on');

            if (Trace(i, j) - meanAc) / std > 5
                %                     disp(abs(Trace(i, j) - meanAc)/std);
                gui.rectangle = rectangle(gui.VideoAxes, 'Position', [data1.center(1) - data1.boxy1 - 6, data1.center(2) - data1.boxx1 - 6, 13, 13], 'EdgeColor', 'red');
            else
                gui.rectangle = rectangle(gui.VideoAxes, 'Position', [data1.center(1) - data1.boxy1 - 6, data1.center(2) - data1.boxx1 - 6, 13, 13], 'EdgeColor', 'yellow');
            end
            set(gui.VideoAxes, 'DataAspectRatio', [1, 1, 1], ...
                'Xlim', [1, size(data1.videomask, 2)], 'Ylim', [1, size(data1.videomask, 1)], ...
                'XTick', 1:30:size(data1.videomask, 2), 'YTick', 1:30:size(data1.videomask, 1), ...
                'XTickLabel', data1.boxy1:30:data1.boxy2, 'YTickLabel', data1.boxx1:30:data1.boxx2);
            colormap(gui.VideoAxes, gray);

            timeline = plot(gui.TraceAxes, [j, j], currentylim, '-', 'Color', 'red');
            pause(0.008);
            delete(timeline);

            if CallBackInterrupted
                CallBackInterrupted = 0;
                IsPlaying = 0;
                return;
            end

            %To prevent freeze in video
            hold(gui.VideoAxes, 'off');
        end
    end

%% PushSpikeButton - start spike labeling, play video for 1st spike
    function PushSpikeButton(~, ~)
        %disp(meanAc);disp(std);
        spikeCheck = true;

        if (spikeTotal > 0)
            fprintf(fileout, strcat(int2str(spikeArray(1)), " ", int2str(spikeArray(2)), " "));
            foundPeak = false;
            for j = max(spikeArray(1)-20, 1):min(spikeArray(2)+20, size(vid, 3))
                IsPlaying = 1;
                imgShow = vid(data1.boxx1:data1.boxx2, data1.boxy1:data1.boxy2, j);
                imagesc(gui.VideoAxes, imgShow);
                hold(gui.VideoAxes, 'on');
                if (Trace(i, j) - meanAc) / std > 5
                    gui.rectangle = rectangle(gui.VideoAxes, 'Position', [data1.center(1) - data1.boxy1 - 6, data1.center(2) - data1.boxx1 - 6, 13, 13], 'EdgeColor', 'red');


                else
                    gui.rectangle = rectangle(gui.VideoAxes, 'Position', [data1.center(1) - data1.boxy1 - 6, data1.center(2) - data1.boxx1 - 6, 13, 13], 'EdgeColor', 'yellow');
                    foundPeak = false;
                end
                set(gui.VideoAxes, 'DataAspectRatio', [1, 1, 1], ...
                    'Xlim', [1, size(data1.videomask, 2)], 'Ylim', [1, size(data1.videomask, 1)], ...
                    'XTick', 1:30:size(data1.videomask, 2), 'YTick', 1:30:size(data1.videomask, 1), ...
                    'XTickLabel', data1.boxy1:30:data1.boxy2, 'YTickLabel', data1.boxx1:30:data1.boxx2);
                colormap(gui.VideoAxes, gray);
                pause(0.008);
                delete(timeline);

                if CallBackInterrupted
                    CallBackInterrupted = 0;
                    IsPlaying = 0;
                    return;
                end
            end
        end


    end

%% YesSpike - Check if user is looking for spikes, print to output file,
%and play video for next spike
    function YesSpike(~, ~)
        if spikeCheck
            fprintf(fileout, strcat(int2str(1), "\n"));
            spikeCount = spikeCount + 1;
            if spikeCount > spikeTotal
                spikeCheck = false;
                spikeCount = 1;
            else
                %disp(int2str(spikeArray(2*spikeCount-1)));
                fprintf(fileout, strcat(int2str(spikeArray(2*spikeCount-1)), " ", int2str(spikeArray(2*spikeCount)), " "));
                for j = spikeArray(2*spikeCount-1) - 20:spikeArray(2*spikeCount) + 20
                    IsPlaying = 1;
                    imgShow = vid(data1.boxx1:data1.boxx2, data1.boxy1:data1.boxy2, j);
                    imagesc(gui.VideoAxes, imgShow);
                    %set(gui.VideoAxes,'clim',[cmin,cmax]);
                    hold(gui.VideoAxes, 'on');
                    if (Trace(i, j) - meanAc) / std > 5
                        gui.rectangle = rectangle(gui.VideoAxes, 'Position', [data1.center(1) - data1.boxy1 - 6, data1.center(2) - data1.boxx1 - 6, 13, 13], 'EdgeColor', 'red');
                    else
                        gui.rectangle = rectangle(gui.VideoAxes, 'Position', [data1.center(1) - data1.boxy1 - 6, data1.center(2) - data1.boxx1 - 6, 13, 13], 'EdgeColor', 'yellow');
                    end
                    set(gui.VideoAxes, 'DataAspectRatio', [1, 1, 1], ...
                        'Xlim', [1, size(data1.videomask, 2)], 'Ylim', [1, size(data1.videomask, 1)], ...
                        'XTick', 1:30:size(data1.videomask, 2), 'YTick', 1:30:size(data1.videomask, 1), ...
                        'XTickLabel', data1.boxy1:30:data1.boxy2, 'YTickLabel', data1.boxx1:30:data1.boxx2);
                    colormap(gui.VideoAxes, gray);
                    pause(0.008);

                    if CallBackInterrupted
                        CallBackInterrupted = 0;
                        IsPlaying = 0;
                        return;
                    end

                    %To prevent freeze in video
                    hold(gui.VideoAxes, 'off');
                end
            end
        end
    end

%% NoSpike - Check if user is looking for spikes, print to output file,
%and play video for next spike
    function NoSpike(~, ~)
        if spikeCheck
            fprintf(fileout, strcat(int2str(0), "\n"));
            spikeCount = spikeCount + 1;

            if spikeCount > spikeTotal
                spikeCheck = false;
                spikeCount = 1;
            else
                fprintf(fileout, strcat(int2str(spikeArray(2*spikeCount-1)), " ", int2str(spikeArray(2*spikeCount)), " "));
                for j = spikeArray(2*spikeCount-1):spikeArray(2*spikeCount)

                    IsPlaying = 1;
                    imgShow = vid(data1.boxx1:data1.boxx2, data1.boxy1:data1.boxy2, j);
                    imagesc(gui.VideoAxes, imgShow);
                    %set(gui.VideoAxes,'clim',[cmin,cmax]);
                    hold(gui.VideoAxes, 'on');
                    if (Trace(i, j) - meanAc) / std > 5
                        gui.rectangle = rectangle(gui.VideoAxes, 'Position', [data1.center(1) - data1.boxy1 - 6, data1.center(2) - data1.boxx1 - 6, 13, 13], 'EdgeColor', 'red');
                    else
                        gui.rectangle = rectangle(gui.VideoAxes, 'Position', [data1.center(1) - data1.boxy1 - 6, data1.center(2) - data1.boxx1 - 6, 13, 13], 'EdgeColor', 'yellow');
                    end
                    set(gui.VideoAxes, 'DataAspectRatio', [1, 1, 1], ...
                        'Xlim', [1, size(data1.videomask, 2)], 'Ylim', [1, size(data1.videomask, 1)], ...
                        'XTick', 1:30:size(data1.videomask, 2), 'YTick', 1:30:size(data1.videomask, 1), ...
                        'XTickLabel', data1.boxy1:30:data1.boxy2, 'YTickLabel', data1.boxx1:30:data1.boxx2);
                    colormap(gui.VideoAxes, gray);

                    %                timeline = plot(gui.TraceAxes,[j j],currentylim,'-','Color','red');
                    pause(0.008);
                    delete(timeline);

                    if CallBackInterrupted
                        CallBackInterrupted = 0;
                        IsPlaying = 0;
                        return;
                    end

                    %To prevent freeze in video
                    hold(gui.VideoAxes, 'off');
                end
            end
        end
    end

%% YesActive - print active neuron to output file
    function YesActive(~, ~)
        fprintf(fileout, strcat(int2str(i), " 1\n"));
    end

%% NoActive - print inactive neuron to output file
    function NoActive(~, ~)
        fprintf(fileout, strcat(int2str(i), " 0\n"));
    end

%% Forward - move current neuron forward 1 and update interface
    function Forward(~, ~)
        if ~(i == size(Mask, 3))
            i = i + 1;
        end
        %             disp(i);
        updateInterface();
        ResetSpikeArray();
        set(gui.ListBox, 'Value', i);
    end

%% Backward - move current neuron backward 1 and update interface
    function Backward(~, ~)
        if ~(i == 1)
            i = i - 1;
        end
        %             disp(i);
        updateInterface();
        ResetSpikeArray();
        set(gui.ListBox, 'Value', i);
    end

%% setListBox - set box for list of neurons using mask array size
    function setListBox()
        arr = [];
        for c = 1:size(Mask, 3)
            arr = [arr, c];
        end
        set(gui.ListBox, 'String', arr);

    end
end