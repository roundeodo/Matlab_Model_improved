fs = 100e3;                       % 采样率 100 kHz
fc_true = 20.1e3;                 % 实际频率 20.1 kHz
t = (0:1/fs:0.05-1/fs)';          % 50 ms 共 5000 点

% ✅ 用复数信号（唯一频率成分）
signal = exp(1j * 2 * pi * fc_true * t);

% ✅ 扫描频率列表
fc_list = 19.5e3 : 0.1e3 : 20.5e3;
energy = zeros(size(fc_list));

% ✅ 下变频 + 能量积累
for i = 1:length(fc_list)
    fc_test = fc_list(i);
    lo = exp(-1j * 2 * pi * fc_test * t);  % 本地复数载波
    baseband = signal .* lo;
    energy(i) = abs(sum(baseband));    % 能量计算
end

% ✅ 画图查看结果
plot(fc_list/1e3, energy, '-o');
xlabel('Test Frequency (kHz)');
ylabel('Energy');
title('Frequency Scan');
grid on;

% ✅ 输出估计频率
[~, idx_max] = max(energy);
fc_est = fc_list(idx_max);
fprintf('Estimated frequency = %.3f kHz\n', fc_est/1e3);
