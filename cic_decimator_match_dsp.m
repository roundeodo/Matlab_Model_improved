function y = cic_decimator_match_dsp(x, D, M, N)
% 手写版 CIC 降采样，完全等价 dsp.CICDecimator（含首样本输出 0）
%
%  x —  输入信号向量
%  D —  降采样因子
%  M —  梳状滤波差分延迟
%  N —  级数

    %—— 1. N 级积分 ——%
    v = x;
    for stage = 1:N
        v = filter(1, [1 -1], v);
    end

    %—— 2. 降采样 ——%
    w = v(1:D:end);

    %—— 3. N 级梳状 ——%
    % 每级都用 filter + 初始状态 zi，使得首个输出为 0
    y = w;
    for stage = 1:N
        b  = [1, zeros(1,M-1), -1];
        zi = -y(1) * ones(M,1);        % 设定初始状态
        y  = filter(b, 1, y, zi);      % 带初态的滤波
    end
end
