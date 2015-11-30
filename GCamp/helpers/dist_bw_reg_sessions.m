function [ neuron_centroid, centroid_dist, neuron_axisratio, ratio_diff, ...
    neuron_orientation, orientation_diff ] = dist_bw_reg_sessions( BinBlobs_reg, shuffle )
%[ neuron_centroid, centroid_dist, neuron_axisratio, rtio_diff, neuron_orientation, ...
% orientation_diff ] = dist_bw_reg_sessions( BinBlobs_reg, shuffle )
%   Calculate neuron centroid and distance to same centroid in each
%   registered session.
%
% INPUTS
%   BinBlobs_reg: of the form BinBlobs{session_number}{neuron_number},
%   where each entry is the neuron mask
%
%   shuffle(optional): 1 = shuffle BinBlobs_reg randomly for each session
%   when calculating centroid_dist, ratio_diff, and orientation_diff
%   to get shuffled distributions of distances/differences.  0 = no shuffle (default)
%
% OUTPUTS
%   neuron_centroid: same form as BinBlobs_reg, with x and y coordinates of
%   the neurons mask centroid
%
%   centroid_dist: a num_sessions - 1 x num_sessions x num_neurons array
%   with the distances between neuron centroids
%   
%   neuron_axisratio: ratio of minor to major axis for each neuron mask.
%   Form = 

if nargin < 2
    shuffle = 0;
end

num_sessions = length(BinBlobs_reg);
num_neurons = length(BinBlobs_reg{1});

%% Get centroids, axis ratios, and orientations for each neuron
for j = 1:num_sessions
   for k = 1: num_neurons
      stats_temp = regionprops(BinBlobs_reg{j}{k},'Centroid','MajorAxisLength','MinorAxisLength','Orientation');
      neuron_centroid{j}{k} = stats_temp.Centroid;
      neuron_axisratio{j}(k) = stats_temp.MinorAxisLength/stats_temp.MajorAxisLength;
      neuron_orientation{j}(k) = stats_temp.Orientation;
   end
   
end

%% Calculate difference in centers-of-mass, axis ratio, and orientation
centroid_dist = nan(num_sessions-1, num_sessions, num_neurons);
ratio_diff = nan(num_sessions-1, num_sessions, num_neurons);
orientation_diff = nan(num_sessions-1, num_sessions, num_neurons);
for k = 1:num_sessions-1
    for ll = k+1:num_sessions
        if shuffle == 1
            neuron_index_use = randperm(num_neurons);
        elseif shuffle == 0
            neuron_index_use = 1:num_neurons;
        end
        for j = 1:num_neurons
            centroid_dist(k,ll,j) = pdist([neuron_centroid{k}{j}; ...
                neuron_centroid{ll}{neuron_index_use(j)}]);
        end
        ratio_diff(k,ll,:) = neuron_axisratio{ll}(neuron_index_use) - neuron_axisratio{k};
        orientation_diff(k,ll,:) = neuron_orientation{ll}(neuron_index_use) - neuron_orientation{k};
    end
end

end
