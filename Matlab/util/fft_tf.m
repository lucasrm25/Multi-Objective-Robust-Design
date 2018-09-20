function [Hexp, freq_hz] = fft_tf( input_Sinus, output_Sinus, freq_range, dt )
    U = fft(input_Sinus);
    Y = fft(output_Sinus);

    N = numel(input_Sinus);

    freq_min = max(1/(N*dt), freq_range(1));  %Hz
%     freq_max = min(1/dt, freq_range(2));        %Hz - FFT maximal frequency
    freq_max = min(1/dt/2, freq_range(2));        %Hz - Nyquist cut-off frequency

    N1 = floor(freq_min*N*dt);        % N1 = freq_min, N = 1/dt
    N2 = floor(freq_max*N*dt);

    U = U(N1:N2);
    Y = Y(N1:N2);    
    Hexp = U .* Y ./ U.^2; % the H1 transfer function estimate

    freq_hz = (1:N)/(N*dt);
    freq_hz = freq_hz(N1:N2);
end

