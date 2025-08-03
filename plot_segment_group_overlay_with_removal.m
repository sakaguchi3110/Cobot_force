function [segment_data, removed_trigger_times] = plot_segment_group_overlay_with_removal(segment_data, label, classname)
% 同じセグメント（コメントラベル）かつ同じVelocityクラスのすべての波形を一括表示・削除
% 入力：
%   segment_data - 全イベントデータ構造
%   label        - コメントラベル（セグメント名）
%   classname    - クラス名（例: 'Velocity30'）
% 出力：
%   segment_data           - 削除後の構造体
%   removed_trigger_times  - 削除された波形のトリガーON時刻（相対時刻）

    segments_all = segment_data.(classname);
    removed_trigger_times = [];

    % 対象セグメントだけ抽出
    match_idx = find(cellfun(@(x) strcmp(x.label, label), segments_all));

    if isempty(match_idx)
        fprintf('No data found for label "%s" in class "%s"\n', label, classname);
        return;
    end

    cmap = lines(length(match_idx));
    handles = gobjects(length(match_idx), 1);
    triggers = gobjects(length(match_idx), 1);
    is_removed = false(1, length(match_idx));
    trigger_on_times = NaN(1, length(match_idx));

    figure('Name', sprintf('%s - %s (Click waveform to remove)', label, classname));
    hold on;

    yyaxis left;
    ylabel('Ch1 Signal (V)');
    xlabel('Time (s)');

    for i = 1:length(match_idx)
        seg = segments_all{match_idx(i)};
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
    title([label ' - ' strrep(classname, '_', '.') ' (Click waveform to remove)'], 'Interpreter', 'none');
    grid on;

    uiwait(gcf);

    % 削除処理
    for i = length(match_idx):-1:1
        if is_removed(i)
            idx_to_remove = match_idx(i);
            segment_data.(classname)(idx_to_remove) = [];
            removed_trigger_times(end+1) = trigger_on_times(i);
        end
    end

    % --- コールバック関数（入れ子）---
    function removeTrace(~, ~, idx)
        if is_removed(idx)
            return;
        end
        seg = segments_all{match_idx(idx)};
        t = seg.t;
        trig = seg.trigger;

        % トリガーONの立ち上がり検出
        cross_idx = find(trig(1:end-1) <= 5 & trig(2:end) > 5, 1, 'first');
        if ~isempty(cross_idx)
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
        disp(['Removed waveform ID ' num2str(match_idx(idx)) ' (' label ')']);
    end
end
