%% Scatter plots showing mean IC weights of rats
area = {'RFA' 'S1'};
stimtype = {'Solenoid' 'ICMS' 'Solenoid + ICMS'};
name = {'MM-T2' 'MM-U2' 'MM-W1' 'MM-S1' 'MM-T1' 'MM-U1' 'MM-V1'};
lv = [6.5 8.8 1.4 3.1 11.2 1.7 4.8];
var = {'Rat' 'LV' 'Area' 'sol_ic1' 'icms_ic1' 'solicms_ic1' 'sol_ic2' 'icms_ic2' 'solicms_ic2'};
na = repmat(name,1,2)';
lv = repmat(lv,1,2)';
ar = repelem(area,[7 7])';
add = zeros(14,1);
scatS = table(na,lv,ar,add,add,add,add,add,add);
scatS.Properties.VariableNames = var;
scatS(:,1) = na;
scatS(:,3) = ar;
scatS.Area = string(scatS.Area);
scatS.Rat = string(scatS.Rat);
for i = 1:2
    for ii = 1:3
        for iii = 1:7
        idx = S{ii}.Area == area{i} & S{ii}.AnimalID == name{iii};
        st = z{ii}(idx,2:3);
        ic1 = ii + 3;
        ic2 = ii + 6;
        idx2 = find(scatS.Area == area{i} & scatS.Rat == name{iii});
        scatS(idx2,ic1) = {mean(st(:,1))};
        scatS(idx2,ic2) = {mean(st(:,2))};
        end
    end
end
figure; hold on
RFA = scatS(1:7,:);
scatter(RFA,'sol_ic1','sol_ic2','filled','ColorVariable','LV')
scatter(RFA,'solicms_ic1','solicms_ic2','filled','ColorVariable','LV')
title('Per Rat Basis RFA')
figure; hold on
S1 = scatS(8:14,:);
scatter(S1,'sol_ic1','sol_ic2','filled','ColorVariable','LV')
scatter(S1,'solicms_ic1','solicms_ic2','filled','ColorVariable','LV')
title('Per Rat Basis S1')
%% Collapsed by stim type
scatD = scatS;
h = [scatD.sol_ic1,scatD.solicms_ic1];
scatD.icms_ic1 = mean(h,2);
h = [scatD.sol_ic2,scatD.solicms_ic2];
scatD.icms_ic2 = mean(h,2);RFA = scatS(1:7,:);
figure; hold on
RFA = scatD(1:7,:);
scatter(RFA,'icms_ic1','icms_ic2','filled','ColorVariable','LV')
title('Per Rat Basis RFA')
figure; hold on
S1 = scatD(8:14,:);
scatter(S1,'icms_ic1','icms_ic2','filled','ColorVariable','LV')
title('Per Rat Basis S1')
%% 
figure; hold on
RFA = scatS(1:7,:);
RFA = [RFA;RFA];
RFA.combined = [RFA.sol_ic1(1:7);RFA.solicms_ic1(8:14)];
S1 = scatS(8:14,:);
S1 = [S1;S1];
S1.combined = [S1.sol_ic1(1:7);S1.solicms_ic1(8:14)];
scatter(RFA,'combined','LV')
scatter(S1,'combined','LV')
rP = polyfit(RFA.combined,RFA.LV,1);
rYfit = polyval(rP,RFA.combined);
plot(RFA.combined,rYfit,'b-');
sP = polyfit(S1.combined,S1.LV,1);
sYfit = polyval(sP,S1.combined);
plot(S1.combined,sYfit,'y-');
title('Per Rat Basis Both Areas Component 2')
figure; hold on
RFA = scatS(1:7,:);
RFA = [RFA;RFA];
RFA.combined = [RFA.sol_ic2(1:7);RFA.solicms_ic2(8:14)];
S1 = scatS(8:14,:);
S1 = [S1;S1];
S1.combined = [S1.sol_ic2(1:7);S1.solicms_ic2(8:14)];
scatter(RFA,'combined','LV')
scatter(S1,'combined','LV')
rP = polyfit(RFA.combined,RFA.LV,1);
rYfit = polyval(rP,RFA.combined);
plot(RFA.combined,rYfit,'b-');
sP = polyfit(S1.combined,S1.LV,1);
sYfit = polyval(sP,S1.combined);
plot(S1.combined,sYfit,'y-');
title('Per Rat Basis Both Areas Component 3')