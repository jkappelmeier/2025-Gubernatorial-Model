classdef Model < handle
    properties
        name (1,1) string
        geographies table
        xFundEst (:,1) double
        pFund (:,:) double
        xGeoEst (:,:) double
        pGeoEst (:,:,:) double
        time (1,:) double
        pBiasPolling (:,:) double
        Q (:,:) double
        xFinalEst (:,:) double
        pFinal (:,:,:) double
        hMap (:,:) double = []
        hMapCd (:,:) logical = []
        xPolling (:,:) double
        pPolling (:,:,:) double
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
                else
                    error("Geography not found");
                end
                
            end

            obj.pFund = zeros(length(obj.xFundEst));
            obj.pBiasPolling = obj.pFund;

            types = cell(N,1);
            idxs = cell(N,1);
            vecSigmaDistricts = cell(N,1);
            vecSigmaDistrictPolls = cell(N,1);
            vecProcessNoiseDistricts = cell(N,1);
            incs = cell(N,1);

            for i = 1:N
                type = geographies.Type(i);
                types{i} = type;
                idx = strcmp(type, C.types);
                if strcmp(type, "Generic Ballot")
                    idx = strcmp("House", C.types);
                end
                idxs{i} = idx;

                n = sum(obj.hMap(:,i)>0);
                vecSigmaDistricts{i} = ones(n,1) * C.districtSigma(idx);
                vecSigmaDistrictPolls{i} = ones(n,1) * C.pollingDistrictSigma(idx);
                vecProcessNoiseDistricts{i} = ones(n,1) * C.pollingDistrictProcessNoise(idx)^0.5;

                if geographies.usePrevResults(i) == 1 && geographies.Incumbency(i) == geographies.PrevIncumbency(i)
                    incs{i} = 0.5 * geographies.Incumbency(i);
                else
                    incs{i} = geographies.Incumbency(i);
                end
            end

            for i = 1:N
                disp(string(i)+"/"+string(N))
                for j = 1:i
                    type1 = types{i};
                    type2 = types{j};
                    vecSigmaDistrict1 = vecSigmaDistricts{i};
                    vecSigmaDistrict2 = vecSigmaDistricts{j};
                    vecSigmaDistrictPoll1 = vecSigmaDistrictPolls{i};
                    vecSigmaDistrictPoll2 = vecSigmaDistrictPolls{j};
                    vecProcessNoiseDistrict1 = vecProcessNoiseDistricts{i};
                    vecProcessNoiseDistrict2 = vecProcessNoiseDistricts{j};
                    idx1 = idxs{i};
                    idx2 = idxs{j};
                    inc1 = incs{i};
                    inc2 = incs{j};

                    if strcmp(type1, "Generic Ballot") || strcmp(type2, "Generic Ballot")
                        rhoTemp = zeros(length(vecSigmaDistrict1),length(vecSigmaDistrict2));
                    else
                        rhoTemp = corrMatrix(obj.hMapCd(:,i),obj.hMapCd(:,j));
                    end

                    % Covariance between districts
                    cov = vecSigmaDistrict1 * vecSigmaDistrict2' .* rhoTemp;
                    covPoll = vecSigmaDistrictPoll1 * vecSigmaDistrictPoll2' .* rhoTemp;
                    qTemp = vecProcessNoiseDistrict1 * vecProcessNoiseDistrict2' .* rhoTemp;

                    % Covariance from biases
                    cov = cov + C.biasSigma(idx1) * C.biasCorr(idx1, idx2) * C.biasSigma(idx2);
                    covPoll = covPoll + C.pollingBiasSigma(idx1) * C.pollBiasCorr(idx1, idx2) * C.pollingBiasSigma(idx2);
                    qTemp = qTemp + C.pollingBiasProcessNoise(idx1)^0.5 * C.pollBiasCorr(idx1,idx2) * C.pollingBiasProcessNoise(idx2)^0.5;

                    % Covariance from state/district errors
                    if strcmp(geographies.Election(i), geographies.Election(j)) && strcmp(type1, type2) && ~strcmp(type1, "Generic Ballot")
                        cov = cov + C.electionSigma(idx1).^2;
                        covPoll = covPoll + C.pollingElectionSigma(idx1).^2;
                        qTemp = qTemp + C.pollingElectionProcessNoise(idx1);
                    end

                    % Covariance from incumbency
                    cov = cov + double(inc1*inc2*C.incSigma(idx1)*C.incSigma(idx2)*C.incCorr(idx1,idx2));

                    if (any(isnan(cov)))
                        a = 1;
                    end
                    obj.pFund(obj.hMap(:,i)>0,obj.hMap(:,j)>0) = cov;
                    obj.pBiasPolling(obj.hMap(:,i)>0,obj.hMap(:,j)>0) = covPoll;
                    obj.Q(obj.hMap(:,i)>0,obj.hMap(:,j)>0) = qTemp;
                end
            end
            pFundBottom = tril(obj.pFund);
            pBiasPollingBottom = tril(obj.pBiasPolling);
            qBottom = tril(obj.Q);
            obj.pFund = pFundBottom + pFundBottom' - pFundBottom .* eye(size(pFundBottom));
            obj.pBiasPolling = pBiasPollingBottom + pBiasPollingBottom' - pBiasPollingBottom .* eye(size(pBiasPollingBottom));
            obj.Q = qBottom + qBottom' - qBottom .* eye(size(qBottom));
        end

        function obj = runPollingAverage(obj, polls)
            arguments
                obj Core.Model
                polls table
            end

            C = Common.Config();

            N = length(obj.time);
            n = length(obj.xFundEst);
            obj.xPolling = zeros(n,N);
            obj.pPolling = zeros(n,n,N);
            P = obj.pFund * 100000;
            x = obj.xFundEst;
            tRemain = days(C.electionDate - C.currentDate);
            for i = 1:length(obj.time)
                curIdx = polls.DaysFromT0 == obj.time(i);
                if any(curIdx)
                    curPolls = polls(curIdx, :);
                    z = curPolls.Result;
                    H = zeros(length(z),length(obj.xFundEst));
                    R = curPolls.Sigma' * curPolls.Sigma.* eye(length(z));
                    for j = 1:length(z)
                        measIdx = (curPolls.Type(j) == obj.geographies.Type) & (curPolls.Election(j) == obj.geographies.Election) & (curPolls.Geography(j) == obj.geographies.Geography);
                        if any(measIdx)
                            H(j,:) = obj.hMap(:,measIdx)';
                        else
                            diffGeographyIdx = (curPolls.Type(j) == obj.geographies.Type) & (curPolls.Election(j) == obj.geographies.Election) & (curPolls.Geography(j) ~= obj.geographies.Geography);
%                             geos = obj.geographies.Geography(diffGeographyIdx);
                            if strcmp(curPolls.Geography(j), "National")
                                newH = obj.hMap;
                                newH(:,~diffGeographyIdx) = 0;
                                newH = sum(newH,2);
                                newH = newH / sum(newH);
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
                                H(j,:) = newH'/sum(newH);

                            end
                        end
                    end

                    y = z - H * x;
                    S = H * P * H' + R;
                    K = P * H' / S;
                    x = x + K * y;
                    P = (eye(n)-K*H)*P*(eye(n)-K*H)'+K*R*K';
                end
                P = P + obj.Q;
                tRemainCur = tRemain + N-i;
                obj.xPolling(:,i) = x;
                obj.pPolling(:,:,i) = P + tRemainCur * obj.Q + obj.pBiasPolling;
            end
            
        end

        function [xGeoEst, pGeoEst] = runEstimate(obj)
            arguments
                obj Core.Model
            end

            n = length(obj.xFundEst);
            N = length(obj.time);

            x = obj.xFundEst;
            P = obj.pFund;

            for i = 1:N
                z = obj.xPolling(:,i);
                R = obj.pPolling(:,:,i);
    
                y = z - x;
                S = P + R;
                K = P / S;
    
                xFinal = x + K * y;
                PFinal = (eye(n)-K)*P*(eye(n)-K)' + K*R*K';
                PFinal = (PFinal + PFinal')/2;
    
                idxNoDCand = obj.geographies.DemCandidate == "No Candidate";
                idxNoRCand = obj.geographies.RepCandidate == "No Candidate";
                idxNoDCand = (obj.hMap * idxNoDCand) > 0;
                idxNoRCand = (obj.hMap * idxNoRCand) > 0;
                xFinal(idxNoDCand) = 0;
                xFinal(idxNoRCand) = 1;

                obj.xFinalEst(:,i) = xFinal;
                obj.pFinal(:,:,i) = PFinal;

                xGeoEst = obj.hMap' * xFinal;
                pGeoEst = obj.hMap' * PFinal * obj.hMap;
    
                obj.xGeoEst(:,i) = xGeoEst;
                obj.pGeoEst(:,:,i) = pGeoEst;
            end

            
        end
    end
end