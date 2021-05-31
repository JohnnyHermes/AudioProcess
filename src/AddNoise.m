function output = AddNoise(ori_data,snr)
%%
%函数功能：叠加一个信噪比为snr的高斯白噪声到信号中
%输入：
%     ori_data:原始音频数据
%     fs:采样率
%输出：
%     output:处理后数据
%% 主程序
noise=randn(size(ori_data));       % 用randn函数产生高斯白噪声
Nx=length(ori_data);               % 求音频长度
ori_data_power = 1/Nx*sum(ori_data.*ori_data);     % 求信号的平均能量
noise_power=1/Nx*sum(noise.*noise);% 求噪声的能量
noise_variance = ori_data_power / ( 10^(snr/10) );    % 求噪声方差值
noise=sqrt(noise_variance/noise_power)*noise;       % 按噪声的平均能量构成相应的白噪声
output=ori_data+noise;                         % 叠加噪声