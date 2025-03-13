function complex_envelope = iq_downmixer(signal, osr, br, fc, fs)

% TODO: You may want to implement a better downsampling filter.
% TIP: Look up 'CIC' filters as inspiration for an efficient hardware 
% implementation. Also think about how you will generate the LO signal in
% hardware, looking up 'CORDIC' will set you in a correct direction.

%% IQ downmixer
t = ((1 : numel(signal))' - 1) / fs;
upsampled_envelope = 2 * exp(-1j * 2 * pi * fc * t) .* signal;
%% Low Pass Filter
% first simple downsampling filter
    % filt = ones(16 * round(fs / (br * osr)) + 1);
    % upsampled_envelope = conv(upsampled_envelope, filt / sum(filt), 'same');

% second filter design plan
    %CIC filter
    D = fs / (br * osr);
    M = 3; % Differential Delay
    N = 5; % Numsections
    CICFilter = dsp.CICDecimator(D,M,N);

    % fvtool(CICFilter, 'Fs', fs);

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
    H_cic_norm = H_cic / CIC_Gain;

    
    filtered_signal = CICFilter(upsampled_envelope);
    complex_envelope = filtered_signal / CIC_Gain;
    % complex_envelope = filter(Compensate_Filter, 1, complex_envelope);

    
    
    % 绘制 CIC 通带增益衰减

    % figure;
    % plot(f, 20*log10(abs(H_cic)), 'b', 'LineWidth', 1.5);
    % xlabel('Frequency (Hz)');
    % ylabel('Gain (dB)');
    % title('CIC Filter Passband Gain (0-50 Hz)');
    % grid on;





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