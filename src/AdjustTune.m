function output = AdjustTune(ori_data,fs,Tune_val)
%%
%函数功能：变速不变调
%输入：
%     ori_data:原始音频数据
%     fs:采样率
%     Tune_val:音调升、降单音数，+12为升高十二个单音，即一个八度，对应频率×2
%输出：
%     output:处理后数据

%% 基本参数设置
wlen=240;                                 % 窗长
inc=80;                                   % 帧长
overlap=wlen-inc;                         % 重叠长度
tempr1=(0:overlap-1)'/overlap;            % 斜三角窗函数w1
tempr2=(overlap-1:-1:0)'/overlap;         % 斜三角窗函数w2
T1=0.1; r2=0.5;                           % 端点检测参数
miniL=10;                                 % 有话段最短帧数
mnlong=5;                                 % 元音主体最短帧数
ThrC=[10 15];                             % 阈值
p=12;                                     % LPC阶次
idx=0;                                  % 初始化index
zint=zeros(p,1);                          % z变换系数
%% 原始数据预处理
ori_data=ori_data-mean(ori_data);         % 去除直流分量
tmp_data=ori_data/max(abs(ori_data));     % 归一化
X=enframe(tmp_data,wlen,inc)';            % 对数据进行分帧处理
N=length(tmp_data);                       % 语音数据长度
fn=size(X,2);                             % 帧数
rate = 2^(Tune_val/12);                   % 根据十二平均律计算相应的频率倍数
%% 计算每帧的预测系数和信号增益
for i=1 : fn
    u=X(:,i);
    [ar,g]=lpc(u,p);  %线性预测法计算p个预测系数
    AR_coeff(:,i)=ar; %预测系数矩阵
    Gain(i)=g;        %增益系数矩阵
end
%% 基音检测
[Dpitch,Dfreq,~,SF,~,~,~,~,~]=...
    Ext_F0ztms(tmp_data,fs,wlen,inc,T1,r2,miniL,mnlong,ThrC,0);
%% 计算变调后的频率根值旋转量
if rate>1, sign=-1; else sign=1; end      % 根据升调还是降调确定顺逆时针
lmin=floor(fs/450);                       % 基音周期的最小值
lmax=floor(fs/60);                        % 基音周期的最大值
deltaOMG = sign*100*2*pi/fs;              % 根值顺时针或逆时针旋转量dθ
Dpitch_new=Dpitch/rate;                      % 增减后的基音周期
Dfreq_new=Dfreq*rate;                        % 增减后的基音频率
%% 利用调整后的数据进行语音合成
for i=1 : fn
    a=AR_coeff(:,i);                      % 取得本帧的AR系数
    sigma=sqrt(Gain(i));                  % 取得本帧的增益系数

    if SF(i)==0                           % 无话帧
        excitation=randn(wlen,1);         % 产生白噪声
        [synt_frame,zint]=filter(sigma,a,excitation,zint);
    else                                  % 有话帧
        PT=floor(Dpitch_new(i));             % 把周期值变为整数
        if PT<lmin, PT=lmin; end          % 判断修改后的周期值有否超限
        if PT>lmax, PT=lmax; end
        ft=roots(a);                      % 对预测系数求根
        ft1=ft;
%增加共振峰频率，实轴上方的根顺时针转，下方的根逆时针转，求出新的根值
        for k=1 : p
            if imag(ft(k))>0
                ft1(k) = ft(k)*exp(1i*deltaOMG);
            elseif imag(ft(k))<0 
                ft1(k) = ft(k)*exp(-1i*deltaOMG);
	        end
        end
        ai=poly(ft1);                     % 由新的根值重新组成预测系数

        exc_syn1 =zeros(wlen+idx,1);      % 初始化脉冲发生区
        exc_syn1(mod(1:idx+wlen,PT)==0)=1;% 在基音周期的位置产生脉冲，幅值为1
        exc_syn2=exc_syn1(idx+1:idx+inc); % 计算帧移inc区间内的脉冲个数
        index=find(exc_syn2==1);
        excitation=exc_syn1(idx+1:idx+wlen);% 这一帧的激励脉冲源
        
        if isempty(index)                 % 帧移inc区间内没有脉冲
            idx=idx+inc;                  % 计算下一帧的前导零点
        else                              % 帧移inc区间内有脉冲
            eal=length(index);            % 计算脉冲个数
            idx=inc-index(eal);           % 计算下一帧的前导零点
        end
        gain=sigma/sqrt(1/PT);            % 增益
        [synt_frame,zint]=filter(gain,ai,excitation,zint);%用激励脉冲合成语音
    end
    
    if i==1                               % 若为第1帧
        output=synt_frame;                % 不需要重叠相加,保留合成数据
    else
        M=length(output);         % 重叠部分用两个三角窗滤波器进行叠加处理
        output=[output(1:M-overlap); output(M-overlap+1:M).*tempr1+...
            synt_frame(1:overlap).*tempr2; synt_frame(overlap+1:wlen)];
    end
end
%% 调整合成音频长度，使其与原始音频等长
output(isnan(output))=0;
ol=length(output);
if ol<N
    output=[output; zeros(N-ol,1)];
else
    output=output(1:N);
end
output=output/max(abs(output));           % 幅值归一化