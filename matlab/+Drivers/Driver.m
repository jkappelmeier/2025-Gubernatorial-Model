clear
clc
close all

filePath = pwd;

cdData = readtable("CongressionalData.csv");
corr = Common.Reader.readCorrelation("Correlation.csv");
fundamentals = Common.Reader.readFundamentals("Fundamentals.csv");
polls = Common.Reader.readPolls("Polls.csv");

model = Core.Model("2025 Model", fundamentals, corr, cdData);
model = model.runPollingAverage(polls);
[xEst, pEst] = model.runEstimate();

sims = mvnrnd(xEst, pEst, 1000)';
Visualization.printResults.printGovResults(fundamentals, xEst, pEst);