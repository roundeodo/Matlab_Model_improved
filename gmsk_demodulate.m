function raw = gmsk_demodulate(complex_envelope, osr)

% TODO: This is a very simple demodulator to get you started. There are
% lots of things that can be improved!
% TIP: Search for demodulation methods online. Are you going for the
% coherent or incoherent approach?
% 设定参数
bt = 0.5;  % GMSK 的 BT 参数

% 生成发送端的高斯滤波器
% h_tx = gaussian_filter(bt, osr);

% 设计匹配滤波器（时间反转版本）
% h_matched = fliplr(h_tx);  % 反转时间轴
% 
% complex_envelope = conv(complex_envelope, h_matched, 'same');
fc = 1 / (2 * osr);  % 截止频率 = Rb/2 归一化

B = fir1(50, fc * 2);  % 低通滤波器
complex_envelope = complex_envelope / max(abs(complex_envelope));
complex_envelope = filter(B,1,complex_envelope);  
%IQ_synced = costas_loop(complex_envelope,0.01);
I = real(complex_envelope);
Q = imag(complex_envelope);

% fvtool(B, 'Fs', 1600);
% **(3) 滤波平滑 IQ 信号**
I_filtered = filter(B, 1, I);
Q_filtered = filter(B, 1, Q);

% **(4) 计算瞬时相位**
phase_origin = atan2(Q, I);
phase_origin_transformed = phase_origin.';

phase = unwrap(atan2(Q, I));
% phase = filter(B,1,phase);


% 假设 phase 是你已有的向量（单位为弧度），是 1×N 或 N×1
phase_transformed = phase(:);  % 转换为列向量，方便处理

% 假设你已有 phase 数组，是 1xN 或 Nx1 的向量
% 这里举例模拟
% phase = rand(1, 100) * 60000 - 30000;  % 测试数据范围 [-30000, 30000]

% 1. 转为 Q16格式（1符号+15整数+16小数），即乘以 2^16 并四舍五入
phase_fixed = round(phase_transformed * 2^16);

% 2. 限定在 int32 可表示范围（-2^31 ~ 2^31-1），也确保不溢出
phase_fixed = max(min(phase_fixed, 2^31 - 1), -2^31);

% 3. 转为补码二进制字符串（32位）
phase_bin = dec2bin(typecast(int32(phase_fixed), 'uint32'), 32);

% 4. 写入文本文件，每行一个二进制数
% fid = fopen('phase_q15int_16frac.txt', 'wt');
% for i = 1:size(phase_bin, 1)
%     fprintf(fid, '%s\n', phase_bin(i, :));
% end
% fclose(fid);








phase_differential = diff(phase);
phase_differential = phase_differential.';
% calculate derivative
raw = diff(phase) * osr / (0.5 * pi);
raw = max(min(raw,1),-1);
raw = raw.';
end