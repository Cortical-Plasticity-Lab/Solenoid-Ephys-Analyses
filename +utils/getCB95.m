function cb = getCB95(x,dim)
%GETCB95 Return 95% confidence bounds
%
%  cb = utils.getCB95(x);
%  cb = utils.getCB95(x,dim);
%
% Inputs
%  x   - Data vector
%  dim - 1 (def) | 2 [Dimension to estimate confidence-band along]
%
% Output
%  cb - Cell containing [lb, ub] based on sorted values of x.
%        -> Removes nan values
%        -> Removes inf values
%
% See also: utils, tbl.gfx.PETH, splitapply, findgroups

if nargin < 2
   dim = 1;
end

switch dim
   case 1
      x = x(~any(isnan(x),2) & ~(any(isinf(x),2)),:);
      x = sort(x,1,'ascend');
      n = size(x,1);
      if n == 0
         cb = nan(2,size(x,2));
         return;
      elseif n == 1
         cb = x;
         return;
      end
      i_lb = max(round(0.025 * n),1);
      i_ub = round(0.975 * n);
      cb = [x(i_lb,:); x(i_ub,:)];
   case 2
      x = x(:,~any(isnan(x),1) & ~(any(isinf(x),1)));
      x = sort(x,2,'ascend');
      n = size(x,2);
      if n == 0
         cb = nan(2,size(x,1));
         return;
      elseif n == 1
         cb = x;
         return;
      end
      i_lb = max(round(0.025 * n),1);
      i_ub = round(0.975 * n);
      cb = [x(:,i_lb), x(:,i_ub)];
   otherwise
      error('Expected `dim` to be either 1 or 2.');
end

end