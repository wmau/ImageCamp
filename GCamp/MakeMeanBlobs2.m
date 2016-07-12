function MakeMeanBlobs2(NeuronImage,ROIavg)
%
%
%

%%
    nNeurons = length(NeuronImage);
    
    BinBlobs = cell(1,nNeurons); 
    for n=1:nNeurons
        maskedAvg = ROIavg{n};
        maskedAvg(~NeuronImage{n}) = 0;
        
        %Normalize.
        maskedAvg = maskedAvg ./ max(maskedAvg(:));
        BinBlobs{n} = maskedAvg > 0.9;
    end
    
    save('MeanBlobs.mat','BinBlobs');
    
end