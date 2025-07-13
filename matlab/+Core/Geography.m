classdef Geography
    properties
        type (1,1) string
        election (1,1) string
        geography (1,1) string 
        fundamentalsEstimate (1,1) double
        demCandidate (1,1) string
        repCandidate (1,1) string
        incumbency (1,1) int32 = 0
        prevIncumbency (1,1) int32 = 0
        usePrevResults (1,1) int32 = 0
        electoralVotes (1,1) double = 0
    end

    methods
        function obj = Geography(type, election, geography, fundamentalsEstimate, ...
                demCandidate, repCandidate, ...
                incumbency, prevIncumbency, ...
                usePrevResults, args)
            arguments
                type (1,1) string {mustBeMember(type, ["Presidential", ...
                    "Senate", "House", "Governor", "Generic Ballot"])}
                election (1,1) string
                geography (1,1) string
                fundamentalsEstimate (1,1) double
                demCandidate (1,1) string
                repCandidate (1,1) string
                incumbency (1,1) int32 = 0
                prevIncumbency (1,1) int32 = 0
                usePrevResults (1,1) logical = 0
                args.electoralVotes (1,1) double = 0;
            end

            obj.type = type;
            obj.election = election;
            obj.geography = geography;
            obj.fundamentalsEstimate = fundamentalsEstimate;
            obj.demCandidate = demCandidate;
            obj.repCandidate = repCandidate;
            obj.incumbency = incumbency;
            obj.prevIncumbency = prevIncumbency;
            obj.usePrevResults = usePrevResults;
            obj.electoralVotes = args.electoralVotes;
        end

        function obj = addPolls(obj, poll)
            arguments
                obj Core.Geography
                poll (1,:) Core.Poll
            end

            C = Data.config;
            
            if length(poll) > 1
                for i = 1:length(poll)
                    obj.addPolls(poll(i));
                end
            else
                if strcmp(poll.geography, obj.name) && ... 
                        days(C.currentDate - poll.date) >= 0
                    obj.polls = [obj.polls, poll];
                end
            end

        end
    end
end