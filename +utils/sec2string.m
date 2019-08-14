function [tStr,hh,mm,ss] = sec2string(s)
%% SEC2STRING  Take seconds (double) and return time string for hours, minutes, and seconds
%
%  tStr = utils.SEC2STRING(s);
%  [tStr,hh,mm,ss] = utils.SEC2STRING(s);
%
%  --------
%   OUTPUT
%  --------
%    tStr      :     Time string of format 
%                       '%g hour(s) %g minute(s) %.5g second(s)' 
%
%     hh       :     Number of hours (double precision, but is a whole
%                       number)
%
%     mm       :     Number of minutes (see hh)
%
%     ss       :     Number of seconds (double precision, decimal)
%
% By: Max Murphy  v1.0  2019-08-14  Original version (R2017a)

%% GET HOURS
hh = floor(s / (60 * 60));
if (hh == 1)
   hStr = sprintf('%g hour',hh);
else
   hStr = sprintf('%g hours',hh);
end

%% GET MINUTES
m = rem(s,(60 * 60));
mm = floor(m / 60);
if (mm == 1)
   mStr = sprintf('%g minute',mm);
else
   mStr = sprintf('%g minutes',mm);
end

%% GET SECONDS
ss = rem(m,60);
if (ss == 1)
   sStr = sprintf('%.5g second',ss);
else
   sStr = sprintf('%.5g seconds',ss);
end

%% OUTPUT STRING
tStr = sprintf('%s %s %s',hStr,mStr,sStr);

end