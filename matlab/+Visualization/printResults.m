classdef printResults
    methods (Static)
        function printStandardResults(model, results)
            arguments
                model Core.Model
                results struct
            end

            geographies = model.geographies;
            data = model.cdData;
            idxPres = geographies.Type == "President";
            if sum(idxPres) > 0
                geoPres = geographies(idxPres, :);
                xPres = model.xGeoEst(idxPres, end);
                pPres = model.pGeoEst(idxPres, idxPres, end);
    
                if geoPres.Incumbency(1) == 1
                    inc = [1;0];
                elseif geoPres.Incumbency(1) == -1
                    inc = [0;1];
                else
                    inc = [0;0];
                end
                Visualization.printResults.printResult([results.president.average; 538-results.president.average], ...
                    [results.president.demPercent; results.president.repPercent], ...
                    "President", "Electoral Votes", inc, [geoPres.DemCandidate(1); geoPres.RepCandidate(1)], ...
                    "dispType", "Electoral Votes");
                disp("    Chance of Tie: " + string(round(results.president.tiePercent*100,2))+"%");
                disp("    Chance of " + geoPres.DemCandidate(1) + " winning Popular Vote but losing Electoral College: " + string(round(results.president.repECdemPV*100,2)) + "%");
                disp("    Chance of " + geoPres.RepCandidate(1) + " winning Popular Vote but losing Electoral College: " + string(round(results.president.demECrepPV*100,2)) + "%");
    
    
                hPresNat = model.hMapCd(:, idxPres).*data.TotalVote;
                hPresNat = sum(hPresNat, 1);
                hPresNat = hPresNat/sum(hPresNat);
                xPresNat = hPresNat * xPres;
                sigmaPresNat = sqrt(hPresNat * pPres * hPresNat');
                chancePres = normcdf(xPresNat, 0.5, sigmaPresNat, 1);
                Visualization.printResults.printResult([xPresNat; 1-xPresNat], ...
                    [chancePres; 1-chancePres], ...
                    "President", "Popular Vote", inc, [geoPres.DemCandidate(1); geoPres.RepCandidate(1)], ...
                    "dispType", "Percent");
                
                
                for i = 1:length(geoPres.Type)
                    if geoPres.Incumbency(i) == 1
                        inc = [1;0];
                    elseif geoPres.Incumbency(i) == -1
                        inc = [0;1];
                    else
                        inc = [0;0];
                    end
                    if (contains(geoPres.Geography(i), data.CongressionalDistrict)) && contains(geoPres.Geography(i), "1st")
                        stateIdx = geoPres.Geography(i) == data.CongressionalDistrict;
                        state = string(data.State(stateIdx));
                        cdIdx = string(data.State) == state;
                        cds = data.CongressionalDistrict(cdIdx);
                        idx = geoPres.Type == "President" & contains(geoPres.Geography,string(cds));
                        xTemp = xPres(idx,1);
                        pTemp = pPres(idx,idx);
                        hTemp = data.TotalVote(cdIdx)/sum(data.TotalVote(cdIdx));
                        pTemp = hTemp' * pTemp * hTemp;
                        xTemp = hTemp' * xTemp;
                        chance = normcdf(xTemp, 0.5, sqrt(pTemp), 1);
                        Visualization.printResults.printResult([xTemp; 1-xTemp], ...
                            [chance; 1-chance], ...
                            "President", state + " - 2 Electoral Votes", inc, [geoPres.DemCandidate(i); geoPres.RepCandidate(i)], ...
                            "dispType", "Percent");
                    end
    
                    chance = normcdf(xPres(i), 0.5, sqrt(pPres(i,i)), 1);
                    Visualization.printResults.printResult([xPres(i); 1-xPres(i)], ...
                            [chance; 1-chance], ...
                            "President", geoPres.Geography(i) + " - " + string(geoPres.ElectoralVotes(i)) + " Electoral Votes", inc, [geoPres.DemCandidate(i); geoPres.RepCandidate(i)], ...
                            "dispType", "Percent");
                end
            end
            
            
            idxSen = geographies.Type == "Senate";
            if sum(idxSen) > 0
                geoSen = geographies(idxSen, :);
                disp(" ")
                Visualization.printResults.printResult([results.senate.demAverage; results.senate.repAverage], ...
                    [results.senate.demPercent; results.senate.repPercent], ...
                    "Senate", "Senate Seats", zeros(2,1), ["Democrats"; "Republicans"], ...
                    "dispType", "Senate Seats");
                xSen = model.xGeoEst(idxSen, end);
                pSen = model.pGeoEst(idxSen, idxSen, end);
    
                for i = 1:length(xSen)
                    if geoSen.Incumbency(i) == 1
                        inc = [1;0];
                    elseif geoSen.Incumbency(i) == -1
                        inc = [0;1];
                    else
                        inc = [0;0];
                    end
                    chance = normcdf(xSen(i), 0.5, sqrt(pSen(i,i)), 1);
                    Visualization.printResults.printResult([xSen(i); 1-xSen(i)], ...
                            [chance; 1-chance], ...
                            "Senate", geoSen.Election(i), inc, [geoSen.DemCandidate(i); geoSen.RepCandidate(i)], ...
                            "dispType", "Percent");
                end
            end

            
            idxHouse = geographies.Type == "House";
            if sum(idxHouse) > 0
                geoHouse = geographies(idxHouse, :);
                xHouse = model.xGeoEst(idxHouse, end);
                pHouse = model.pGeoEst(idxHouse, idxHouse, end);
                disp(" ")
                Visualization.printResults.printResult([results.house.demAverage; results.house.repAverage], ...
                    [results.house.demPercent; results.house.repPercent], ...
                    "House", "Districts", [0;0], ["Democrats"; "Republicans"], ...
                    "dispType", "House Seats");
    
                hHouseNat = model.hMapCd(:, idxHouse).*data.TotalVote;
                hHouseNat = sum(hHouseNat, 1);
                hHouseNat = hHouseNat/sum(hHouseNat);
                xHouseNat = hHouseNat * xHouse;
                sigmaHouseNat = sqrt(hHouseNat * pHouse * hHouseNat');
                chanceHouse = normcdf(xHouseNat, 0.5, sigmaHouseNat, 1);
                Visualization.printResults.printResult([xHouseNat; 1-xHouseNat], ...
                    [chanceHouse; 1-chanceHouse], ...
                    "House", "Popular Vote", [0;0], ["Democrats"; "Republicans"], ...
                    "dispType", "Percent");
    
                for i = 1:length(xHouse)
                    if geoHouse.Incumbency(i) == 1
                        inc = [1;0];
                    elseif geoHouse.Incumbency(i) == -1
                        inc = [0;1];
                    else
                        inc = [0;0];
                    end
                    chance = normcdf(xHouse(i), 0.5, sqrt(pHouse(i,i)), 1);
                    Visualization.printResults.printResult([xHouse(i); 1-xHouse(i)], ...
                            [chance; 1-chance], ...
                            "House", geoHouse.Election(i), inc, [geoHouse.DemCandidate(i); geoHouse.RepCandidate(i)], ...
                            "dispType", "Percent");
                end
            end

            
            idxGov = geographies.Type == "Governor";
            if sum(idxGov) > 0
                disp(" ")
                geoGov = geographies(idxGov, :);
                xGov = model.xGeoEst(idxGov, end);
                pGov = model.pGeoEst(idxGov, idxGov, end);
                for i = 1:length(xGov)
                    if geoGov.Incumbency(i) == 1
                        inc = [1;0];
                    elseif geoGov.Incumbency(i) == -1
                        inc = [0;1];
                    else
                        inc = [0;0];
                    end
                    chance = normcdf(xGov(i), 0.5, sqrt(pGov(i,i)), 1);
                    Visualization.printResults.printResult([xGov(i); 1-xGov(i)], ...
                            [chance; 1-chance], ...
                            "Governor", geoGov.Election(i), inc, [geoGov.DemCandidate(i); geoGov.RepCandidate(i)], ...
                            "dispType", "Percent");
                end
            end
        end

        function printAllDistricts(model)
            arguments
                model Core.Model
            end

            xEst = model.xFinalEst(:,end);
            sigmaEst = diag(model.pFinal(:,:,end)).^0.5;
            for i = 1:size(model.hMap,2)
                geographies = model.geographies;
                if ~strcmp(geographies.Type(i), "Generic Ballot")
                    headerStr = geographies.Election(i) + " " + geographies.Type(i);
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
                    idxNum = 0;
                    idx = model.hMap(:,i) > 0;
                    for j = 1:size(model.hMapCd,1)
                        if model.hMapCd(j,i) > 0
                            idxNum = idxNum + 1;
                            xCur = xEst(idx);
                            xCur = xCur(idxNum);
                            sigmaCur = sigmaEst(idx);
                            sigmaCur = sigmaCur(idxNum);
                            headerFinal = headerStr + " " + model.cdData.CongressionalDistrict(j) + ":";
                            disp(headerFinal)
                            chance = normcdf(xCur,0.5,sigmaCur,1);
                            dStr = "    " + geographies.DemCandidate(i) + dAdd + " (D) - Estimate: " + string(round(xCur*100,2)) + "% | Chance of Winning: " + string(round(chance*100,2)) + "%";
                            rStr = "    " + geographies.RepCandidate(i) + rAdd + " (R) - Estimate: " + string(round((1-xCur)*100,2)) + "% | Chance of Winning: " + string(round((1-chance)*100,2)) + "%";
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

        function printResult(x, chance, type, election, inc, candName, args)
            arguments
                x (:,1) double
                chance (:,1) double
                type (:,1) string
                election (1,1) string
                inc (:,1) double
                candName (:,1) string
                args.party (:,1) string = ["D", "R"];
                args.dispType (1,1) string = "Percent";
            end

            headerStr = type + " - " + election + ":";
            disp(headerStr);
            [~, idx] = sort(x, "descend");
            for i = 1:length(idx)
                curIdx = idx(i);
                if inc(curIdx) == 1
                    add = "*";
                else
                    add = "";
                end

                if strcmp(args.dispType, "Percent")
                    xDisp = string(round(x(curIdx)*100,2)) + "%";
                else
                    xDisp = string(round(x(curIdx),2)) + " " + args.dispType;
                end

                dispString = "    " + candName(curIdx) + add + " (" + args.party(curIdx) + ") - Estimate: " + xDisp + " | Chance of Winning: " + string(round(chance(curIdx)*100,2)) + "%";
                disp(dispString)
            end
        end

        function tbl = saveTimeEstimate(model, election)
            C = Common.Config();
            startDate = C.startDate;

            names = model.geographies.Election;
            idx = names == election;

            timeVec = startDate + (model.time)';
            timeVec = string(timeVec);
            xEst = model.xGeoEst(idx,:)';
            sigma = sqrt(model.pGeoEst(idx,idx,:));
            sigma = sigma(:);
            dVec = string(round(xEst*100,2)) + "%";
            dLow = string(round((xEst-sigma*2)*100,2)) + "%";
            dHigh = string(round((xEst+sigma*2)*100,2)) + "%";
            dChance = string(round(normcdf(xEst,0.5,sigma)*100,2)) + "%";

            rVec = string(round(100-xEst*100,2)) + "%";
            rLow = string(round((1-xEst-sigma*2)*100,2)) + "%";
            rHigh = string(round((1-xEst+sigma*2)*100,2)) + "%";
            rChance = string(round(normcdf((1-xEst),0.5,sigma)*100,2)) + "%";

            data = [timeVec, dVec, dLow, dHigh, dChance, rVec, rLow, rHigh, rChance];
            dCand = model.geographies.DemCandidate(idx);
            rCand = model.geographies.RepCandidate(idx);
            genName = ["", " Low", " High", " "];

            tbl = array2table(data, "VariableNames", ["Date", dCand + genName, rCand + genName]);
        end
    end
end