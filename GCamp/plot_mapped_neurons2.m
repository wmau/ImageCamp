function [ ] = plot_mapped_neurons2( ROIbase, ROIreg_mapped, neuron_id)
% plot_mapped_neurons2( ROIbase, ROIreg, neuron_id)
%   Plots each session's neuron ROIs overlaid on the other.  Good for
%   identifying good/bad registrations. Lower-level function for
%   plot_mapped_neurons

figure;

imagesc(create_AllICmask(ROIbase) + 2*create_AllICmask(ROIreg_mapped)); colorbar
title('1 = session 1, 2 = session 2, red outline = both')
hold on
for j = 1:length(neuron_id)
    nid = neuron_id{j};
    if ~isempty(nid) && ~isnan(nid)
        b1 = bwboundaries(ROIbase{j} ,'noholes');
        b2 = bwboundaries(ROIreg_mapped{nid},'noholes');
        plot(b1{1}(:,2),b1{1}(:,1),'r',b2{1}(:,2),b2{1}(:,1),'r');
    end
end
hold off

end

