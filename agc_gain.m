function out = agc_gain(in)

% TODO: Implement this yourself!
% TIP: What can the output bits tell you about the signal amplitude
% beforing decoding?
max_in = max(abs(in));
out = double(in)./double(max(abs(in)));

end

