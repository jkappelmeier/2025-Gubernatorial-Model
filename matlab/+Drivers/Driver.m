clear
clc
close all

cdData = readtable("CongressionalData.csv");
corr = Common.Reader.readCorrelation("Correlation.csv");
fundamentals = Common.Reader.readFundamentals("Fundamentals.csv");
polls = Common.Reader.readPolls("Polls.csv");

model = Core.Model("2025 Model", fundamentals, corr, cdData);
model = model.runPollingAverage(polls);
[xEst, pEst] = model.runEstimate();

sims = mvnrnd(xEst, pEst, 100000)';
Visualization.printResults.printStandardResults(fundamentals, xEst, pEst);