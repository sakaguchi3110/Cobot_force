function block_segments = restore_segment(block_segments, block_segments_backup, block_idx)
    % Restore specified segment (block_idx) from backup
    if block_idx <= length(block_segments_backup)
        block_segments{block_idx} = block_segments_backup{block_idx};
        fprintf('✅ Segment %d restored from backup.\n', block_idx);
    else
        warning('⚠️ Index %d is out of bounds for backup data.', block_idx);
    end
end