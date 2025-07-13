classdef Reader
    methods (Static)
        function corr = readCorrelation(file)
            corr = readmatrix(file);
            corr = corr(:,3:end);
        end
        
        function geographies = readFundamentals(file)
            arguments
                file (1,1) string
            end

            geographies = readtable(file);
            geographies.Type = string(geographies.Type);
            geographies.Election = string(geographies.Election);
            geographies.Geography = string(geographies.Geography);
            geographies.DemCandidate = string(geographies.DemCandidate);
            geographies.RepCandidate = string(geographies.RepCandidate);
        end

        function polls = readPolls(file)
            arguments
                file (1,1) string
            end

            C = Common.Config;

            opts = detectImportOptions(file);
            opts = setvaropts(opts,'Date','InputFormat','MM/dd/uuuu');
            data = readtable(file, opts);
            N = length(data.Type);

            polls = table();

            for i = 1:N
                if i > 1
                    polls(height(polls)+1,:) = polls(1,:);
                end
                Dem = data.Democrat(i);
                Dem = Dem{:};
                Dem(Dem == '%') = [];
                Rep = data.Republican(i);
                Rep = Rep{:};
                Rep(Rep == '%') = [];
                result = str2double(Dem) / (str2double(Dem) + str2double(Rep));

                dateArray = split(string(data.Date(i)), "/");
                date = datetime(double(dateArray(3)), double(dateArray(1)), double(dateArray(2)));

                polls.Type(i) = string(data.Type(i));
                polls.Election(i) = string(data.Election(i));
                polls.Geography(i) = string(data.Geography(i));
                polls.Date(i) = date;
                polls.DaysFromT0(i) = days(date - C.startDate);
                polls.Result(i) = result;
                polls.Sigma(i) = C.pollingSigmaSF * sqrt(1000 / data.SampleSize(i));
            end
        end
    end
end