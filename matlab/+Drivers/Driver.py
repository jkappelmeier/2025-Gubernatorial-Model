import sys
sys.path.append('../')
import Governor.Geographies.GovernorNational as GovernorNational
import House.HouseModel as HouseModel
import House.LoadData as LoadData
import datetime
import Config as C
import csv



# Create National object
nat = GovernorNational.GovernorNational('GovernorNational', C.incAvg, C.incSigma)

# Add District objects
nat.addChildren(LoadData.congressionalDistricts)

# Assign to Model
house = HouseModel.HouseModel('House Model', nat, LoadData.cor)


# Add polls
house.addPolls(LoadData.polls)



# Run simulation
[incAvg, chalAvg, winRate, lossRate, tippingPoint, simDistrictVote] = house.runSimulation(10000)

print('')
print('House Seats:')
print('    Democrats - Average: ' + str(round(incAvg, 2)) + ' House Seats | Chance of winning: ' + str(round(winRate * 100, 2)) + '%')
print('    Republicans - Average: ' + str(round(chalAvg, 2)) + ' House Seats | Chance of winning: ' + str(round(lossRate * 100, 2)) + '%')
print('')
for i in range(len(house.stateGeographies)):
    print(str(house.stateGeographies[i].name) + ' (' +str(round(tippingPoint[i]*100,2))+'% Tipping Point Chance):')
    if house.allGeographies[i + 1].gopName == 'No Candidate':
        est = 1
        probWin = 1
    elif house.allGeographies[i + 1].demName == 'No Candidate':
        est = 0
        probWin = 0
    else:
        est = house.allGeographies[i + 1].est
        probWin = house.allGeographies[i + 1].probWin
    if house.allGeographies[i + 1].est > 0.5:
        print('    ' + str(house.stateGeographies[i].demName) + ' - Estimate: ' + str(round(est * 100, 2)) + '% | Chance of winning: ' + str(round(probWin * 100, 2)) + '%')
        if est < 1:
            print('    ' + str(house.stateGeographies[i].gopName) + ' - Estimate: ' + str(round((1 - est) * 100, 2)) + '% | Chance of winning: ' + str(round((1 - probWin) * 100, 2)) + '%')
    else:
        print('    ' + str(house.stateGeographies[i].gopName) + ' - Estimate: ' + str(round((1 - est) * 100, 2)) + '% | Chance of winning: ' + str(round((1 - probWin) * 100, 2)) + '%')
        if est > 0:
            print('    ' + str(house.stateGeographies[i].demName) + ' - Estimate: ' + str(round(est * 100, 2)) + '% | Chance of winning: ' + str(round(probWin * 100, 2)) + '%')
    print('')
