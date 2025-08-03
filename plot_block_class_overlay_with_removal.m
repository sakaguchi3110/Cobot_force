% function [block_segments, removed_trigger_times] = plot_block_class_overlay_with_removal(block_segments, block_num, classname)
%     segments = block_segments{block_num}.(classname);
%     removed_trigger_times = [];
% 
%     if isempty(segments)
%         fprintf('No segments for %s in block %d\n', classname, block_num);
%         return;
%     end
% 
%     blockname = segments{1}.blockname;
%     figure('Name', sprintf('%s - %s (Click waveform to remove)', blockname, classname));
%     hold on;
% 
%     handles = gobjects(length(segments), 1);
%     triggers = gobjects(length(segments), 1);
%     cmap = lines(length(segments));
% 
%     % Prepare containers to track removal
%     is_removed = false(1, length(segments));
%     trigger_on_times = NaN(1, length(segments));
% 
%     yyaxis left;
%     ylabel('Ch1 Signal (V)');
%     xlabel('Time (s)');
% 
%     for i = 1:length(segments)
%         seg = segments{i};
%         yyaxis left;
%         handles(i) = plot(seg.t, seg.channels(1, :), '-', ...
%             'Color', cmap(i,:), 'ButtonDownFcn', {@removeTrace, i});
%         yyaxis right;
%         triggers(i) = plot(seg.t, seg.trigger, '--', ...
%             'Color', cmap(i,:), 'ButtonDownFcn', {@removeTrace, i});
%     end
% 
%     yyaxis right;
%     ylabel('Trigger Signal (V)');
%     yyaxis left;
%     title([blockname ' - ' strrep(classname, '_', '.') ' (Click waveform to remove)'], 'Interpreter', 'none');
%     grid on;
% 
%     % Wait for user input before continuing
%     uiwait(gcf);
% 
%     % Remove flagged segments and collect trigger times
%     for i = length(segments):-1:1
%         if is_removed(i)
%             segments(i) = [];
%             removed_trigger_times(end+1) = trigger_on_times(i);
%         end
%     end
% 
%     block_segments{block_num}.(classname) = segments;
% 
%     % --- Nested callback function ---
%     function removeTrace(~, ~, idx)
%         if is_removed(idx)
%             return;
%         end
%         seg = segments{idx};
%         t = seg.t;
%         trig = seg.trigger;
% 
%         % Detect rising edge (crossing 5V from below)
%         cross_idx = find(trig(1:end-1) <= 5 & trig(2:end) > 5, 1, 'first');
%         if ~isempty(cross_idx)
%             % Linear interpolation to find exact crossing time
%             t1 = t(cross_idx);
%             t2 = t(cross_idx + 1);
%             y1 = trig(cross_idx);
%             y2 = trig(cross_idx + 1);
%             trigger_time = t1 + (5 - y1) / (y2 - y1) * (t2 - t1);
%         else
%             trigger_time = NaN;
%         end
% 
%         trigger_on_times(idx) = trigger_time;
%         is_removed(idx) = true;
% 
%         delete(handles(idx));
%         delete(triggers(idx));
%         disp(['Removed waveform ID ' num2str(idx)]);
%     end
% end
function [block_segments, removed_trigger_times] = plot_block_class_overlay_with_removal(block_segments, block_num, classname)
    segments = block_segments{block_num}.(classname);
    segments = segments(~cellfun(@isempty, segments));  % 空の要素を除去
    removed_trigger_times = [];

    if isempty(segments)
        fprintf('No segments for %s in block %d\n', classname, block_num);
        return;
    end

    blockname = segments{1}.blockname;
    figure('Name', sprintf('%s - %s (Click waveform to remove)', blockname, classname));
    hold on;

    handles = gobjects(length(segments), 1);
    triggers = gobjects(length(segments), 1);
    cmap = lines(length(segments));

    % Prepare containers to track removal
    is_removed = false(1, length(segments));
    trigger_on_times = NaN(1, length(segments));

    yyaxis left;
    ylabel('Ch1 Signal (V)');
    xlabel('Time (s)');

    for i = 1:length(segments)
        seg = segments{i};

        if isempty(seg.t) || isempty(seg.channels)
            fprintf('[!] Empty segment skipped: %d of block %d\n', i, block_num);
            continue;
        end

        len_t = length(seg.t);
        len_ch = size(seg.channels, 2);
        [num_ch_rows, num_ch_cols] = size(seg.channels);
    
        fprintf('Length of seg.t       : %d\n', len_t);
        fprintf('Size of seg.channels  : [%d x %d]\n', num_ch_rows, num_ch_cols);

            % 長さ不一致のチェック
        if len_t ~= len_ch
            fprintf('[!] Length mismatch: seg.t = %d, seg.channels = %d (segment %d of block %d)\n', ...
                len_t, len_ch, i, block_num);
            fprintf('    --> Skipping this segment for plotting\n\n');
            continue;
        end

        yyaxis left;
        handles(i) = plot(seg.t, seg.channels(1, :), '-', ...
            'Color', cmap(i,:), 'ButtonDownFcn', {@removeTrace, i});

        yyaxis right;
        triggers(i) = plot(seg.t, seg.trigger, '--', ...
            'Color', cmap(i,:), 'ButtonDownFcn', {@removeTrace, i});
    end

    yyaxis right;
    ylabel('Trigger Signal (V)');
    yyaxis left;
    title([blockname ' - ' strrep(classname, '_', '.') ' (Click waveform to remove)'], 'Interpreter', 'none');
    grid on;

    % Wait for user input before continuing
    uiwait(gcf);

    % Remove flagged segments and collect trigger times
    for i = length(segments):-1:1
        if is_removed(i)
            segments(i) = [];
            removed_trigger_times(end+1) = trigger_on_times(i);
        end
    end

    block_segments{block_num}.(classname) = segments;

    % --- Nested callback function ---
    function removeTrace(~, ~, idx)
        if is_removed(idx)
            return;
        end
        seg = segments{idx};
        t = seg.t;
        trig = seg.trigger;

        % Detect rising edge (crossing 5V from below)
        cross_idx = find(trig(1:end-1) <= 5 & trig(2:end) > 5, 1, 'first');
        if ~isempty(cross_idx)
            % Linear interpolation to find exact crossing time
            t1 = t(cross_idx);
            t2 = t(cross_idx + 1);
            y1 = trig(cross_idx);
            y2 = trig(cross_idx + 1);
            trigger_time = t1 + (5 - y1) / (y2 - y1) * (t2 - t1);
        else
            trigger_time = NaN;
        end

        trigger_on_times(idx) = trigger_time;
        is_removed(idx) = true;

        delete(handles(idx));
        delete(triggers(idx));
        disp(['Removed waveform ID ' num2str(idx)]);
    end
end
