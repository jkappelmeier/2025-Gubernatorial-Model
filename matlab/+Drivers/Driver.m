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

results = Common.Simulate(model, 10000);
Visualization.printResults.printStandardResults(model, results);