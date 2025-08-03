% function plot_resultant_force_all(block_segments, Fs, save_result, subject_id, param)
%     save_dir = "C:\Users\saisa68\OneDrive - Linköpings universitet\Skin OCT - OCT_BRUSH\2_processed\Forcesensor";
% 
%     velocity_classes = {'Velocity30', 'Velocity3_0', 'Velocity0_3'};
%     baseline_window = 0.3;
% 
%     resultant_force_table = table();
% 
%     for v = 1:length(velocity_classes)
%         cname = velocity_classes{v};
%         fig = figure('Name', cname); clf;
% 
%         % count only valid blocks
%         valid_blocks = find(arrayfun(@(b) isfield(block_segments{b}, cname) && ...
%             ~isempty(block_segments{b}.(cname)) && ...
%             ~contains(lower(block_segments{b}.(cname){1}.blockname), 'air'), 1:length(block_segments)));
%         num_blocks_to_plot = numel(valid_blocks);
%         num_cols = ceil(sqrt(num_blocks_to_plot));
%         num_rows = ceil(num_blocks_to_plot / num_cols);
% 
%         t = tiledlayout(num_rows, num_cols, 'TileSpacing', 'compact', 'Padding', 'compact');
% 
%         ref_segs = {};
%         for b = 1:length(block_segments)
%             if isfield(block_segments{b}, cname)
%                 segs = block_segments{b}.(cname);
%                 if ~isempty(segs) && isfield(segs{1}, 'blockname') && contains(lower(segs{1}.blockname), 'air')
%                     ref_segs = segs;
%                     break;
%                 end
%             end
%         end
% 
%         subplot_idx = 0;
%         y_min = inf; y_max = -inf;
% 
%         for b = valid_blocks
%             segs = block_segments{b}.(cname);
%             blk_title = block_segments{b}.(cname){1}.blockname;
% 
%             subplot_idx = subplot_idx + 1;
%             ax = nexttile;
%             hold(ax, 'on');
% 
%             % --- pre_samples from param ---
%             if ~isfield(param, cname)
%                 fprintf('Skipping %s: not found in param\n', cname);
%                 continue;
%             end
%             if contains(lower(blk_title), 'web')
%                 if ~isfield(param.(cname), 'pre_samples_web')
%                     fprintf('Skipping %s: pre_samples_web not defined\n', cname);
%                     continue;
%                 end
%                 pre_samples = param.(cname).pre_samples_web;
%             elseif contains(lower(blk_title), 'thumb')
%                 if ~isfield(param.(cname), 'pre_samples_thumb')
%                     fprintf('Skipping %s: pre_samples_thumb not defined\n', cname);
%                     continue;
%                 end
%                 pre_samples = param.(cname).pre_samples_thumb;
%             else
%                 fprintf('Skipping %s: cannot determine group from blockname\n', cname);
%                 continue;
%             end
% 
%             post_samples = param.(cname).post_samples;
%             total_len = pre_samples + post_samples + 1;
% 
%             for s = 1:length(segs)
%                 seg = segs{s};
%                 tvec = seg.t;
%                 ch = seg.channels;
%                 trg = seg.trigger;
% 
%                 % --- detect trigger OFF point (last high value)
%                 trg_on = trg > 5;
%                 edges = diff([trg_on, 0]);
%                 off_idx = find(edges == -1, 1, 'last');
% 
%                 if isempty(off_idx) || off_idx < baseline_window * Fs || off_idx + baseline_window * Fs > length(trg)
%                     fprintf('Segment %d skipped: no valid OFF edge or out of range.\n', s);
%                     continue;
%                 end
% 
%                 % ±0.005秒のベースライン区間
%                 base_idx = (off_idx - round(baseline_window * Fs)):(off_idx + round(baseline_window * Fs));
% 
%                 % 対象信号ベースライン
%                 bl_signal = mean(ch(1:3, base_idx), 2);
% 
%                 % 参照信号のベースライン
%                 ref_ch = zeros(3, total_len);
%                 for k = 1:3
%                     mats = cellfun(@(x) x.channels(k,:), ref_segs, 'UniformOutput', false);
%                     mats = vertcat(mats{:});
%                     if size(mats, 2) == total_len
%                         ref_ch(k,:) = mean(mats,1);
%                     end
%                 end
%                 ref_bl = mean(ref_ch(:, base_idx), 2);
% 
%                 % 補正処理
%                 adj_signal = ch(1:3,:) - bl_signal;
%                 adj_ref = ref_ch - ref_bl;
% 
%                 force_diff = adj_signal - adj_ref;
%                 norm_force = vecnorm(force_diff);
%                 smooth_window = round(0.05 * Fs);
%                 norm_force = movmean(norm_force, smooth_window);
% 
%                 colors = {'b', 'g', 'r'};
%                 yyaxis left;
%                 for k = 1:3
%                     plot(tvec, force_diff(k,:), '-', 'Color', colors{k}, 'LineWidth', 1);
%                 end
%                 plot(tvec, norm_force, 'k-', 'LineWidth', 1.2);
%                 y_min = min([y_min, min(force_diff(:)), min(norm_force)]);
%                 y_max = max([y_max, max(force_diff(:)), max(norm_force)]);
% 
%                 yyaxis right;
%                 plot(tvec, trg, 'r--');
%                 ylim([0 10]);
% 
%                 title(remove_subject_from_blkname(blk_title), 'Interpreter', 'none');
% 
%                 N = length(tvec);
%                 segment_table = table(...
%                     repmat(subject_id, N, 1), ...
%                     repmat(string(cname), N, 1), ...
%                     repmat(string(blk_title), N, 1), ...
%                     repmat(s, N, 1), ...
%                     tvec(:), ...
%                     force_diff(1,:)', force_diff(2,:)', force_diff(3,:)', trg(:), norm_force(:), ...
%                     'VariableNames', {'Subject','VelocityClass','BlockName','Segment','Time','Ch1','Ch2','Ch3','Trigger','Resultant'});
%                 resultant_force_table = [resultant_force_table; segment_table];
%             end
% 
%             if subplot_idx == 1
%                 legend({'Ch1', 'Ch2', 'Ch3', 'Resultant force'}, ...
%                     'Location', 'best', 'FontSize', 8, 'Box', 'off');
%             end
% 
%         end
% 
%         % scalling
%         ax_all = findall(fig, 'Type', 'axes');
%         for ax = ax_all'
%             yyaxis(ax, 'left');
%             ylim(ax, [y_min, y_max]);
%         end
% 
%         % shared lables
%         xlabel(t, 'Time (s)');
%         ylabel(t, 'Resultant force (V)');
%         sgtitle(t, sprintf('%s - %s', subject_id, strrep(cname, '_', '.')));
% 
%         if save_result
%             save(fullfile(save_dir, [subject_id '_processed.mat']), 'resultant_force_table', '-append');
%             fprintf('Appended resultant_force_table to %s_processed.mat\n', subject_id);
%             set(fig, 'WindowState', 'maximized');
%             saveas(fig, fullfile(save_dir, [subject_id '_' cname '_resultant_plot.png']));
%         end
%     end
% 
% 
%     function label = remove_subject_from_blkname(blk_title)
%         tokens = strsplit(strtrim(blk_title));
%         if numel(tokens) > 1
%             label = strjoin(tokens(2:end), ' ');
%         else
%             label = blk_title;
%         end
%     end
% 
% end
function plot_resultant_force_all(block_segments, Fs, save_result, subject_id, param)
    save_dir = "C:\Users\saisa68\OneDrive - Linköpings universitet\Skin OCT - OCT_BRUSH\2_processed\Forcesensor";

    velocity_classes = {'Velocity30', 'Velocity3_0', 'Velocity0_3'};
    baseline_window = 0.3;

    resultant_force_table = table();

    % block_segments is assumed to be a cell array
    for v = 1:length(velocity_classes)
        cname = velocity_classes{v};
        fig = figure('Name', cname); clf;

        valid_blocks = find(arrayfun(@(b) ...
            isfield(block_segments{b}, cname) && ...
            ~isempty(block_segments{b}.(cname)) && ...
            isfield(block_segments{b}.(cname){1}, 'blockname') && ...
            ~contains(lower(block_segments{b}.(cname){1}.blockname), 'air'), ...
            1:length(block_segments)));


        num_blocks_to_plot = numel(valid_blocks);
        num_cols = ceil(sqrt(num_blocks_to_plot));
        num_rows = ceil(num_blocks_to_plot / num_cols);

        t = tiledlayout(num_rows, num_cols, 'TileSpacing', 'compact', 'Padding', 'compact');

        % reference segments
        ref_segs = {};
        for ref_b = 1:length(block_segments)
            if isfield(block_segments{ref_b}, cname)
                segs = block_segments{ref_b}.(cname);
                if ~isempty(segs) && isfield(segs{1}, 'blockname') && contains(lower(segs{1}.blockname), 'air')
                    ref_segs = segs;
                    break;
                end
            end
        end

        subplot_idx = 0;
        y_min = inf; y_max = -inf;

        for b = valid_blocks
            segs = block_segments{b}.(cname);
            blk_title = segs{1}.blockname;

            subplot_idx = subplot_idx + 1;
            ax = nexttile;
            hold(ax, 'on');

            if ~isfield(param, cname)
                fprintf('Skipping %s: not found in param\n', cname);
                continue;
            end
            if contains(lower(blk_title), 'web')
                if ~isfield(param.(cname), 'pre_samples_web')
                    fprintf('Skipping %s: pre_samples_web not defined\n', cname);
                    continue;
                end
                pre_samples = param.(cname).pre_samples_web;
            elseif contains(lower(blk_title), 'thumb')
                if ~isfield(param.(cname), 'pre_samples_thumb')
                    fprintf('Skipping %s: pre_samples_thumb not defined\n', cname);
                    continue;
                end
                pre_samples = param.(cname).pre_samples_thumb;
            else
                fprintf('Skipping %s: cannot determine group from blockname\n', cname);
                continue;
            end

            post_samples = param.(cname).post_samples;
            total_len = pre_samples + post_samples + 1;

            for s = 1:length(segs)
                seg = segs{s};
                tvec = seg.t;
                ch = seg.channels;
                trg = seg.trigger;

                trg_on = trg > 5;
                edges = diff([trg_on, 0]);
                off_idx = find(edges == -1, 1, 'last');

                if isempty(off_idx) || off_idx < baseline_window * Fs || off_idx + baseline_window * Fs > length(trg)
                    fprintf('Segment %d skipped: no valid OFF edge or out of range.\n', s);
                    continue;
                end

                base_idx = (off_idx - round(baseline_window * Fs)):(off_idx + round(baseline_window * Fs));


                bl_signal = mean(ch(1:3, base_idx), 2);

                ref_ch = zeros(3, total_len);
                for k = 1:3
                    valid_mats = {};
                    for r = 1:length(ref_segs)
                        ref_seg = ref_segs{r};
                        if size(ref_seg.channels, 2) == total_len
                            valid_mats{end+1} = ref_seg.channels(k, :);
                        end
                    end
                    if ~isempty(valid_mats)
                        ref_ch(k,:) = mean(vertcat(valid_mats{:}), 1);
                    else
                        fprintf('No valid reference segments for channel %d\n', k);
                        ref_ch(k,:) = zeros(1, total_len);
                    end
                end

                % ✅ ref_ch を作った後ならチェックOK！
                if any(base_idx < 1) || any(base_idx > size(ch,2)) || any(base_idx > size(ref_ch,2))
                    fprintf('Skipping segment %d due to invalid base_idx\n', s);
                    continue;
                end
                ref_bl = mean(ref_ch(:, base_idx), 2);
                fprintf('ch size before adj_signal: [%d x %d]\n', size(ch,1), size(ch,2));
                adj_signal = ch(1:3,:) - bl_signal;
                adj_ref = ref_ch - ref_bl;

                force_diff = adj_signal - adj_ref;
                norm_force = vecnorm(force_diff);
                smooth_window = round(0.05 * Fs);
                norm_force = movmean(norm_force, smooth_window);

                colors = {'b', 'g', 'r'};
                yyaxis left;
                for k = 1:3
                    plot(tvec, force_diff(k,:), '-', 'Color', colors{k}, 'LineWidth', 1);
                end
                plot(tvec, norm_force, 'k-', 'LineWidth', 1.2);
                y_min = min([y_min, min(force_diff(:)), min(norm_force)]);
                y_max = max([y_max, max(force_diff(:)), max(norm_force)]);

                yyaxis right;
                plot(tvec, trg, 'r--');
                ylim([0 10]);

                title(remove_subject_from_blkname(blk_title), 'Interpreter', 'none');

                N = length(tvec);
                segment_table = table(...
                    repmat(subject_id, N, 1), ...
                    repmat(string(cname), N, 1), ...
                    repmat(string(blk_title), N, 1), ...
                    repmat(s, N, 1), ...
                    tvec(:), ...
                    force_diff(1,:)', force_diff(2,:)', force_diff(3,:)', trg(:), norm_force(:), ...
                    'VariableNames', {'Subject','VelocityClass','BlockName','Segment','Time','Ch1','Ch2','Ch3','Trigger','Resultant'});
                resultant_force_table = [resultant_force_table; segment_table];
            end

            if subplot_idx == 1
                legend({'Ch1', 'Ch2', 'Ch3', 'Resultant force'}, ...
                    'Location', 'best', 'FontSize', 8, 'Box', 'off');
            end
        end

        ax_all = findall(fig, 'Type', 'axes');
        for ax = ax_all'
            yyaxis(ax, 'left');
            ylim(ax, [y_min, y_max]);
        end

        xlabel(t, 'Time (s)');
        ylabel(t, 'Resultant force (V)');
        sgtitle(t, sprintf('%s - %s', subject_id, strrep(cname, '_', '.')));

        if save_result
            save(fullfile(save_dir, [subject_id '_processed.mat']), 'resultant_force_table', '-append');
            fprintf('Appended resultant_force_table to %s_processed.mat\n', subject_id);
            set(fig, 'WindowState', 'maximized');
            saveas(fig, fullfile(save_dir, [subject_id '_' cname '_resultant_plot.png']));
        end
    end

    function label = remove_subject_from_blkname(blk_title)
        tokens = strsplit(strtrim(blk_title));
        if numel(tokens) > 1
            label = strjoin(tokens(2:end), ' ');
        else
            label = blk_title;
        end
    end
disp(param.Velocity30.range_web);
disp(param.Velocity3_0.range_web);
disp(param.Velocity0_3.range_web);
end
