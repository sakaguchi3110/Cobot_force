function param = build_velocity_param(range_web, range_thumb, Fs)
    velocity_classes = {'Velocity30', 'Velocity3_0', 'Velocity0_3'};
    param = struct();

    for i = 1:length(velocity_classes)
        cname = velocity_classes{i};
        param.(cname).range_web   = range_web.(cname);
        param.(cname).range_thumb = range_thumb.(cname);
        param.(cname).post_sec    = 0.5;

        % Calculate pre_sec separately for web and thumb
        param.(cname).pre_sec_web = max(range_web.(cname)) + 1;
        param.(cname).pre_sec_thumb = max(range_thumb.(cname)) + 1;

        % Convert sec to samples separately for web and thumb
        param.(cname).pre_samples_web  = round(param.(cname).pre_sec_web  * Fs);
        param.(cname).pre_samples_thumb = round(param.(cname).pre_sec_thumb * Fs);
        param.(cname).post_samples = round(param.(cname).post_sec * Fs);
    end
end
