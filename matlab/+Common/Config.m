% This provides all constants/config values used by model
% Note that data comes from elections from 1996 - 2020

classdef Config

    properties (Constant)
        %% Race Specific Strings
        currentDate (1,1) datetime = datetime("today"); % Current Date
        electionDate (1,1) datetime = datetime(2025,11,4);
        startDate (1,1) datetime =  datetime(2025,1,20); % Campaign Start Date

        %% Funadmental Constants
        types (1,4) string = ["President", "Senate", "House", "Governor"];
        biasSigma (1,4) double = [0.04057, 0.0231, 0.0234, 0.0259];
        districtSigma (1,4) double = [0.0390, 0.0390, 0.0390, 0.0390];
        electionSigma (1,4) double = [0, sqrt(0.0608^2-0.0299^2), sqrt(0.0448^2-0.0390^2), sqrt(0.085734^2-0.0299^2)];
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
        
        pollingSigmaSF (1,1) double {mustBePositive} = 0.0158; % Average polling error at N = 1000 .0566
        

        pollingBiasSigma (1,4) = [0.0155, 0.0181, 0.0160, 0.0161];
        pollingDistrictSigma (1,4) = [0.0188, 0.0188, 0.0188, 0.0188]
        pollingElectionSigma (1,4) = [0, sqrt(0.0199^2-0.0148^2), sqrt(0.0325^2-0.0188^2), sqrt(0.022^2-0.0148^2)];
        pollingBiasProcessNoise (1,4) = [7.75e-6, 1.05e-5, 8.26e-6, 8.36e-6];
        pollingDistrictProcessNoise (1,4) = [1.17e-5, 1.17e-5, 1.17e-5, 1.17e-5];
        pollingElectionProcessNoise (1,4) = [0, 5.86e-6, 2.33e-5, 8.80e-6];
        
        % polling correlation:
        pollBiasCorr (4,4) double = [1, 0.9167, 0.8691, 0.9281;
            0.9167, 1, 0.5729, 0.8721;
            0.8691, 0.5729, 1, 0.703;
            0.9281, 0.8721, 0.703, 1];

        %% Congressional Makeup

        senateDInit (1,1) double = 53;
        senateRInit (1,1) double = 47;
        curVP (1,1) string = "Republican";
        
    end
end