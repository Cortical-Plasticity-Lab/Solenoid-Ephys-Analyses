% Exclude ipsilateral trials
initialVars = who;
excBl = contains(string(T.BlockID),"_7");
excSurg = (T.SurgID == "R19-234");
exc = and(excBl,excSurg);
T(exc,:)= [];
excBl = contains(string(T.BlockID),"_4");
excSurg = (T.SurgID == "R19-232");
exc = and(excBl,excSurg);
T(exc,:) = [];
clearvars('-except',initialVars{:})
save('Solenoid-Table_5-ms_excluded_ipsi','T','-v7.3');