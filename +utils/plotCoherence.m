function plotCoherence(wcoh,f,t,coi,xlab,ylab,wcs,thresh)
%% PLOTCOHERENCE  Helper function to plot coherence (from example R2017a)
%
%  PLOTCOHERENCE(wcoh,f,t,coi,xlab,ylab);
%
% 2019-08-12

%% PARSE INPUT
if nargin < 8
   thresh = 0.95;
end

if nargin < 6
   ylab = 'f (Hz)';
end

if nargin < 5
   xlab = 't (ms)';
end

if nargin < 4
   coi = nan(1,size(wcoh,2));
end

if nargin < 3
   t = linspace(0,1,size(wcoh,2));
end

%% PLOT
F = log2(f);
Yticks = 2.^(round(min(F)):round(max(F)));
imagesc(t,F,wcoh);
set(gca,'YLim',[min(F) max(F)], ...
   'layer','top', ...
   'YTick',log2(Yticks(:)), ...
   'YTickLabel',num2str(sprintf('%.2f\n',Yticks)), ...
   'layer','top','YDir','normal');
hold on;
plot(t,log2(coi),'w--');

if nargin > 6
   [tt,ff] = meshgrid(t,F);
   u = cos(angle(wcs));
   v = sin(angle(wcs));
   idx = abs(wcs) < thresh;
   u(idx) = nan;
   v(idx) = nan;
   
   xscl = mode(diff(t));
   u = u .* xscl;
   
   yscl = diff(F);
   yscl = [yscl; yscl(end)];
   
   nscly = 1/numel(F);
   nsclx = 1/numel(t);
   
   u = u .* xscl .* 0.75;
   
   v = v .* yscl .* 0.75 .* (nsclx/nscly);
   
%    quiver(tt(1:5:end,1:10:end),ff(1:5:end,1:10:end),...
%       u(1:5:end,1:10:end),v(1:5:end,1:10:end),...
%       'k-','filled');

   quiver(tt,ff,u,v,...
      0.1,'Color','k','LineWidth',1.5);
   
end

xlabel(xlab);
ylabel(ylab);
hcol = colorbar;
hcol.Label.String = 'Magnitude-Squared Coherence';
title('Wavelet Coherence');

end