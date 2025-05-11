function complex_envelope = iq_downmixer(signal, osr, br, fc, fs)

% TODO: You may want to implement a better downsampling filter.
% TIP: Look up 'CIC' filters as inspiration for an efficient hardware 
% implementation. Also think about how you will generate the LO signal in
% hardware, looking up 'CORDIC' will set you in a correct direction.

%% IQ downmixer
    %CIC filter
    D = fs / (br * osr);
    M = 1; % Differential Delay
    N = 5; % Numsections
    CICFilter = dsp.CICDecimator(D,M,N);


    
t = ((1 : numel(signal))' - 1) / fs;

% fc_list = 19.5e3 : 0.1e3 : 20.5e3;
% energy = zeros(size(fc_list));
% for i = 1:length(fc_list)
%     t_track = ((1 : numel(signal(1 + 2400*(i-1) :2400*i )))' - 1) / fs;
%     fc_test=fc_list(i);
%     carrier = exp(-1j * 2 * pi * fc_test * t_track);
%     baseband = signal(1 + 2400*(i-1) :2400*i ) .* carrier;
%     % filtered_signal_for_tracking = CICFilter(baseband);
%     filtered_signal_for_tracking = imag(baseband);
%     energy(i) = (sum(filtered_signal_for_tracking));
% end
% plot(fc_list/1e3, energy, '-o');
% xlabel('fc test (kHz)');
% ylabel('energy');
% grid on;
% [~,idx_max] = max(energy);
% fc_est = fc_list(idx_max);

% fc_list = 19.5e3 : 0.1e3 : 20.5e3;
% energy = zeros(size(fc_list));
% for i = 1:length(fc_list)
%     t_track = ((1 : numel(signal(1 : 400)))' - 1) / fs;
%     fc_test=fc_list(i);
%     carrier = exp(-1j * 2 * pi * fc_test * t_track);
%     baseband = signal(1:2600) .* carrier;
%     energy(i) = (sum(baseband));
% end
% plot(fc_list/1e3, energy, '-o');
% xlabel('fc test (kHz)');
% ylabel('energy');
% grid on;
% [~,idx_max] = max(energy);
% fc_est = fc_list(idx_max);


upsampled_envelope = 2 * exp(-1j * 2 * pi * fc * t) .* signal;
%% Low Pass Filter
% first simple downsampling filter
    % filt = ones(16 * round(fs / (br * osr)) + 1);
    % upsampled_envelope = conv(upsampled_envelope, filt / sum(filt), 'same');

% second filter design plan
    %CIC filter
    D = fs / (br * osr);
    M = 1; % Differential Delay
    N = 5; % Numsections
    CICFilter = dsp.CICDecimator(D,M,N);

    %fvtool(CICFilter, 'Fs', fs);

    % 计算输入信号的当前长度
    num_samples = length(upsampled_envelope);

    % 计算需要填充的 0 的数量
    pad_length = ceil(num_samples / D) * D - num_samples;
    
    last_value = upsampled_envelope(end);
    padding = repmat(last_value, pad_length, 1);
    % 在信号末尾填充 0
    upsampled_envelope = [upsampled_envelope; padding];



    fd = fs / D; 

    % CIC frequency response 
    f = linspace(0, fd/2, 1600);
    H_cic = (sin(pi * f * D * M / fs) ./ sin(pi * f * M / fs)).^N;
    H_cic (H_cic == 0) = 1e-6;
    CIC_Gain = (D * M) ^ N;
    H_cic_norm = H_cic / 1024;


    % % 1. 提取实部和虚部
    % real_part = real(upsampled_envelope);
    % imag_part = imag(upsampled_envelope);
    % 
    % % 2. 映射为 Q1.14 格式，即乘以 2^14（=16384），再转为 int16
    % real_fixed = round(real_part * 2^14);  % 乘以 16384
    % imag_fixed = round(imag_part * 2^14);
    % 
    % % 3. 限制范围 [-32768, 32767]（int16 极限值）
    % real_fixed = max(min(real_fixed, 32767), -32768);
    % imag_fixed = max(min(imag_fixed, 32767), -32768);
    % 
    % % 4. 转为 16位补码二进制字符串
    % real_bin = dec2bin(typecast(int16(real_fixed), 'uint16'), 16); % 保留完整16位补码
    % imag_bin = dec2bin(typecast(int16(imag_fixed), 'uint16'), 16);
    % 
    % % 5. 保存为文本文件，每行一条
    % fid1 = fopen('real_part_q1_14.txt', 'wt');
    % for i = 1:size(real_bin, 1)
    %     fprintf(fid1, '%s\n', real_bin(i, :));
    % end
    % fclose(fid1);
    % 
    % fid2 = fopen('imag_part_q1_14.txt', 'wt');
    % for i = 1:size(imag_bin, 1)
    %     fprintf(fid2, '%s\n', imag_bin(i, :));
    % end
    % fclose(fid2);

    y = cic_decimator_match_dsp(upsampled_envelope, D, M, N);
    y_real = real(y);
    y_imag = imag(y);
    filtered_signal = CICFilter(upsampled_envelope);
    % filtered_signal = [filtered_signal(2:end);filtered_signal(end)];
    real_unormalized = real(filtered_signal);
    image_unormalized = imag(filtered_signal);
    filtered_signal = filtered_signal / CIC_Gain;
    complex_envelope = filtered_signal;
    real_part_1 = real(complex_envelope);
    imag_part_1 = imag(complex_envelope);
    % complex_envelope = filter(Compensate_Filter, 1, complex_envelope);

    
    
    % 绘制 CIC 通带增益衰减

    % figure;
    % plot(f, 20*log10(abs(H_cic)), 'b', 'LineWidth', 1.5);
    % xlabel('Frequency (Hz)');
    % ylabel('Gain (dB)');
    % title('CIC Filter Passband Gain (0-50 Hz)');
    % grid on;

    length_signal = length(complex_envelope);
    X = fft(complex_envelope);
    X_magnitiude = abs(X)/length_signal;
    X_magnitiude = X_magnitiude(1:length_signal/2);
    f = (0:length_signal/2 - 1) * (fs/length_signal);

    figure;
    plot(f,X_magnitiude);
    xlabel('frequency(Hz)');
    ylabel('magnitude');
    title('CIC filtered signal frequency spectrum');
    grid on;



%% Down sampling
% calculate number of output samples
% n1 = numel(upsampled_envelope);
% n2 = round((n1 - 1) * (br * osr) / fs) + 1;

% resample the complex envelope to the new sample rate
% t1 = ((1 : n1)' - 1) / fs;
% t2 = ((1 : n2)' - 1) / (br * osr);

% complex_envelope = interp1(t1, upsampled_envelope, t2);
% D = fs/(br*osr);
% complex_envelope = upsampled_envelope(1:D:end);


end