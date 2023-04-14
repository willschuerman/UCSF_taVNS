dat = load('/Users/mattleonard/Downloads/SMT_JR_4.13.2023.mat');

blockOrder = {'baseline','speech prep','washout1','cold1','washout2','cold2'};
blockLen = 300;
fs = dat.isi*100000;

%% plot specific block

clear sp
figure('Position',[1729           2        1217         913]);
for i = 1:size(dat.data,2)
    sp(i) = subplot(size(dat.data,2),1,i);
    plot(dat.data(:,i));

    hold on;
    
    for j = 1:length(blockOrder)
        line([blockLen*fs*j blockLen*fs*j],get(gca,'YLim'),'Color','r');
        text((blockLen*fs*j)-((blockLen*fs)/2),max(get(gca,'YLim')),blockOrder{j},'HorizontalAlignment','center');
    end

    title(dat.labels(i,:));
end
linkaxes(sp,'x');

%% plot specific block

blockToPlot = 'cold2';

clear sp
figure('Position',[1729           2        1217         913]);
for i = 1:size(dat.data,2)
    sp(i) = subplot(size(dat.data,2),1,i);
    plot(dat.data(blockLen*fs*(find(strcmpi(blockToPlot,blockOrder))-1):(blockLen*fs*(find(strcmpi(blockToPlot,blockOrder)))),i));

    hold on;
    % text((blockLen*fs*find(strcmpi(blockToPlot,blockOrder)))-((blockLen*fs)/2),max(get(gca,'YLim')),blockOrder{find(strcmpi(blockToPlot,blockOrder))},'HorizontalAlignment','center');
    title(dat.labels(i,:));

end
linkaxes(sp,'x');