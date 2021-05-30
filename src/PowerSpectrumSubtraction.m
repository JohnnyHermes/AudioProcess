function output = PowerSpectrumSubtraction(ori_data,fs)
%%
%函数功能：用功率谱减法对信号进行降噪
%输入：
%     ori_data:原始音频数据
%     fs:采样率
%输出：
%     output:处理后数据

%% 基本参数设置
wlen=240;                                 % 窗长
window=hamming(wlen);                     % 设置窗函数
inc=80;                                   % 帧长
pre_time = 0.25;                          % 录音前段空白噪音的时长
noise_fs = fix((pre_time*fs-wlen)/inc+1);  % 噪音帧总数
a= 4;                                     % 过减因子
b=0.001;                                  % 功率补偿因子
%% 原始数据预处理
ori_data=ori_data-mean(ori_data);         % 去除直流分量
tmp_data=ori_data/max(abs(ori_data));     % 归一化
X=enframe(tmp_data,window,inc)';          % 对数据分帧
N=length(tmp_data);                       % 语音数据长度
fn=size(X,2);                             % 帧数
%% 功率谱减法实现
x_fft = fft(X);                           % 进行傅里叶变换
n_pos=wlen/2+1;                           % 求出正频率的区间
X_a = abs(x_fft);                         % 求幅值
X_phase=angle(x_fft);                     % 求相位
X_a2=X_a.^2;                              % 求能量
Nt=mean(X_a2(:,1:noise_fs),2);            % 求算噪声段平均能量

for i = 1:fn                             % 谱减
    for k= 1:n_pos
        if X_a2(k,i)>a*Nt(k)
            temp(k) = X_a2(k,i) - a*Nt(k);
        else
            temp(k)=  b*X_a2(k,i);
        end
        A(k)=sqrt(temp(k));             % 把能量开方得幅值
    end
    X_new(:,i)=A;
end
output=OverlapAdd2(X_new,X_phase(1:n_pos,:),wlen,inc);   % 合成谱减后的语音
%% 合成后处理
if length(output)>N
    output=output(1:N);
elseif length(output)<N
    output=[output; zeros(N-length(output),1)];
end
output=output/max(abs(output));         % 归一化