function y = cic_decimator_match_dsp(x, D, M, N)
    % 1) N 级积分
    v = x;
    for k = 1:N
        v = filter(1, [1 -1], v);
    end

    % 2) 降采样
    w = v(1:D:end);

    % 3) N 级梳状（每级都先缓冲 M 个零，再做 filter，然后丢掉最前面 M 个输出）
    for k = 1:N
        b = zeros(1, M+1); b(1)=1; b(end)=-1;
        % 在 w 前面加 M 个零
        w_padded = [zeros(1, M), w(:)'];  
        % 滤波
        y_padded = filter(b, 1, w_padded);
        % 丢掉最前面 M 个，剩余才是真正的输出
        w = y_padded((M+1):end)';
    end

    y = w;
end
