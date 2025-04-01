% This provides all constants/config values used by model
% Note that data comes from elections from 1996 - 2020

classdef Config

    properties (Constant)
        %% Race Specific Strings
        
        currentDate (1,1) datetime = datetime("today"); % Current Date
        electionDate (1,1) datetime = datetime(2025,4,1);
        startDate (1,1) datetime =  datetime(2025,1,20); % Campaign Start Date

        %% Funadmental Constants
        types (1,4) string = ["President", "Senate", "House", "Governor"];
        biasSigma (1,4) double = [0.04057, 0.0231, 0.0234, 0.0259];
        stateSigma (1,4) double = [0.0354, 0.0608, 0.0448, 0.085734];
        incSigma (1,4) double = [0, 0.0322, 0.0305, 0];

        biasCorr (4,4) double = [1, 0.4166, 0.5644, 0.2171;
            0.4166, 1, 0.9004, 0.5212;
            0.5644, 0.9004, 1, 0.3020;
            0.2171, 0.5212, 0.3020, 1];

        incCorr (4,4) double = [0, 0, 0, 0;
            0, 1, 0.9542, 0;
            0, 0.9542, 1, 0;
            0, 0, 0, 0];
        
        %% Polling Constants
        
        pollingSigmaSF (1,1) double {mustBePositive} = 0.0566; % Average polling error at N = 1000
        

        pollingBiasSigma (1,4) = [0.0248, 0.0231, 0.0241, 0.0247];
        pollingStateSigma (1,4) = [0.0304, 0.0418, 0.0467, 0.0415];
        pollingBiasProcessNoise (1,4) = [7.75e-6, 6.73e-6, 7.33e-6, 7.68e-6];
        pollingStateProcessNoise (1,4) = [1.17e-5, 2.2e-5, 2.75e-5, 2.17e-5];
        
        % polling correlation:
        pollBiasCorr (4,4) double = [1, 0.9909, 0.8875, 0.9104;
            0.9909, 1, 0.8459, 0.8979;
            0.8875, 0.8459, 1, 0.7934;
            0.9104, 0.8979, 0.7934, 1];
        
    end
end