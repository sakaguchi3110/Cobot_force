function [segment_data, removed_trigger_times] = plot_segment_class_overlay_in_segment(segment_data, classname, segment_index)
% 表示：指定セグメント中の同じVelocityクラスの全イベント（チャネル1のみ）
% 削除：クリックされたチャネル1に対応するイベント1件（全チャネル分まとめて）

    segments_all = segment_data.(classname);
    removed_trigger_times = [];

    % 該当セグメント内のイベントインデックスを取得
    match_idx = find(cellfun(@(x) x.segment_index == segment_index, segments_all));
    if isempty(match_idx)
        fprintf('No matching events for %s in segment %d\n', classname, segment_index);
        return;
    end

    cmap = lines(length(match_idx));
    handles = gobjects(length(match_idx), 1);
    triggers = gobjects(length(match_idx), 1);
    is_removed = false(1, length(match_idx));
    trigger_on_times = NaN(1, length(match_idx));

    label = segments_all{match_idx(1)}.label;
    figure('Name', sprintf('%s - %s (Click Ch1 to remove)', label, classname));
    hold on;

    yyaxis left;
    ylabel('Ch1 Signal (V)');
    xlabel('Time (s)');

    for i = 1:length(match_idx)
        seg = segments_all{match_idx(i)};
        t = seg.t;

        % ✅ チャネル1のみ表示し、クリック削除の対象とする
        handles(i) = plot(t, seg.channels(1, :), '-', ...
            'Color', cmap(i,:), 'ButtonDownFcn', {@removeTrace, i});

        % ✅ トリガーは右軸で破線表示（削除対象ではない）
        yyaxis right;
        triggers(i) = plot(t, seg.trigger, '--', 'Color', cmap(i,:));
    end

    yyaxis right;
    ylabel('Trigger Signal (V)');
    yyaxis left;
    title([label ' - ' strrep(classname, '_', '.') ' (Click Ch1 waveform to remove)'], 'Interpreter', 'none');
    grid on;

    uiwait(gcf);  % ユーザーがFigureを閉じるまで待つ

    % ✅ 削除処理：対応イベント構造体ごと削除
    for i = length(match_idx):-1:1
        if is_removed(i)
            idx_to_remove = match_idx(i);
            segment_data.(classname)(idx_to_remove) = [];
            removed_trigger_times(end+1) = trigger_on_times(i);
        end
    end

    % --- 入れ子の削除コールバック関数（Ch1の線をクリックで発火） ---
    function removeTrace(~, ~, idx)
        if is_removed(idx)
            return;
        end
        seg = segments_all{match_idx(idx)};
        t = seg.t;
        trig = seg.trigger;

        % トリガーON（5V立ち上がり）の時刻を推定
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
        disp(['Removed event ID ' num2str(match_idx(idx)) ' (segment ' num2str(segment_index) ')']);
    end
end
