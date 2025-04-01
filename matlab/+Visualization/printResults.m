classdef printResults
    methods (Static)
        function printStandardResults(geographies, xEst, pEst)
            arguments
                geographies table
                xEst (:,1)
                pEst (:,:)
            end

            for i = 1:length(xEst)
                if ~strcmp(geographies.Type(i),"Generic Ballot")
                    chance = normcdf(xEst(i),0.5,sqrt(pEst(i,i)),1);
                    headerStr = geographies.Election(i) + " " + geographies.Type(i) + ":";
                    disp(headerStr);
                    if geographies.Incumbency(i) == 1
                        dAdd = "*";
                        rAdd = "";
                    elseif geographies.Incumbency(i) == -1
                        rAdd = "*";
                        dAdd = "";
                    else
                        dAdd = "";
                        rAdd = "";
                    end
                    dStr = "    " + geographies.DemCandidate(i) + dAdd + " (D) - Estimate: " + string(round(xEst(i)*100,2)) + "% | Chance of Winning: " + string(round(chance*100,2)) + "%";
                    rStr = "    " + geographies.RepCandidate(i) + rAdd + " (R) - Estimate: " + string(round((1-xEst(i))*100,2)) + "% | Chance of Winning: " + string(round((1-chance)*100,2)) + "%";
                    if chance > 0.5
                        disp(dStr)
                        disp(rStr)
                    else
                        disp(rStr)
                        disp(dStr)
                    end
                end
            end
        end
    end
end