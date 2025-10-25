function results = Simulate(model, nSims)
arguments
    model Core.Model
    nSims double
end

idx = model.geographies.Type == "Generic Ballot";
geographies = model.geographies;
geographies(idx,:) = [];
xEstSim = model.xGeoEst(:,end);
xEstSim(idx) = [];
pEstSim = model.pGeoEst(:,:,end);
pEstSim(idx,:) = [];
pEstSim(:,idx) = [];
sims = mvnrnd(xEstSim, pEstSim, nSims)';

%% Presidential Simulations
idxPres = geographies.Type == "President";
if sum(idxPres) > 0
geoPres = geographies(idxPres,:);
xPres = sims(idxPres, :);
electoralVotes = zeros(nSims,1);
for i = 1:length(geoPres.Type)
    if (contains(geoPres.Geography(i), model.cdData.CongressionalDistrict)) && contains(geoPres.Geography(i), "1st")
        stateIdx = geoPres.Geography(i) == model.cdData.CongressionalDistrict;
        state = string(model.cdData.State(stateIdx));
        cdIdx = string(model.cdData.State) == state;
        cds = model.cdData.CongressionalDistrict(cdIdx);
        idxTemp = geoPres.Type == "President" & contains(geoPres.Geography,string(cds));
        xTemp = xPres(idxTemp,:);
        hTemp = model.cdData.TotalVote(cdIdx)/sum(model.cdData.TotalVote(cdIdx));
        xTemp = hTemp' * xTemp;
        
        stateIdxWin = xTemp > 0.5;
        electoralVotes(stateIdxWin) = electoralVotes(stateIdxWin) + 2;
    end
    
    idxWin = xPres(i,:) > 0.5;
    electoralVotes(idxWin) = electoralVotes(idxWin) + geoPres.ElectoralVotes(i);
end
hNatPres = model.hMapCd(:,idxPres) .* model.cdData.TotalVote;
hNatPres = sum(hNatPres, 1) / sum(hNatPres, "all");
xPresPopularVote = hNatPres * xPres;
idxPresPopularVote = xPresPopularVote > 0.5;

demPercent = sum(electoralVotes >= 270)/nSims;
repPercent = sum(electoralVotes <= 268)/nSims;
tiePercent = 1 - demPercent - repPercent;

results.president.demPercent = demPercent;
results.president.repPercent = repPercent;
results.president.tiePercent = tiePercent;
results.president.sims = electoralVotes;
results.president.average = mean(electoralVotes);
results.president.demECdemPV = sum(idxPresPopularVote' & electoralVotes >= 270)/nSims;
results.president.demECrepPV = sum(electoralVotes >= 270 & ~idxPresPopularVote')/nSims;
results.president.repECdemPV = sum(electoralVotes <= 268 & idxPresPopularVote')/nSims;
results.president.repECrepPV = sum(electoralVotes <= 268 & ~idxPresPopularVote')/nSims;

% Get histogram counts and bin edges
[counts, edges] = histcounts(electoralVotes, 'BinWidth', 10, 'BinMethod', 'integers'); % adjust bin width if needed
binCenters = edges(1:end-1) + diff(edges)/2;
counts = counts/nSims*100;

% Create bar plot manually
b = bar(binCenters, counts, 'FaceColor', 'flat');

b.EdgeColor = 'black';

% Assign colors to each bar
colors = zeros(length(counts), 3);
for i = 1:length(binCenters)
    if binCenters(i) > 270
        colors(i,:) = [0 0 1];  % Blue
    else
        colors(i,:) = [1 0 0];  % Red
    end
end

% Apply colors
b.CData = colors;

xlabel("Electoral Votes")
ylabel("Frequency (%)")
title("Presidential Simulations")

end

%% Senate Simulatiosn
idxSen = geographies.Type == "Senate";
if sum(idxSen) > 0
xSen = sims(idxSen, :);
dSeats = sum(xSen > 0.5, 1) + Common.Config.senateDInit;
rSeats = sum(xSen < 0.5, 1) + Common.Config.senateRInit;
idxTie = dSeats == rSeats;
if sum(idxPres) > 0
    electoralVotesSenateTie = electoralVotes(idxTie);
    dPercentTie = sum(electoralVotesSenateTie >= 270) / sum(idxTie);
    rPercentTie = sum(electoralVotesSenateTie <= 268) / sum(idxTie);
else
    if strcmp(Common.Config.curVP, "Democrat")
        dPercentTie = 1;
        rPercentTie = 0;
    else
        dPercentTie = 0;
        rPercentTie = 1;
    end
end

dSenPercentWin = sum(dSeats > 50)/nSims;
rSenPercentWin = sum(rSeats > 50)/nSims;
tiePercentSen = sum(dSeats == rSeats) /nSims;
dSenPercentWin = dSenPercentWin + tiePercentSen * dPercentTie;
rSenPercentWin = rSenPercentWin + tiePercentSen * rPercentTie;
results.senate.demPercent = dSenPercentWin;
results.senate.repPercent = rSenPercentWin;
results.senate.demAverage = mean(dSeats);
results.senate.repAverage = mean(rSeats);

% Define bin edges
[counts, edges] = histcounts(dSeats, 'BinWidth', 1, 'BinMethod', 'integers');
binCenters = edges(1:end-1) + diff(edges)/2;
counts = counts/nSims*100;

% Create a figure
figure; hold on;

% Loop through and draw each bar manually
for i = 1:length(counts)
    x = binCenters(i);
    y = counts(i);

    if x < 50
        % Red bar
        bar(x, y, 'FaceColor', [1 0 0], 'EdgeColor', 'none','EdgeColor', 'k');
    elseif x > 50
        % Blue bar
        bar(x, y, 'FaceColor', [0 0 1], 'EdgeColor', 'none','EdgeColor', 'k');
    else
        % Split bar at 50
        red_height = rPercentTie * y;

        % Top blue part, stacked on top
        bar(x, y, 'FaceColor', [0 0 1], 'EdgeColor', 'none','EdgeColor', 'k');

        % Bottom red part
        bar(x, red_height, 'FaceColor', [1 0 0], 'EdgeColor', 'none','EdgeColor', 'k');

        
    end
end

% Optional: Tidy up the plot
xlabel('Democratic Senate Seats');
ylabel('Frequency (%)');
title('Senate Seat Simulation');
box on;
end
%% House Simulation
idxHouse = geographies.Type == "House";
if sum(idxHouse) > 0
xHouse = sims(idxHouse, :);
dHouseSeats = sum(xHouse > 0.5, 1);
rHouseSeats = sum(xHouse < 0.5, 1);
dHousePercent = sum(dHouseSeats >= 218)/nSims;
rHousePercent = sum(rHouseSeats >= 218)/nSims;
results.house.demPercent = dHousePercent;
results.house.repPercent = rHousePercent;
results.house.demAverage = mean(dHouseSeats);
results.house.repAverage = mean(rHouseSeats);

% Get histogram counts and bin edges
figure()
[counts, edges] = histcounts(dHouseSeats, 'BinWidth', 1, 'BinMethod', 'integers'); % adjust bin width if needed
binCenters = edges(1:end-1) + diff(edges)/2;
counts = counts/nSims*100;

% Create bar plot manually
b = bar(binCenters, counts, 'FaceColor', 'flat');

b.EdgeColor = 'none';


% Assign colors to each bar
colors = zeros(length(counts), 3);
for i = 1:length(binCenters)
    if binCenters(i) > 218
        colors(i,:) = [0 0 1];  % Blue
    else
        colors(i,:) = [1 0 0];  % Red
    end
end

% Apply colors
b.CData = colors;

xlabel("Democratic House Seats")
ylabel("Frequency (%)")
title("House Simulations")
end

%% Governor Simulation
idxGov = geographies.Type == "Governor";
if sum(idxGov) > 0
xGov = sims(idxGov, :);
dGov = sum(xGov > 0.5, 1);
rGov = sum(xGov < 0.5, 1);
results.governor.demAverage = mean(dGov);
results.governor.repAverage = mean(rGov);

% Get histogram counts and bin edges
figure()
% histogram(dGov, 'BinWidth', 1, 'BinMethod', 'integers', 'FaceColor', 'blue', 'Normalization', 'probability');
[counts, edges] = histcounts(dGov, 'BinWidth', 1, 'BinMethod', 'integers');
counts = counts/nSims*100;
bin_centers = (edges(1:end-1) + edges(2:end)) / 2;
bar(bin_centers, counts, 'FaceColor', 'blue')

xlabel("Democratic Governors")
ylabel("Frequency (%)")
title("Governor Simulations")
end

%% Correlations
if sum(idxPres) > 0 && sum(idxSen) > 0 && sum(idxHouse) > 0
results.corr.dPresdSendHouse = sum(electoralVotes >= 270 & dSeats' >= 50 & dHouseSeats' >= 218)/nSims;
results.corr.dPresdSenrHouse = sum(electoralVotes >= 270 & dSeats' >= 50 & rHouseSeats' >= 218)/nSims;
results.corr.dPresrSendHouse = sum(electoralVotes >= 270 & rSeats' >= 51 & dHouseSeats' >= 218)/nSims;
results.corr.dPresrSenrHouse = sum(electoralVotes >= 270 & rSeats' >= 51 & rHouseSeats' >= 218)/nSims;
results.corr.rPresdSendHouse = sum(electoralVotes <= 268 & dSeats' >= 51 & dHouseSeats' >= 218)/nSims;
results.corr.rPresdSenrHouse = sum(electoralVotes <= 268 & dSeats' >= 51 & rHouseSeats' >= 218)/nSims;
results.corr.rPresrSendHouse = sum(electoralVotes <= 268 & rSeats' >= 50 & dHouseSeats' >= 218)/nSims;
results.corr.rPresrSenrHouse = sum(electoralVotes <= 268 & rSeats' >= 50 & rHouseSeats' >= 218)/nSims;
end


end