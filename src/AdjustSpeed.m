function output = AdjustSpeed(ori_data,fs,speed_val)
%%
%函数功能：变速不变调
%输入：
%     ori_data:原始音频数据
%     fs:采样率
%     speed_val:速度倍率
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
%% 计算每帧的预测系数和信号增益
for i=1 : fn
    u=X(:,i);
    [ar,g]=lpc(u,p);  %线性预测法计算p个预测系数
    AR_coeff(:,i)=ar; %预测系数矩阵
    Gain(i)=g;        %增益系数矩阵
end
%% 基音检测
[Dpitch,~,~,SF,~,~,~,~,~]=...
    Ext_F0ztms(tmp_data,fs,wlen,inc,T1,r2,miniL,mnlong,ThrC,0);
%% LSP参数的提取
for i=1 : fn
    a=AR_coeff(:,i);                     % 取来本帧的预测系数
    lsf=ar2lsf(a);                       % 调用ar2lsf函数求出lsf
    Glsf(:,i)=lsf;                       % 把lsf存储在Glsf数组中
end
%% 利用内插法把数据根据缩放倍数进行缩放
fn1=floor(speed_val*fn);                           % 设置新的总帧数fn1
Glsf_new=interp1((1:fn),Glsf',linspace(1,fn,fn1))';% 把LSF系数内插
Dpitch_new=interp1(1:fn,Dpitch,linspace(1,fn,fn1));% 把基音周期内插
G_new=interp1((1:fn),Gain,linspace(1,fn,fn1));     %把增益系数内插
SF_new=interp1((1:fn),SF,linspace(1,fn,fn1));      %把SF系数内插
%% 利用缩放后的数据进行语音合成
for i=1:fn1             % 分别对每帧进行语音合成
    lsf=Glsf_new(:,i);  % 获取本帧的lsf参数
    ai=lsf2ar(lsf);     % 调用lsf2ar函数把lsf转换成预测系数ar 
    sigma=sqrt(G_new(i));

    if SF_new(i)==0     % 若该帧无话
        excitation=randn(wlen,1);  % 产生白噪声来填充该帧
        [synt_frame,zint]=filter(sigma,ai,excitation,zint);
    else                % 若该帧有话
        PT=round(Dpitch_new(i));            % 取该帧的基音周期
        exc_syn1 =zeros(wlen+idx,1);      % 初始化脉冲发生区
        exc_syn1(mod(1:idx+wlen,PT)==0)=1;% 在基音周期的位置产生脉冲，幅值为1
        exc_syn2=exc_syn1(idx+1:idx+inc); % 计算帧移inc区间内的脉冲个数
        index=find(exc_syn2==1);
        excitation=exc_syn1(idx+1:idx+wlen);% 这一帧的激励脉冲源
        
        if isempty(index)                 % 帧移inc区间内没有脉冲
            idx=idx+inc;              % 计算下一帧的前导零点
        else                              % 帧移inc区间内有脉冲
            eal=length(index);            % 计算有几个脉冲
            idx=inc-index(eal);         % 计算下一帧的前导零点
        end
        gain=sigma/sqrt(1/PT);            % 计算脉冲增益
        [synt_frame,zint]=filter(gain,ai,excitation,zint);%用激励脉冲合成语音
    end
    
    if i==1                           % 若为第1帧
        output=synt_frame;            % 不需要重叠相加,保留合成数据
    else
        M=length(output);             % 重叠部分用两个三角窗滤波器进行叠加处理
        output=[output(1:M-overlap); output(M-overlap+1:M).*tempr1+...
            synt_frame(1:overlap).*tempr2; synt_frame(overlap+1:wlen)];
    end
end
%% 合成后处理
output(isnan(output))=0;
output=output/max(abs(output));          % 幅值归一化