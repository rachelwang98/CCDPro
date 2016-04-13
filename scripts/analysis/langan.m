function res = langan(Taskname, splitRes)
%SRT Does some basic data transformation to simple reactiontime tasks.
%
%   Basically, the supported tasks are as follows (TASK ID: 1-6):
%     �����ж� 
%     �����ж�
%     �����ж�
%     ƴ���ж�
%     �����ж�
%     �����ж�(�߼�)
%   The output table contains 8 variables, called Count_hit, Count_FA,
%   Count_miss, Count_CR, RT_hit, RT_FA, RT_miss, RT_CR

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

RECORD = splitRes{:}.RECORD{:};
%Modify SCat.
switch Taskname{:}
    case '�����ж�'
        RECORD.SCat = strcmp(RECORD.STIM, '��');
    case '�����ж�'
        RECORD.SCat = str2double(RECORD.STIM) <= 25;
    % The following four tasks are based on the same format. We use CResp*
    % to denote the right answers for each task: 1 for the positively
    % expected trials, 0 for the negatively.
    case '�����ж�'
        CRespTONE = cell2table(...
            {'��',1;'��',1;'��',1;'��',1;'��',1;'��',1;'��',1;'��',1;'��',1;...
            '��',1;'��',1;'��',1;'ȥ',1;'��',1;'Ū',1;'��',1;'��',1;'��',1;'��',1;...
            'У',1;'��',1;'��',1;'��',1;'��',1;'��',1;'��',0;'��',0;'��',0;'��',0;...
            '��',0;'��',0;'��',0;'��',0;'��',0;'��',0;'��',0;'��',0;'ϰ',0;'��',0;...
            '��',0;'��',0;'ƽ',0;'��',0;'��',0;'��',0;'��',0;'��',0;'��',0;'Ʒ',0;'��',0;}, ...
            'VariableNames', {'STIM', 'SCat'});
        [~, locSTIM] = ismember(RECORD.STIM, CRespTONE.STIM);
        RECORD.SCat = CRespTONE.SCat(locSTIM);
    case 'ƴ���ж�'
        CRespPINYIN = cell2table(...
            {'��uh',0;'m��in',0;'b��g',0;'l��',1;'r��n��',1;'dlu��',0;'x��n��',1;...
            'c��n��',1;'hu��',1;'hs��',0;'��u��n��',1;'w��in',0;'y��',1;'b��g',0;'h��u',1;...
            'u��n',0;'bi��',0;'x��n��',1;'zh��n',1;'j��in',0;'ti��n',1;'qi��',1;'li��m',0;...
            'm��io',0;'ji��n',1;'si��n',0;'m��o',1;'fi��n',0;'ni��g',0;'j��nq',0;'w��i',1;...
            'x��ng',0;'ti��n',1;'n��l',0;'xii��',0;'w��',1;'sh��n��',1;'p��i',1;'bo��',0;...
            'd��u',1;'d��n',0;'po��',0;'i��n',0;'ch��',1;'bi��n',1;'l��m',0;'zh����',0;...
            'y��',1;'xu��',1;'sh��o',1}, ...
            'VariableNames', {'STIM', 'SCat'});
        [~, locSTIM] = ismember(RECORD.STIM, CRespPINYIN.STIM);
        RECORD.SCat = CRespPINYIN.SCat(locSTIM);
    case '�����ж�'
        CRespLEXICO = cell2table(...
            {'�ݵ�',1;'����',1;'��԰',1;'��Щ',1;'�߹�',1;'�ܲ�',1;'����',1;...
            'Զ��',1;'����',1;'��ɫ',1;'����',1;'��ҵ',1;'��Ұ',1;'����',1;'����',1;...
            'Ư��',1;'ͬѧ',1;'����',1;'����',1;'����',1;'�ش�',1;'����',1;'��ɫ',1;...
            '����',1;'����',1;'�λ�',0;'����',0;'ƽ��',0;'����',0;'����',0;'վʿ',0;...
            '����',0;'ʯ��',0;'ֹͤ',0;'����',0;'����',0;'�Ϲ�',0;'����',0;'����',0;...
            '����',0;'����',0;'�޲�',0;'����',0;'����',0;'����',0;'����',0;'����',0;...
            '����',0;'����',0;'����',0;}, ...
            'VariableNames', {'STIM', 'SCat'});
        [~, locSTIM] = ismember(RECORD.STIM, CRespLEXICO.STIM);
        RECORD.SCat = CRespLEXICO.SCat(locSTIM);
    case '�����жϣ��߼��棩'
        CRespSEMANTIC = cell2table(...
            {'����',1;'����',1;'����',1;'ˮţ',1;'����',1;'ɽ��',1;'�ڹ�',1;...
            '��è',1;'��ţ',1;'����',1;'ҰѼ',1;'�ϻ�',1;'����',1;'����',1;'����',1;...
            'ʨ��',1;'�ڹ�',1;'��ѻ',1;'���',1;'����',1;'��ȸ',1;'����',1;'��Ÿ',1;...
            '֩��',1;'�ڻ�',1;'����',0;'����',0;'����',0;'����',0;'�ɻ�',0;'��ɽ',0;...
            '����',0;'�輸',0;'����',0;'����',0;'����',0;'��',0;'Ƥ��',0;'�̳�',0;...
            '����',0;'�ܲ�',0;'����',0;'����',0;'ľ��',0;'ë��',0;'�ؿ�',0;'��ɡ',0;...
            'ɳ��',0;'β��',0;'ѩ��',0;}, ...
            'VariableNames', {'STIM', 'SCat'});
        [~, locSTIM] = ismember(RECORD.STIM, CRespSEMANTIC.STIM);
        RECORD.SCat = CRespSEMANTIC.SCat(locSTIM);
end

%Cutoff RTs: for too fast trials.
RECORD(RECORD.RT < 100, :) = [];

%Occurences of hit and false alarm.
Count_hit = sum(RECORD.ACC(RECORD.SCat == 1));
Count_FA = sum(~RECORD.ACC(RECORD.SCat == 0));
Count_miss = sum(~RECORD.ACC(RECORD.SCat == 1));
Count_CR = sum(RECORD.ACC(RECORD.SCat == 0));
%Mean RT computation.
RT_hit = mean(RECORD.RT(RECORD.SCat == 1 & RECORD.ACC == 1));
RT_FA = mean(RECORD.RT(RECORD.SCat == 0 & RECORD.ACC == 0));
RT_miss = mean(RECORD.RT(RECORD.SCat == 1 & RECORD.ACC == 0));
RT_CR = mean(RECORD.RT(RECORD.SCat == 0 & RECORD.ACC == 1));

res = table(Count_hit, Count_FA, Count_miss, Count_CR, ...
    RT_hit, RT_FA, RT_miss, RT_CR);
