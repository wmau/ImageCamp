function [h] = subplot_auto( n_total, n )
% h = subplot_auto( n_total, n )
%
% Automatically creates subplots that keep the images as close to square as
% possible, e.g. if you have 3 or 4 plots, it uses subplot (2,2,x), if you
% have somewhere between 10 and 16, it uses subplot (4,4,x), etc.
%
% INPUTS
%   n_total: the total number of plots you want to make
%
%   n: which number out of n_total plots you want to create a subplot for.
% 
% Example: subplot_auto(3,2) is the same as subplot(2,2,3);

if n_total <= 2
    h = subplot(1,2,n);
elseif n_total <= 4
    h = subplot(2,2,n);
elseif n_total <= 9
    h = subplot(3,3,n);
elseif n_total <= 16
    h = subplot(4,4,n);
elseif n_total <= 25
    h = subplot(5,5,n);
else
    disp('You really want to have more than 25 subplots in a figure?')
end

end

