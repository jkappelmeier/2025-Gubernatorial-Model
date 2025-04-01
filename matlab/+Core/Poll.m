% Class that contains information regarding a poll
classdef Poll
    properties
        type (1,1) string
        election (1,1) string
        geography (1,1) string
        date (1,1) datetime
        timeSinceT0 (1,1) double
        result (1,1) double
        name (1,1) string
        N (1,1) int32
        sigma (1,1) double
    end

    methods
        % Constructor for this class
        %
        % Inputs:
        %   geography - Geographic area that was polled
        %   date - Date of poll in format "MM/DD/YYYY"
        %   result - Result as a vector in format [incumbent, challenger]
        %   pollster - Name of pollster
        %   sampleSize - Sample size of poll
        % Output:
        %   Instance of this class
        function obj = Poll(type, election, geography, date, result, args)
            arguments
                type (1,1) string {mustBeMember(type, ["Presidential", ...
                    "Senate", "House", "Governor", "Generic Ballot"])}
                election (1,1) string
                geography (1,1) string
                date (1,1) string
                result (1,:) double
                args.name (1,1) string
                args.N (1,1) double
            end
    
            C = Common.Config();
    
            obj.election = election;
            obj.type = type;
            obj.geography = geography;
            dateArray = split(date, "/");
            obj.date = datetime(double(dateArray(3)), double(dateArray(1)), double(dateArray(2)));
            obj.timeSinceT0 = days(obj.date - C.startDate);
            obj.result = result;
            obj.name = args.name;
            obj.N = args.N;
            obj.sigma = C.pollingSigmaSF * sqrt(1000 / args.N);
        end
    end
end
