classdef Model
    properties
        name (1,1) string
        geographies table
        xFundEst (:,1) double
        pFund (:,:) double
        time (1,:) double
        pBiasPolling (:,:) double
        Q (:,:) double
        xFinalEst (:,1) double
        pFinal (:,:) double
        hMap (:,:) double = []
        hMapCd (:,:) logical = []
        xPolling (:,1) double
        pPolling (:,:) double
        cdData table
    end

    methods
        function obj = Model(name, geographies, corrMatrix, cdData)
            arguments
                name (1,1) string
                geographies table
                corrMatrix (:,:) double
                cdData table
            end

            C = Common.Config();

            obj.name = name;
            obj.geographies = geographies;
            obj.cdData = cdData;

            tf = days(C.electionDate - C.startDate);
            obj.time = 0:1:tf;
            
            N = length(geographies.Type);
            states = string(cdData.State);
            cd = string(cdData.CongressionalDistrict);
            for i = 1:N
                if strcmp(geographies.Geography(i), "Generic Ballot")
                    obj.xFundEst = [obj.xFundEst; geographies.Estimate(i)];
                    if ~isempty(obj.hMap)
                        obj.hMap = [obj.hMap, zeros(size(obj.hMap, 1), 1);
                            zeros(1,size(obj.hMap,2)), 1];
                    else
                        obj.hMap = 1;
                    end
                    obj.hMapCd = [obj.hMapCd, zeros(length(cd),1)];
                elseif any(geographies.Geography(i) == states)
                    mapIdx = strcmp(geographies.Geography(i), states);
                    H = cdData.TotalVote(mapIdx);
                    H = H / sum(H);
                    pvi = H' * cdData.PVI(mapIdx);
                    pviAdj = cdData.PVI(mapIdx) + geographies.Estimate(i) - pvi;
                    obj.xFundEst = [obj.xFundEst; pviAdj];
                    if ~isempty(obj.hMap)
                        obj.hMap = [obj.hMap, zeros(size(obj.hMap, 1), 1);
                            zeros(size(H,1),size(obj.hMap,2)), H];
                    else
                        obj.hMap = H;
                    end
    
                    obj.hMapCd = [obj.hMapCd, mapIdx];
                elseif any(geographies.Geography(i) == cd)
                    obj.xFundEst = [obj.xFundEst; geographies.Estimate(i)];
                    mapIdx = strcmp(geographies.Geography(i), cd);
                    obj.hMap = [obj.hMap, zeros(size(obj.hMap, 1), 1);
                       zeros(1,size(obj.hMap,2)), 1];
                    obj.hMapCd = [obj.hMapCd, mapIdx];
                end
                
            end

            obj.pFund = zeros(length(obj.xFundEst));
            obj.pBiasPolling = obj.pFund;

            sigmaStatePres = C.stateSigma(1);
            sigmaStatePresPoll = C.pollingStateSigma(1);
            deltaSigmaState = (C.stateSigma.^2 - sigmaStatePres^2).^0.5;
            deltaSigmaStatePoll = (C.pollingStateSigma.^2 - sigmaStatePresPoll.^2).^0.5;
            deltaProcessNoisePoll = C.pollingStateProcessNoise - C.pollingStateProcessNoise(1);

            for i = 1:N
                type1 = geographies.Type(i);
                idx1 = strcmp(type1, C.types);
                if strcmp(type1, "Generic Ballot")
                    idx1 = strcmp("House", C.types);
                end

                n1 = sum(obj.hMap(:,i)>0);
                vecSigmaPres1 = ones(n1,1) * sigmaStatePres;
                vecSigmaPresPoll1 = ones(n1,1) * sigmaStatePresPoll;

                if geographies.usePrevResults(i) == 1 && geographies.Incumbency(i) == geographies.PrevIncumbency(i)
                    inc1 = 0.5 * geographies.Incumbency(i);
                else
                    inc1 = geographies.Incumbency(i);
                end

                for j = 1:N
                    type2 = geographies.Type(j);
                    n2 = sum(obj.hMap(:,j)>0);
                    vecSigmaPres2 = ones(n2,1) * sigmaStatePres;
                    vecSigmaPresPoll2 = ones(n2,1) * sigmaStatePresPoll;
                    idx2 = strcmp(type2, C.types);

                    if strcmp(type1, "Generic Ballot") || strcmp(type2, "Generic Ballot")
                        rhoTemp = zeros(length(vecSigmaPres1),length(vecSigmaPres2));
                        if strcmp(type2, "Generic Ballot")
                            idx2 = strcmp("House", C.types);
                        end
                    else
                        rhoTemp = corrMatrix(obj.hMapCd(:,i),obj.hMapCd(:,j));
                    end
                    
                    if geographies.usePrevResults(j) == 1 && geographies.Incumbency(j) == geographies.PrevIncumbency(j)
                        inc2 = 0.5 * geographies.Incumbency(j);
                    else
                        inc2 = geographies.Incumbency(j);
                    end

                    % Covariance between districts
                    cov = vecSigmaPres1 * vecSigmaPres2' .* rhoTemp;
                    covPoll = vecSigmaPresPoll1 * vecSigmaPresPoll2' .* rhoTemp;
                    qTemp = C.pollingStateProcessNoise(1) * rhoTemp;

                    % Covariance from biases
                    cov = cov + C.biasSigma(idx1) * C.biasCorr(idx1, idx2) * C.biasSigma(idx2);
                    covPoll = covPoll + C.pollingBiasSigma(idx1) * C.pollBiasCorr(idx1, idx2) * C.pollingBiasSigma(idx2);
                    qTemp = qTemp + C.pollingBiasProcessNoise(idx1)^0.5 * C.pollBiasCorr(idx1,idx2) * C.pollingBiasProcessNoise(idx2)^0.5;

                    % Covariance from state/district errors
                    if strcmp(type1, type2) && strcmp(geographies.Election(i), geographies.Election(j)) && ~strcmp(type1, "Generic Ballot")
                        cov = cov + deltaSigmaState(idx1).^2;
                        covPoll = covPoll + deltaSigmaStatePoll(idx1).^2;
                        qTemp = qTemp + deltaProcessNoisePoll(idx1);
                    end

                    % Covariance from incumbency
                    cov = cov + double(inc1*inc2*C.incSigma(idx1)*C.incSigma(idx2)*C.incCorr(idx1,idx2));
                    obj.pFund(obj.hMap(:,i)>0,obj.hMap(:,j)>0) = cov;
                    obj.pBiasPolling(obj.hMap(:,i)>0,obj.hMap(:,j)>0) = covPoll;
                    obj.Q(obj.hMap(:,i)>0,obj.hMap(:,j)>0) = qTemp;
                end
            end
        end

        function obj = runPollingAverage(obj, polls)
            arguments
                obj Core.Model
                polls table
            end

            C = Common.Config();

            P = obj.pFund * 100000;
            x = obj.xFundEst;
            tRemain = 0;
            for i = 1:length(obj.time)
                if obj.time(i) > days(C.currentDate - C.startDate)
                    tRemain = days(C.electionDate - C.currentDate);
                    break
                end
                curIdx = polls.DaysFromT0 == obj.time(i);
                if any(curIdx)
                    curPolls = polls(curIdx, :);
                    z = curPolls.Result;
                    H = zeros(length(z),length(obj.xFundEst));
                    R = curPolls.Sigma' * eye(length(z)) * curPolls.Sigma;
                    for j = 1:length(z)
                        measIdx = (curPolls.Type(j) == obj.geographies.Type) & (curPolls.Election(j) == obj.geographies.Election) & (curPolls.Geography(j) == obj.geographies.Geography);
                        if any(measIdx)
                            H(j,:) = obj.hMap(:,measIdx)';
                        else
                            diffGeographyIdx = (curPolls.Type(j) == obj.geographies.Type) & (curPolls.Election(j) == obj.geographies.Election) & (curPolls.Geography(j) ~= obj.geographies.Geography);
                            geos = obj.geographies.Geography(diffGeographyIdx);
                            if strcmp(geos(1), "National")
                                newH = obj.hMap;
                                newH(:,~diffGeographyIdx) = 0;
                                newH = sum(newH,2);
                                newH = norm(newH);
                                H(j,:) = newH';
                            else
                                cdIdx = string(obj.cdData.State) == curPolls.Geography(j);
                                hCdTemp = obj.hMapCd;
                                hCdTemp(:,~diffGeographyIdx) = 0;
                                hCdTemp(~cdIdx,:) = 0;
                                idx = any(hCdTemp > 0);
                                newH = obj.hMap;
                                newH(:,~idx) = 0;
                                newH = sum(newH,2);
                                H(j,:) = newH';

                            end
                        end
                    end

                    y = z - H * x;
                    S = H * P * H' + R;
                    K = P * H' / S;
                    x = x + K * y;
                    N = length(x);
                    P = (eye(N)-K*H)*P*(eye(N)-K*H)'+K*R*K';
                end
                P = P + obj.Q;
            end

            P = P + obj.Q * tRemain + obj.pBiasPolling;

            obj.xPolling = x;
            obj.pPolling = P;
            
        end

        function [xGeoEst, pGeoEst] = runEstimate(obj)
            arguments
                obj Core.Model
            end

            N = length(obj.xFundEst);

            x = obj.xFundEst;
            P = obj.pFund;
            z = obj.xPolling;
            R = obj.pPolling;

            y = z - x;
            S = P + R;
            K = P / S;

            xFinal = x + K * y;
            PFinal = (eye(N)-K)*P*(eye(N)-K)' + K*R*K';

            obj.xFinalEst = xFinal;
            obj.pFinal = PFinal;

            xGeoEst = obj.hMap' * xFinal;
            pGeoEst = obj.hMap' * PFinal * obj.hMap;
        end
    end
end