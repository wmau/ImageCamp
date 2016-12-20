function MakeMeanBlobs4(NeuronImage,NeuronAvg)
%MakeMeanBlobs4(NeuronImage,NeuronAvg)
%
%   Kind of a hack right now to replace legacy MeanBlobs. Necessary for
%   neuron registration.

    nNeurons = length(NeuronImage);
    BinBlobs = cell(1,nNeurons);
    for n=1:nNeurons
        BinBlobs{n} = NeuronImage{n};
        BinBlobs{n}(logical(NeuronImage{n})) = NeuronAvg{n};
    end
    
    save('MeanBlobs.mat','BinBlobs');
end