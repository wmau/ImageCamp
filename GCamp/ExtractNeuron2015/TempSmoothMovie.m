function [] = TempSmoothMovie(infile,outfile,smoothfr);



info = h5info(infile,'/Object');
NumFrames = info.Dataspace.Size(3);
XDim = info.Dataspace.Size(1);
YDim = info.Dataspace.Size(2);

h5create(outfile,'/Object',info.Dataspace.Size,'ChunkSize',[XDim YDim 1 1],'Datatype','single');

for i = 1:smoothfr-1
    F{i} = single(h5read(infile,'/Object',[1 1 i 1],[XDim YDim 1 1]));
    h5write(outfile,'/Object',single(F{i}),[1 1 i 1],[XDim YDim 1 1]);
end

for i = smoothfr:NumFrames
  display(['Calculating F traces for movie frame ',int2str(i),' out of ',int2str(NumFrames)]);
  F{smoothfr} = single(h5read(infile,'/Object',[1 1 i 1],[XDim YDim 1 1]));
  Fout = zeros(size(F{1}));
  for j = 1:smoothfr
    Fout = Fout+F{j};
  end
  Fout = Fout./smoothfr;
  h5write(outfile,'/Object',single(Fout),[1 1 i 1],[XDim YDim 1 1]);

  for j = 1:smoothfr-1
      F{j} = F{j+1};
  end
end

  