function bounds = sections(x,y)
%function sections(x,y) 
%   
%   This function takes position data and partitions the maze into
%   sections. 
%
%   INPUTS: 
%       X and Y: Position vectors after passing through
%       PreProcessMousePosition. 
%
%   OUTPUTS: 
%       BOUNDS: Struct containing coordinates for the corners of maze
%       sections in the following intuitively-named fields. 
%           base = Start position (vertical stripes side). 
%           center = Middle stem. 
%           choice = Choice point (triangle side). 
%           approach_l = Approaching left arm. 
%           approach_r = Approaching right arm. 
%           left = Left arm. 
%           right = Right arm. 
%           return_l = Returning to start position from left arm.
%           return_r = Returning to start position right right arm. 
%

%% Get xy coordinate bounds for maze sections. 
    xmax = max(x); xmin = min(x); 
    ymax = max(y); ymin = min(y); 
    
    %Find center arm borders. 
    center = getcenterarm(x,y); 
    
    %Establish maze arm widths. 
    w = 40;              %Width of arms.
    l = 80;              %Shift from top/bottom of maze for center stem. 
    
%% Left arm. 
    left.x = [xmin, xmin, xmax, xmax];
    left.y = [ymin, ymin+w, ymin, ymin+w]; 
    
%% Right arm. 
    right.x = left.x;
    right.y = [ymax-w, ymax, ymax-w, ymax]; 
    
%% Left return. 
    return_l.x = [xmax-l, xmax-l, xmax, xmax]; 
    return_l.y = [ymin+w, center.y(1), ymin+w, center.y(1)]; 
    
%% Right return. 
    return_r.x = return_l.x;  
    return_r.y = [center.y(2), ymax-w, center.y(2), ymax-w]; 
    
%% Choice. 
    choice.x = [xmin, xmin, xmin+l, xmin+l]; 
    choice.y = [center.y(1), center.y(2), center.y(1), center.y(2)];
    
%% Left approach. 
    approach_l.x = choice.x;  
    approach_l.y = [left.y(2), center.y(1), left.y(2), center.y(1)]; 

%% Right approach. 
    approach_r.x = choice.x;
    approach_r.y = [center.y(2), right.y(1), center.y(2), right.y(1)]; 
    
%% Base. 
    base.x = return_l.x; 
    base.y = choice.y; 
    
%% Check with plot. 
    figure;
    plot(x,y); 
    hold on;
    plot(left.x,left.y, 'r*', right.x, right.y, 'b.', return_l.x, return_l.y, 'k.',...
    return_r.x, return_r.y, 'k.', choice.x, choice.y, 'g.', center.x, center.y, 'm.',...
    base.x, base.y, 'g*', approach_l.x, approach_l.y, 'b.', approach_r.x, approach_r.y, 'k*'); 

%% Output. 
    bounds.base = base; 
    bounds.center = center; 
    bounds.choice = choice;
    bounds.approach_l = approach_l;
    bounds.approach_r = approach_r; 
    bounds.left = left; 
    bounds.right = right; 
    bounds.return_l = return_l;
    bounds.return_r = return_r; 
end