function [out, idx] = bb(in, type, opts)
% convert bounding boxes into different formats
% 
% Inputs:
%     in: input boxes, can be a matrix or an array of structs with 'BoundingBox' field
%     type: specifies the input and output box format
%     opts:
% Outputs:
%     out : output boxes
%     idx : specifies indices of boxes which are returned.
% 
% box fomats:
%   m :: matlab's format:           [x1,y1,w,h]: (x1,y1)->top left corner, 0.5 point moved out, im=[0 1 0 0] -> [0.5 1]
%   b :: top left corner and size:  [x1,y1,w,h]: (x1,y1)->top left corner, im=[0 1 0 0] -> [1 1]
%   r :: rect format:               [y1,y2,x1,x2], im=[0 1 0 0] -> [2 2]
%   c :: faster r-cnn format:       [x1,y1,x2,y2]: (x1,y1)->top left corner, (x2,y2)->bottom right corner, im=[0 1 0 0] -> [2 2]
%   s :: stats: array of structs with field 'BoundingBox' containing matlab format boundingbox, im=[0 1 0 0] -> [0.5 1]
% 

if nargin < 3
    opts = [];
end
opts_default = struct('clip',0,'sz',[Inf Inf]);
opts = bia.utils.updatefields(opts_default, opts);
clip = opts.clip;
sz = opts.sz;

if isempty(in)
    out = zeros(0,4);
    idx = zeros(0,0);
    return;
end

if type(1) == 's'
    type(1) = 'm';
    out   = [in.BoundingBox];
    cols  = length(in(1).BoundingBox);
    out   = reshape(out, cols, [])';
    if isempty(out)
        out     = [];
        idx     = [];
        return;
    end
    idx_del = out(:,3) == 0 | out(:,4) == 0;
    out(idx_del, :) = [];% remove empty bboxes
    idx = find(~idx_del);
    
    in = out;
else
    idx = [1:size(in,1)]';
end

% convert from input format to b-format
if type(1) == 'b'
elseif  type(1) == 'm'
    in(:,1:2) = in(:,1:2) + 0.5;
elseif type(1) == 'c'% needs sz
    if clip
        in = [max(1, in(:,1)), max(1, in(:,2)), in(:,3)-in(:,1)+1, in(:,4)-in(:,2)+1];
    else
        in = [in(:,1), in(:,2), in(:,3)-in(:,1)+1, in(:,4)-in(:,2)+1];
    end
    in = round(in);
elseif type(1) == 'r'
    in  = in(:,[3,1,4,2]);
    in(:,[3, 4]) = in(:,[3, 4])-in(:,[1, 2])+1;
end

% convert from b-format to output format
if type(3) == 'b'
    out = in;
elseif type(3) == 'm'
    out = in;
    out(:,1:2) = out(:,1:2) - 0.5;
elseif type(3) == 'c'
    out = [in(:,1), in(:,2), in(:,1)+in(:,3)-1, in(:,2)+in(:,4)-1];
elseif type(3) == 'r'
    out = [in(:,1), in(:,2), in(:,1)+in(:,3)-1, in(:,2)+in(:,4)-1];
    out = out(:,[2,4,1,3]);
    out = round(out);
    if clip
        out(:, [1,3]) = max(1, out(:, [1,3]));
        out(:, [2,4]) = min(repmat(sz(1:2), size(out,1),1), out(:, [2,4]));
    end
end

end