function res = sngproc(splitRes, tasksettings, taskSTIMMap)
%SNGPROC forms a wrapper function to compute those single task statistics.
%   RES = SNGPROC(SPLITRES, TASKSETTING) does basic computation job for
%   most of the tasks when no SCat(have a look at the data to see what SCat
%   is) modification is needed. Locally, RT cutoffs, NaN cleaning and other
%   miscellaneous tasks to prepare data for processing.
%   RES = SNGPROC(SPLITRES, TASKSETTING, TASKSTIMMAP) adds a map container
%   for modification of SCat in RECORD.
%
%   See also sngstatsBART, sngstatsCRT, sngstatsConflict, sngstatsMemrep,
%   sngstatsMemsep, sngstatsMentcompare, sngstatsMentcompute, sngstatsNSN,
%   sngstatsNback, sngstatsSRT, sngstatsSpan

%By Zhang, Liang. 05/03/2016, E-mail:psychelzh@gmail.com

%Initialization jobs.
%Get all the output variable names.
%coupleVars are formatted out variables.
varscat = strsplit(tasksettings.VarsCat{:});
varscond = strsplit(tasksettings.VarsCond{:});
if all(cellfun(@isempty, varscond))
    delimiterVC = '';
else
    delimiterVC = '_';
end
cpvars = strcat(repmat(varscat, 1, length(varscond)), delimiterVC, ...
    repelem(varscond, 1, length(varscat)));
%further required variables.
sngvars = [strsplit(tasksettings.SingletonVars{:}), strsplit(tasksettings.SingletonVarsCP{:})];
spvars = strsplit(tasksettings.SpecialVars{:});
%Out variables names are composed by three part.
outvars = [cpvars, sngvars, spvars];
%Merge conditions. Useful when merging data.
mrgcond = strsplit(tasksettings.MergeCond{:});
if all(cellfun(@isempty, mrgcond))
    delimiterMC = '';
else
    delimiterMC = '_';
end
%Remove empty strings.
outvars(cellfun(@isempty, outvars)) = [];
%Preallocation.
res = table; %Table type is used temporarily. Read the lines in the end of this function.
comres = table; %Short of common results. Results calculated from analysis function, if existed.
spres = table; %Short of special results. Results calculated in current function.
if ~isempty(splitRes{:})
    recRes = splitRes{:};
    recVars = recRes.Properties.VariableNames;
    nvar = length(recVars);
    if length(mrgcond) == 1 && length(mrgcond) < nvar
        mrgcond = repmat(mrgcond, 1, nvar);
    end
    for ivar = 1:nvar
        curRecVar = recVars{ivar};
        if ~isempty(strfind(curRecVar, 'RECORD')) || ~isempty(strfind(curRecVar, 'TEST'))
            RECORD = recRes.(curRecVar){:};
            %Remove NaN (not a number) or empty (char of ASCII 0) trials.
            cellRec = table2cell(RECORD);
            chkStatus = cellfun(@all, cellfun(@(x) isnan(x) | double(x) == 0, cellRec, ...
                'UniformOutput', false));
            rmRows = all(chkStatus, 2); %Remove rows of only nan or 0 char.
            RECORD(rmRows, :) = [];
            %Minor modification to some of the variables in RECORD.
            task = tasksettings.TaskIDName{:};
            switch task
                case {'Symbol', 'Orthograph', 'Tone', 'Pinyin', 'Lexic', 'Semantic', 'Reading', ...%langTasks
                        'GNGLure', 'GNGFruit', 'CPT1', ...%otherTasks in NSN. %NSN
                        }
                    if exist('taskSTIMMap', 'var')
                        RECORD = mapSCat(RECORD, taskSTIMMap, 'STIM');
                    end
                    %Before removing RTs, record the time used if required.
                    if ismember('TotalTime', outvars)
                        spres.TotalTime = sum(RECORD.RT);
                    end
                    if ismember('CountTotalTrl', outvars)
                        spres.CountTotalTrl = height(RECORD);
                    end
                    %Take into consideration of no RT record task 'Reading'.
                    if ismember('RT', RECORD.Properties.VariableNames)
                        %Cutoff RTs: for too fast trials and too slow
                        %trials. Do not remove trials without response,
                        %because some trials of GNG task is designed to
                        %suppress a response for subjects.
                        RECORD((RECORD.RT < 100 & RECORD.RT ~= 0) | RECORD.RT > 2500, :) = [];
                    end
                    %record the number of correct trials if required.
                    if ismember('CountAccTrl', outvars)
                        spres.CountAccTrl = sum(RECORD.ACC);
                    end
                case {'SRT', 'SRTWatch', 'SRTBread'} %SRT
                    %The original record of ACC of each trial is not always right.
                    if ismember('STIM', RECORD.Properties.VariableNames)
                        %transform: 'l'/'1' -> 1 , 'r'/'2' -> 2.
                        RECORD.STIM = (RECORD.STIM ==  'r' | RECORD.STIM ==  '2') + 1;
                        RECORD.ACC = RECORD.STIM == RECORD.Resp;
                    end
                    %Cutoff RTs: for too fast and too slow RTs. After discussion, only trials
                    %that are too fast are removed. Note RT == 0 mostly means no response.
                    RECORD(RECORD.RT < 100 & RECORD.RT ~= 0, :) = [];
                    %Do not remove trials without response, because some trials of stopwatch
                    %and fruit task is designed to suppress a response for subjects.
                case {'DRT', ...%DRT
                        'DivAtten1', 'DivAtten2', ...%DA
                        }
                    %Cutoff RTs: for too fast trials.
                    RECORD(RECORD.RT < 100 & RECORD.RT ~= 0, :) = [];
                    %Find out the no-go stimulus. Note RT of 3000 (for DRT)
                    %or 1000 (for DivAtten) is regarded as no response.
                    criterion = 3000 * strcmp(task, 'DRT') + 1000 * ~strcmp(task, 'DRT');
                    NGSTIM = findNG(RECORD, criterion);
                    %For SCat: Go -> 1, NoGo -> 0.
                    RECORD.SCat = ~ismember(RECORD.STIM, NGSTIM);
                    %Set the ACC to 0 for go trials without response.
                    RECORD.ACC(RECORD.SCat == 1 & RECORD.RT == criterion, :) = 0;
                case {'CRT', 'SpeedAdd', 'SpeedSubtract', 'DigitCmp', 'CountSense'} %CRT
                    %Cutoff RTs: eliminate RTs that are too fast (<100ms).
                    RECORD(RECORD.RT < 100 & RECORD.RT ~= 0, :) = [];
                    %Removed trials without response.
                    RECORD(RECORD.Resp == 0, :) = [];
                case {'SusAtten', 'ForSpan', 'BackSpan', 'SpatialSpan'} %Span
                    %Some of the recording does not include SLen (Stimuli
                    %Length) as one of their variable, get it here.
                    if ~ismember('SLen', RECORD.Properties.VariableNames)
                        RECORD.SLen = cellfun(@length, RECORD.SSeries);
                    end
                    %Some of the recording does not include Next as one
                    %variable, get it here.
                    if ~ismember('Next', RECORD.Properties.VariableNames)
                        RECORD.Next = [diff(RECORD.SLen); 0];
                    end
                case 'CPT2'
                    %Note only 'C' which is followed by 'B' is Go(target) trial
                    GoTrials = strcmp(RECORD.STIM, 'C');
                    %'C' appears at the first trial will not be a target.
                    if ismember(find(GoTrials), 1)
                        GoTrials(1) = false;
                    end
                    isFollowB = strcmp(RECORD.STIM(circshift(GoTrials, -1)) , 'B');
                    %'C' not followed by 'B' should be excluded.
                    GoTrials(~isFollowB) = false;
                    %Add a field 'SCat', 1 -> go, 0 -> nogo.
                    RECORD.SCat = zeros(height(RECORD), 1);
                    RECORD.SCat(GoTrials) = 1;
                    %Cutoff RTs: for too fast trials.
                    RECORD(RECORD.RT < 100 & RECORD.RT ~= 0, :) = [];
                case {'AssocMemory', 'SemanticMemory', ... %Memrep
                        'PicMemory', 'WordMemory', ... %Memsep
                        }
                    %Cutoff RTs: for too fast trials.
                    RECORD(RECORD.RT < 100 & RECORD.RT ~= 0, :) = [];
                    %Remove trials of no response, which denoted by -1 in Resp.
                    RECORD(RECORD.Resp == -1, :) = [];
                case {'Flanker', 'Stroop1', 'Stroop2', 'NumStroop', 'TaskSwitching'} %Conflict
                    if exist('taskSTIMMap', 'var')
                        RECORD = mapSCat(RECORD, taskSTIMMap, 'SCat');
                    end
                    %Cutoff RTs: eliminate trials that are too fast (<100ms)
                    RECORD(RECORD.RT < 100 & RECORD.RT ~= 0, :) = [];
                    %Remove trials of no response.
                    if ~ismember(RECORD.Properties.VariableNames, 'Resp')
                        RECORD.Resp = RECORD.ACC;
                    end
                    switch task
                        case {'Flanker', 'Stroop1', 'Stroop2'}
                            missResp = 0;
                        case 'NumStroop'
                            missResp = 2;
                        case 'TaskSwitching'
                            missResp = -1;
                    end
                    RECORD(RECORD.Resp == missResp, :) = [];
                case {'Nback1', 'Nback2'} %Nback
                    %Remove trials that no response is needed.
                    RECORD(RECORD.CResp == -1, :) = [];
                    %Cutoff RTs: for too fast trials.
                    RECORD(RECORD.RT < 100 & RECORD.RT ~= 0, :) = [];
            end
            %Compute now.
            if ~isempty(RECORD)
                anafunsuff = tasksettings.AnalysisFun{:};
                if ~isempty(anafunsuff)
                    %Note: sngstats means 'single task processing'.
                    anafunstr = ['sngproc', anafunsuff];
                    anafun = str2func(anafunstr);
                    switch nargin(anafunstr)
                        case 1
                            comres = anafun(RECORD);
                        case 4
                            comres = anafun(RECORD, varscat, delimiterVC, varscond);
                    end
                end
                curTaskRes = [comres, spres];
                curTaskRes(:, ~ismember(curTaskRes.Properties.VariableNames, outvars)) = [];
            else
                curTaskRes = array2table(nan(1, length(outvars)), 'VariableNames', outvars);
            end
            %Treat mean RT of any condition is less than 300ms as missing.
            curTaskResVarNames = curTaskRes.Properties.VariableNames;
            MRTvars = curTaskResVarNames(~cellfun(@isempty, ...
                regexp(curTaskResVarNames, '\<M?RT(?!_CongEffect|_SwitchCost)', 'once')));
            for irtvar = 1:length(MRTvars)
                if curTaskRes.(MRTvars{irtvar}) < 300 || curTaskRes.(MRTvars{irtvar}) > 2500
                    curTaskRes{:, :} = nan;
                    break
                end
            end
            curTaskRes.Properties.VariableNames = strcat(curTaskResVarNames, ...
                delimiterMC, mrgcond{ivar});
            res = [res, curTaskRes]; %#ok<*AGROW>
        end
    end
end
%Table is wrapped into a cell. The table type of MATLAB has something
%tricky when nesting table type in a table; it treats the rows of the
%nested table as integrated when using rowfun or concatenating.
res = {res};
end

function RECORD = mapSCat(RECORD, taskSTIMMap, var)
%Modify variable SCat of RECORD and return it.

if ~iscell(RECORD.(var))
    RECORD.(var) = num2cell(RECORD.(var));
end
if all(isKey(taskSTIMMap, RECORD.(var)))
    RECORD.SCat = cell2mat(values(taskSTIMMap, RECORD.(var)));
else %In this case, some of stimuli are not right, and delete all the instances.
    RECORD(:, :) = [];
end
end

function NGSTIM = findNG(RECORD, criterion)
%For some of the tasks, no-go stimuli is not predifined.

%Get all the stimuli.
allSTIM = unique(RECORD.STIM);
%For the newer version of DRT data, when response is required and the
%subject responded with an incorrect key, remove that trial because these
%trials might confuse the determination of nogo stimuli.
if isnum(allSTIM) && ismember('Resp', RECORD.Properties.VariableNames)
    %DRT of newer version detected.
    %Amend the ACC records.
    RECORD.ACC(RECORD.Resp == 0) = 0;
    RECORD(str2double(num2cell(RECORD.STIM)) == RECORD.Resp & RECORD.ACC == 0, :) = [];
end
if ~isempty(allSTIM)
    firstTrial = RECORD(1, :);
    firstIsGo = firstTrial.ACC == 1 && firstTrial.RT < criterion;
    firstTrialInfo = allSTIM == firstTrial.STIM;
    %Here is an interesting way to find out no-go stimulus.
    NGSTIM = allSTIM(xor(firstTrialInfo, firstIsGo));
else
    NGSTIM = [];
end
end
