function [ neuron_id ] = get_neuron_from_ROI(NeuronImage, axes_handle, varargin )
% neuron_id = get_neuron_from_ROI(NeuronImage, axes_handle, varargin )
%
%   Get the neuron number by clicking on it.

NumNeurons = length(NeuronImage);

if nargin < 2
    allmask = create_AllICmask(NeuronImage);
    figure
    imagesc(allmask);
    axes_handle = gca;
end

% Get neuron centroids
try
    temp = cellfun(@(a) regionprops(a,'Centroid'),NeuronImage);
    centroids = cat(1,temp.Centroid);
catch
    centroids = [];
    for j = 1:length(NeuronImage)
        temp = regionprops(NeuronImage{j},'Centroid','Area');
        if length(temp) == 1
            centroids = [centroids; temp.Centroid];
        else
            [~, ii] = max(cat(1,temp.Area));
            centroids = [centroids; temp(ii).Centroid];
        end
    end
end

% Get location of neuron centroid from user input
axes(axes_handle);
[x,y] = ginput(1);

% Find closest neuron
xy_diff = centroids - repmat([x,y],NumNeurons,1);
dist_all = sqrt(xy_diff(:,1).^2 + xy_diff(:,2).^2);

[~, neuron_id] = min(dist_all);
disp(['You clicked on neuron ' num2str(neuron_id)]);

% Check
b = bwboundaries(NeuronImage{neuron_id},'noholes');
axes(axes_handle)
hold on
plot(b{1}(:,2),b{1}(:,1),'r.')
hold off

end

