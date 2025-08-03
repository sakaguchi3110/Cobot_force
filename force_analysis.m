%% I Directory

subject_id = 'P35';


% row data folder
cd ("C:\Users\saisa68\OneDrive - Linköpings universitet\Skin OCT - OCT_BRUSH\1_primary\Forcesensor")
load([subject_id '.mat']);  

% functions folder
addpath("C:\Users\saisa68\OneDrive - Linköpings universitet\04 Works\02 BRUSH exp\Mat");

% save folder
save_dir = "C:\Users\saisa68\OneDrive - Linköpings universitet\Skin OCT - OCT_BRUSH\2_processed\Forcesensor";


%% II CHeck Trigger shape
% 
% cd ("C:\Users\saisa68\OneDrive - Linköpings universitet\04 Works\02 BRUSH exp\Mat")
% Fs = 1000; % Sampling rate
% 
% % Initialize duration lists
% web_durations = [];
% thumb_durations = [];
% 
% % Loop through blocks
% % for block_num = 1:size(datastart, 2)
% %     % Determine group by checking comtext
% %     condition = strtrim(comtext(block_num, :)); % remove trailing spaces
% %     if contains(lower(condition), 'web')
% %         group = 'web';
% %     elseif contains(lower(condition), 'thumb')
% %         group = 'thumb';
% %     else
% %         continue; % skip if not matched
% %     end
% 
% current_label = '';  % 初期化
% 
% for block_num = 1:size(datastart, 2)
%     % comtextの範囲内かつ空でなければラベルを更新
%     if block_num <= size(comtext, 1)
%         temp_label = strtrim(comtext(block_num, :));
%         if ~isempty(temp_label)
%             current_label = temp_label;
%         end
%     end
% 
%     % ラベルを小文字にして前後の空白を削除（表記ゆれ対応）
%     label = lower(strtrim(current_label));
% 
%     % ラベル内に "web" や "thumb" を含むかで分類
%     if contains(label, 'web')
%         group = 'web';
%     elseif contains(label, 'thumb')
%         group = 'thumb';
%     else
%         continue;  % どちらでもなければ無視
%     end
% 
% %    
% 
%     % Extract trigger signal (Ch8)
%     idx_start = datastart(7, block_num);
%     idx_end = dataend(7, block_num);
%     trigger_signal = data(idx_start:idx_end);
% 
%     % Detect ON regions
%     is_on = trigger_signal >= 5;
%     edges = diff([0 is_on 0]);
%     on_starts = find(edges == 1);
%     on_ends = find(edges == -1) - 1;
% 
%     for i = 1:length(on_starts)
%         duration_sec = (on_ends(i) - on_starts(i) + 1) / Fs;
%         if strcmp(group, 'web')
%             web_durations(end+1) = duration_sec;
%         elseif strcmp(group, 'thumb')
%             thumb_durations(end+1) = duration_sec;
%         end
%     end
% end
% 
% 
% % Plot histograms
% fig = figure('Name', 'Trigger Duration Histogram');
% set(fig, 'WindowState', 'maximized');
% 
% subplot(2,1,1);
% histogram(web_durations, 'BinWidth', 0.2);
% title('Trigger Durations - WEB');
% xlabel('Duration (s)');
% ylabel('Count');
% xlim([0 20])
% set(fig, 'WindowState', 'maximized');
% grid on;
% 
% % --- Interactive selection ---
% disp('--- Select range for Velocity30 [WEB] ---');
% [x, ~] = ginput(2);
% range_web.Velocity30 = sort(x);
% 
% disp('--- Select range for Velocity3_0 [WEB] ---');
% [x, ~] = ginput(2);
% range_web.Velocity3_0 = sort(x);
% 
% disp('--- Select range for Velocity0_3 [WEB] ---');
% [x, ~] = ginput(2);
% range_web.Velocity0_3 = sort(x);
% 
% subplot(2,1,2);
% histogram(thumb_durations, 'BinWidth', 0.2);
% title('Trigger Durations - THUMB');
% xlabel('Duration (s)');
% ylabel('Count');
% xlim([0 20])
% grid on;
% 
% disp('--- Select range for Velocity30 [THUMB] ---');
% [x, ~] = ginput(2);
% range_thumb.Velocity30 = sort(x);
% 
% disp('--- Select range for Velocity3_0 [THUMB] ---');
% [x, ~] = ginput(2);
% range_thumb.Velocity3_0 = sort(x);
% 
% disp('--- Select range for Velocity0_3 [THUMB] ---');
% [x, ~] = ginput(2);
% range_thumb.Velocity0_3 = sort(x);
% 
% % Parameters duration
% Fs = 1000;
% num_channels = size(datastart,1);
% velocity_classes = {'Velocity30', 'Velocity3_0', 'Velocity0_3'};
% 
% param = build_velocity_param(range_web, range_thumb, Fs);
% 
% fields = fieldnames(param);
% for i = 1:length(fields)
%     name = fields{i};
%     param.(name).pre_samples_web   = round(param.(name).pre_sec_web   * Fs);
%     param.(name).pre_samples_thumb = round(param.(name).pre_sec_thumb * Fs);
%     param.(name).post_samples      = round(param.(name).post_sec      * Fs);
% end
% 
% close all

%% II CHeck Trigger shape,, multiple comments in one data block

cd("C:\Users\saisa68\OneDrive - Linköpings universitet\04 Works\02 BRUSH exp\Mat")
Fs = 1000; % Sampling rate

% Initialize duration lists
web_durations = [];
thumb_durations = [];

num_channels = size(datastart, 1);  
trigger_channel = num_channels;  

% ===== データ抽出・分類 =====
for i = 1:size(comtext, 1)
    % ---- ラベルの取得と分類 ----
    current_label = strtrim(comtext(i, :));
    label = lower(current_label);

    if contains(label, 'web')
        group = 'web';
    elseif contains(label, 'thumb')
        group = 'thumb';
    else
        continue;  % 該当しないラベルはスキップ
    end

    % ---- com 情報からインデックス取得 ----
    com_block = com(i,2);
    com_offset = com(i,3);

    if com_block > size(datastart, 2)
        warning("com block index (%d) exceeds datastart columns", com_block);
        continue;
    end

    idx_start = datastart(trigger_channel, com_block) + com_offset;

    if i < size(com,1)
        next_block = com(i+1,2);
        next_offset = com(i+1,3);
        idx_end = datastart(trigger_channel, next_block) + next_offset - 1;
    else
        idx_end = dataend(trigger_channel, com_block);  % 最終行のみ dataend 使用
    end

    % ---- トリガー信号の抽出 ----
    trigger_signal = data(idx_start:idx_end);

    % ---- ON区間検出 ----
    is_on = trigger_signal >= 5;
    edges = diff([0 is_on 0]);
    on_starts = find(edges == 1);
    on_ends = find(edges == -1) - 1;

    % ---- 持続時間を秒で保存 ----
    for j = 1:length(on_starts)
        duration_sec = (on_ends(j) - on_starts(j) + 1) / Fs;
        if strcmp(group, 'web')
            web_durations(end+1) = duration_sec;
        elseif strcmp(group, 'thumb')
            thumb_durations(end+1) = duration_sec;
        end
    end
end

% ===== ヒストグラムと範囲選択 =====
fig = figure('Name', 'Trigger Duration Histogram');
set(fig, 'WindowState', 'maximized');

subplot(2,1,1);
histogram(web_durations, 'BinWidth', 0.2);
title('Trigger Durations - WEB');
xlabel('Duration (s)');
ylabel('Count');
xlim([0 20])
grid on;

% --- Interactive selection for WEB ---
disp('--- Select range for Velocity30 [WEB] ---');
[x, ~] = ginput(2);
range_web.Velocity30 = sort(x);

disp('--- Select range for Velocity3_0 [WEB] ---');
[x, ~] = ginput(2);
range_web.Velocity3_0 = sort(x);

disp('--- Select range for Velocity0_3 [WEB] ---');
[x, ~] = ginput(2);
range_web.Velocity0_3 = sort(x);

subplot(2,1,2);
histogram(thumb_durations, 'BinWidth', 0.2);
title('Trigger Durations - THUMB');
xlabel('Duration (s)');
ylabel('Count');
xlim([0 20])
grid on;

% --- Interactive selection for THUMB ---
disp('--- Select range for Velocity30 [THUMB] ---');
[x, ~] = ginput(2);
range_thumb.Velocity30 = sort(x);

disp('--- Select range for Velocity3_0 [THUMB] ---');
[x, ~] = ginput(2);
range_thumb.Velocity3_0 = sort(x);

disp('--- Select range for Velocity0_3 [THUMB] ---');
[x, ~] = ginput(2);
range_thumb.Velocity0_3 = sort(x);

% ===== パラメータ生成と補正 =====
velocity_classes = {'Velocity30', 'Velocity3_0', 'Velocity0_3'};
param = build_velocity_param(range_web, range_thumb, Fs);

fields = fieldnames(param);
for i = 1:length(fields)
    name = fields{i};
    param.(name).pre_samples_web   = round(param.(name).pre_sec_web   * Fs);
    param.(name).pre_samples_thumb = round(param.(name).pre_sec_thumb * Fs);
    param.(name).post_samples      = round(param.(name).post_sec      * Fs);
end

close all



%% III Convert comments into segments (comment-based block segmentation)
block_segments = {};
segment_index = 0;

num_comments = size(com, 1);
num_blocks = size(datastart, 2);
block_start_times = datastart(1, :);  % block start times (samples)

for i = 1:num_comments
    block_num = com(i, 2);
    rel_time_in_block = com(i, 3);
    comment_index = com(i, 5);  % index in comtext

    % skip if comment index is invalid
    if isnan(comment_index) || comment_index <= 0 || comment_index > size(comtext, 1)
        continue;
    end

    current_label = strtrim(comtext(comment_index, :));
    current_time = datastart(1, block_num) + rel_time_in_block;

    if i < num_comments
        next_time = datastart(1, com(i+1, 2)) + com(i+1, 3);
    else
        next_time = dataend(1, block_num);  % if last comment, go to block end
    end

    % determine group based on label
    if contains(lower(current_label), 'web')
        group = 'web';
    elseif contains(lower(current_label), 'thumb')
        group = 'thumb';
    else
        continue;  % unknown label, skip
    end

    % initialize new segment
    segment_index = segment_index + 1;
    block_segments{segment_index} = struct();
    for cname = velocity_classes
        block_segments{segment_index}.(cname{1}) = {};
    end

    channel_len = datastart(2, block_num) - datastart(1, block_num);
    block_len = next_time - current_time + 1;
    block_matrix = zeros(num_channels, block_len);

    for ch = 1:num_channels
        offset = channel_len * (ch - 1);
        sta_ind = current_time + offset;
        end_ind = sta_ind + channel_len;
        actual_end_ind = min(end_ind, length(data));
        actual_len = actual_end_ind - sta_ind + 1;
        block_matrix(ch, 1:actual_len) = data(sta_ind:actual_end_ind);
    end

    trigger_signal = block_matrix(num_channels, :);
    is_on = trigger_signal >= 5;
    edges = diff([0 is_on 0]);
    on_starts = find(edges == 1);
    on_ends = find(edges == -1) - 1;

    for j = 1:length(on_starts)
        start_idx = on_starts(j);
        end_idx = on_ends(j);
        duration_sec = (end_idx - start_idx + 1) / Fs;

        if start_idx <= 1 || end_idx >= length(trigger_signal)
            fprintf('⏭️ Skipping segment: trigger does not have proper OFF→ON→OFF structure\n');
            continue;
        end

        matched = false;
        for cname = fieldnames(param)'
            cname = cname{1};
            range = param.(cname).(['range_' group]);

            if duration_sec >= range(1) && duration_sec <= range(2)
                if strcmp(group, 'web')
                    pre_samples = param.(cname).pre_samples_web;
                else
                    pre_samples = param.(cname).pre_samples_thumb;
                end
                post_samples = param.(cname).post_samples;

                center_idx = end_idx;
                sig_start = max(1, center_idx - pre_samples);
                sig_end   = min(block_len, center_idx + post_samples);
                t = (-pre_samples:(sig_end - center_idx)) / Fs;

                ch_all = block_matrix(:, sig_start:sig_end);
                trg_seg = trigger_signal(sig_start:sig_end);

                % store trial data
                block_segments{segment_index}.(cname){end+1} = struct( ...
                    'channels', ch_all, ...
                    'trigger', trg_seg, ...
                    't', t, ...
                    'blockname', current_label, ...
                    'block_num', block_num, ...
                    'comment_index', comment_index, ...
                    'timestamp', current_time / Fs ...
                );

                matched = true;
                break;
            end
        end

        if ~matched
            fprintf('Unclassified trigger in block %d (%.2f sec)\n', block_num, duration_sec);
        end
    end
end



%% IV-I Backup before interactive removal (for undo)

block_segments_backup = block_segments;
disp('✅ Backup complete. You can restore with: block_segments = block_segments_backup;');

%% IV-II Clear unwanted triggers interactively
removal_log = {}; % Each row: {BlockNumber, ClassName, TriggerStartTime}

for c = 1:length(velocity_classes)
    class = velocity_classes{c};
    for s = 1:length(block_segments)
        [block_segments, removed_triggers] = plot_block_class_overlay_with_removal(block_segments, s, class);

        for i = 1:length(removed_triggers)
            removal_log(end+1, :) = {s, class, removed_triggers(i)};
        end
    end
end


%% %%% IV-III (if needed) Undo

block_segments = restore_segment(block_segments, block_segments_backup, 100); % TYPE segment number

%%%%%

%% Save

save(fullfile(save_dir, [subject_id '_processed.mat']), ...
    'block_segments', ...
    'Fs', ...
    'velocity_classes', ...
    'datastart', 'dataend', ...
    'comtext', ...
    'param', ...
    'num_channels', ...
    '-v7.3');

fprintf('Saved: %s_processed.mat\n', subject_id);


%% SHOW PLOT

plot_resultant_force_all(block_segments, Fs, false, subject_id, param); % ONLY PLOT

%% SAVE PLOT 
plot_resultant_force_all(block_segments, Fs, true, subject_id, param);  % SAVE DATA AND PLOT
