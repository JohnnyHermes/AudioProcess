function [Sv,Kv]=findmaxesm5(ru,lmax,lmin)
Sv=zeros(1,5); Kv=zeros(1,5);          % ��ʼ��
if isnan(ru),  return; end
[K,V]=findpeaks(ru(lmin:lmax),[],lmin);% ��ru��Pmin��Pmax��Ѱ�ҷ�ֵ
K=K+lmin-1;                            % ������ֵλ��
[V,ind]=sort(V','descend');            % ��ֵ�ķ�ֵ����ֵ��С�ݼ���������
K=K(ind);                              % ��ֵ��Ӧλ�õ�������V���������Ӧ
vindex=find(V>0.2);                    % �޳���ֵ��ֵС��0.2�ĵ�
V=V(vindex); K=K(vindex);
vl=length(V);                          % ��ֵ����
Sv(1:min(vl,5))=V(1:min(vl,5));        % ���ڷ�ֵ�������ֻȡǰ5������Sv��Kv
Kv(1:min(vl,5))=K(1:min(vl,5));

