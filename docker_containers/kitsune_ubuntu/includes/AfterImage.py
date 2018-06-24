import math
import numpy as np
import json

class incStat:
    def __init__(self, Lambda, isTypeJitter=False):  # timestamp is creation time
        self.CF1 = 0  # linear sum
        self.CF2 = 0  # sum of squares
        self.w = 0  # weight
        self.isTypeJitter = isTypeJitter
        self.Lambda = Lambda  # Decay Factor
        self.lastTimestamp = 0
        self.cur_mean = np.nan
        self.cur_var = np.nan
        self.cur_std = np.nan

    def insert(self, v, t=0):  # v is a scalar, t is v's arrival the timestamp
        if self.isTypeJitter:
            dif = t - self.lastTimestamp
            if dif > 0:
                v = dif
            else:
                v = 0
        self.processDecay(t)

        # update with v
        self.CF1 = self.CF1 + v
        self.CF2 = self.CF2 + math.pow(v, 2)
        self.w = self.w + 1
        self.cur_mean = np.nan  # force recalculation if called
        self.cur_var = np.nan
        self.cur_std = np.nan

    def processDecay(self, timestamp):
        factor=1
        # check for decay
        timeDiff = timestamp - self.lastTimestamp
        if timeDiff > 0:
            factor = math.pow(2, (-self.Lambda * timeDiff))
            self.CF1 = self.CF1 * factor
            self.CF2 = self.CF2 * factor
            self.w = self.w * factor
            self.lastTimestamp = timestamp
        return factor

    def weight(self):
        return self.w

    def mean(self):
        if math.isnan(self.cur_mean):  # calculate it only once when necessary
            self.cur_mean = self.CF1 / self.w
        return self.cur_mean

    def var(self):
        if math.isnan(self.cur_var):  # calculate it only once when necessary
            self.cur_var = abs(self.CF2 / self.w - math.pow(self.mean(), 2))
        return self.cur_var

    def std(self):
        if math.isnan(self.cur_std):  # calculate it only once when necessary
            self.cur_std = math.sqrt(self.var())
        return self.cur_std

    #calculates and pulls all stats
    def allstats(self):
        self.cur_mean = self.CF1 / self.w
        self.cur_var = abs(self.CF2 / self.w - math.pow(self.cur_mean, 2))
        return self.w, self.cur_mean, self.cur_var

    def getHeaders(self):
        return "weight", "mean", "variance"

    def toJSON(self):
        j = {}
        j['CF1'] = self.CF1
        j['CF2'] = self.CF2
        j['w'] = self.w
        j['isTypeJitter'] = self.isTypeJitter
        j['Lambda'] = self.Lambda
        j['lastTimestamp'] = self.lastTimestamp
        return json.dumps(j)

    def loadFromJSON(self,JSONstring):
        j = json.loads(JSONstring)
        self.CF1 = j['CF1']
        self.CF2 = j['CF2']
        self.w = j['w']
        self.isTypeJitter = j['isTypeJitter']
        self.Lambda = j['Lambda']
        self.lastTimestamp = j['lastTimestamp']

#like incStat, but maintains stats between two streams
class incStat_2D(incStat):
    def __init__(self, Lambda):  # timestamp is creation time
        self.CF1 = 0  # linear sum
        self.CF2 = 0  # sum of squares
        self.CF3 = None # sum of residules (A-uA)
        self.CF3_lastTimestamp = None # sum of residules (A-uA)
        self.w = 0  # weight
        self.Lambda = Lambda  # Decay Factor
        self.lastTimestamp = 0
        self.cur_mean = np.nan
        self.cur_var = np.nan
        self.cur_std = np.nan
        self.cur_cov = np.nan
        self.last_residule = 0  # the value of the last residule

    #other_incS_decay is the decay factor of the other incstat
    def insert2D(self, v, t, other_incS_lastDecayedRes):  # also updates covariance (expensive)
        self.processDecay(t)

        # update with v
        self.CF1 = self.CF1 + v
        self.CF2 = self.CF2 + math.pow(v, 2)
        self.w = self.w + 1
        self.cur_mean = np.nan  # force recalculation if called
        self.cur_var = np.nan
        self.cur_std = np.nan
        self.cur_cov = np.nan
        self.last_residule = v - self.mean()
        self.CF3[0] = self.CF3[0] + self.last_residule * other_incS_lastDecayedRes

    def processDecay(self, timestamp):
        # check for decay
        factor = 1
        factor_cf3 = 1
        timeDiff1 = timestamp - self.lastTimestamp
        timeDiff2 = self.lastTimestamp - self.CF3_lastTimestamp[0]  # dif between current time...

        if timeDiff1 > 0:
            factor = math.pow(2, (-self.Lambda * timeDiff1))
            self.CF1 = self.CF1 * factor
            self.CF2 = self.CF2 * factor
            self.w = self.w * factor
            self.last_residule = self.last_residule * factor
            if timeDiff2 == 0:  # i did the last update
                factor_cf3 = factor
            elif self.CF3_lastTimestamp[0] > timestamp:  # out of order
                factor_cf3 = 1
            else:
                factor_cf3 = math.pow(2, (-self.Lambda * (timestamp - self.CF3_lastTimestamp[0])))
            self.lastTimestamp = timestamp

        if self.CF3 == None:
            self.CF3 = [0]  # make it
        else:
            self.CF3[0] = self.CF3[0] * factor_cf3  # decay it
            if timeDiff2 > 0:  # normal (in order) timestamp
                self.CF3_lastTimestamp[0] = timestamp
        return factor

    def radius(self, istat_ref):  # the radius of two stats
        return math.sqrt(math.pow(self.var(), 2) + math.pow(istat_ref[0].var(), 2))

    def magnitude(self, istat_ref):  # the magnitude of two stats
        return math.sqrt(math.pow(self.mean(), 2) + math.pow(istat_ref[0].mean(), 2))

    #covaince approximation using a hold-and-wait model
    def cov(self,istat_ref):  # assumes that current time is the timestamp in 'self.lastTimestamp' is the current time
        if math.isnan(self.cur_cov):
            self.cur_cov = self.CF3[0] / ((self.w + istat_ref[0].w) / 2)
        return self.cur_cov

    # Pearson corl. coef (using a hold-and-wait model)
    def p_cc(self, istat_ref):  # assumes that current time is the timestamp in 'self.lastTimestamp' is the current time
        ss = self.std() * istat_ref[0].std()
        if ss != 0:
            return self.cov(istat_ref[0]) / ss
        else:
            return 0

    # calculates and pulls all stats
    def allstats2D(self, istat_ref):
        self.cur_mean = self.CF1 / self.w
        self.cur_var = abs(self.CF2 / self.w - math.pow(self.cur_mean, 2))
        self.cur_std = math.sqrt(self.cur_var)

        if istat_ref[0].w != 0:
            cov = self.CF3[0] / ((self.w + istat_ref[0].w) / 2)
            magnitude = math.sqrt(math.pow(self.cur_mean, 2) + math.pow(istat_ref[0].mean(), 2))
            radius = math.sqrt(math.pow(self.cur_var, 2) + math.pow(istat_ref[0].var(), 2))
            ss = self.cur_std * istat_ref[0].std()
            pcc = 0
            if ss != 0:
                pcc = cov / ss
        else:
            magnitude = self.cur_mean
            radius = self.cur_var
            cov = 0
            pcc = 0

        return self.w, self.cur_mean, self.cur_std, magnitude, radius, cov, pcc

    def getHeaders(self):
        return "weight", "mean", "std", "magnitude", "radius", "covariance", "pcc"


# A set of 3 incremental statistics for a 1 or 2 dimensional time-series
class windowed_incStat:
    # Each lambda in the tuple L parameter determines a incStat's decay window size (factor)
    def __init__(self, L, isTypeJitter=False):
        self.incStats = list()
        self.L = sorted(L,reverse=True) #largest lambda to smallest
        for l in self.L:
            self.incStats.append(incStat(l,isTypeJitter))

    # returns the weight, mean, and variance of each window
    def getStats(self):
        allstats = np.zeros(len(self.L)*3) #3 stats for each lambda
        for i in range(0,len(self.incStats)):
            stats = self.incStats[i].allstats()
            allstats[i*3:(i*3+3)] = stats
        return allstats

    def getHeaders(self):
        headers = []
        for i in range(0,len(self.incStats)):
            headers = headers + ["L"+str(self.L[i])+"_"+header for header in self.incStats[i].getHeaders()]
        return headers

    # updates the statistics
    # val is the new observation
    # timestamp is the arrival time of val.
    # lite only updates incrementals needed for weight, mean, variance, magnitude and radius
    def updateStats(self, val, timestamp):
        for i in range(0,len(self.incStats)):
            self.incStats[i].insert(val, timestamp)

    # First updates, then gets the stats (weight, mean, and variance only)
    def updateAndGetStats(self, val, timestamp):
        self.updateStats(val, timestamp)
        return self.getStats()

    def getMaxW(self,t):
        mx = 0
        for stat in self.incStats:
            stat.processDecay(t)
            if stat.w > mx:
                mx = stat.w
        return mx

# A set of 3 incremental statistics for a 1 or 2 dimensional time-series
class windowed_incStat_2D:
    # Each lambda parameter in L determines a incStat's decay window size (factor)
    def __init__(self, L):
        self.incStats = list()
        self.L = sorted(L,reverse=True) #largest lambda to smallest
        for l in self.L:
            self.incStats.append(incStat_2D(l))
        self.other_winStat = None  # a mutable refernece [] to the windowed_incStat monitoring the other parallel time-series

    # returns the weight, mean, variance, radius, magnitude, and covariance and pcc of each window
    def getStats(self):
        allstats = np.zeros(len(self.L)*7) #6 stats for each lambda
        for i in range(0,len(self.incStats)):
            stats = self.incStats[i].allstats2D([self.other_winStat[0].incStats[i]])
            allstats[i*7:(i*7+7)] = stats
        return allstats

    def getHeaders(self):
        headers = []
        for i in range(0,len(self.incStats)):
            headers = headers + ["L"+str(self.L[i])+"_"+header for header in self.incStats[i].getHeaders()]
        return headers

    # updates the statistics
    # val is the new observation
    def updateStats(self, val, timestamp):
        for i in range(0,len(self.incStats)):
            self.other_winStat[0].incStats[i].processDecay(timestamp) #this decays the otherIncStat's lastRes
            self.incStats[i].insert2D(val, timestamp, self.other_winStat[0].incStats[i].last_residule)

    # First updates, then gets the stats (weight, mean, variance, magnitude, radius, and covariance)
    def updateAndGetStats(self, val, timestamp):
        self.updateStats(val, timestamp)
        return self.getStats()

    # Joins two windowed_incStat (e.g. rx and tx channels) together.
    # other_winStat should be a [] mutable object
    def join_with_winStat(self, other_winStat):  # prectect with mutexes!
        self.other_winStat = other_winStat
        other_winStat[0].other_winStat = [self]
        for i in range(0,len(self.incStats)):
            self.incStats[i].CF3 = other_winStat[0].incStats[i].CF3 = [0]
            self.incStats[i].CF3_lastTimestamp = other_winStat[0].incStats[i].CF3_lastTimestamp = [0]

    def getMaxW(self,t):
        lastIncStat = len(self.incStats)
        self.incStats[lastIncStat-1].processDecay(t)
        return self.incStats[lastIncStat-1].w

class incStatHT:
    # incStatHT maintains a python dictionary object (Hash Table) filled with a collection of windowed_incStats.
    # The purpose of the incStatHT is to minimize the number of operations in incrementing and retrieving statics on time-series in an online manner.
    # Note, this library is built in a manner which assumes that the individual time sereis are NOT sampled at the same time (i.e., fused), thus each stream should be updated individually with each corresponding value.

    # The current implementation can maintain 1-dimensional or 2-dimensional time series, and monitors three windows over each time-series.
    # If 1-dimensional, set key 2 to the empty string ''.
    # If 2-dimensional, key1 should be the target stream
    # Each lambda parameter determines a incStat's decay window size (factor): 2^(-lambda*deltaT)
    def __init__(self,limit=np.Inf):
        self.HT = dict()
        self.limit = limit

    def updateGet_1D(self, key, val, timestamp, L, isTypeJitter=False):  # 1D will only maintain the mean and variance
        wis = self.HT.get(key)
        if wis is None:
            if len(self.HT) + 1 > self.limit:
                raise LookupError(
                    'Adding Entry:\n' + key + '\nwould exceed incStatHT 1D limit of '+str(self.limit)+'.\nObservation Rejected.')
            wis = [windowed_incStat(L,isTypeJitter)]
            self.HT[key] = wis
        stats = wis[0].updateAndGetStats(val, timestamp)
        return stats

    def getHeaders_1D(self,L):
        tmp_incs = windowed_incStat(L)
        return tmp_incs.getHeaders()

    #cleans out records that have a weight less than the cutoff.
    #returns number or removed records.
    def cleanOutOldRecords(self,cutoffWeight,curTime):
        n = 0
        dump = sorted(self.HT.items(), key=lambda tup: tup[1][0].getMaxW(curTime))
        for entry in dump:
            W = entry[1][0].getMaxW(curTime)
            if W <= cutoffWeight:
                key = entry[0]
                del entry[1][0]
                del self.HT[key]
                n=n+1
            elif W > cutoffWeight:
                break
        return n

class incStatHT_2D(incStatHT):
    def updateGet_2D(self, key1, key2, val, timestamp, L):  # src and dst should be strings
        key = key1 + key2
        wis = self.HT.get(key)  # get windowed incrimental stat object
        if wis is None:
            wis = self.create_2D_entry(key1, key2, L)
        elif wis[0].other_winStat == []:
            self.create_1D_entry(key1,key2,L,wis)
        stats = wis[0].updateAndGetStats(val, timestamp)
        return stats

    def create_1D_entry(self, key1, key2, L, wis):  # prectect with mutexes!
        #check limit
        if len(self.HT) + 1 > self.limit:
            raise LookupError(
                'Adding Entry:\n' + key2+key1 + '\nwould exceed incStatHT 2D limit of ' + str(
                    self.limit) + '.\nObservation Rejected.')
        #create
        wis_k2_k1 = [windowed_incStat_2D(L)]
        # connect net stats..
        wis[0].join_with_winStat(wis_k2_k1)
        # store
        self.HT[key2 + key1] = wis_k2_k1
        return wis_k2_k1

    def create_2D_entry(self, key1, key2, L):  # prectect with mutexes!
        #check limit
        if len(self.HT) + 1 > self.limit:
            raise LookupError(
                'Adding Entry:\n' + key1+key2 + '\nwould exceed incStatHT 2D limit of ' + str(
                    self.limit) + '.\nObservation Rejected.')
        # create
        wis_k1_k2 = [windowed_incStat_2D(L)]
        #store
        self.HT[key1 + key2] = wis_k1_k2

        #check if otherside exist
        wis_k2_k1 = self.HT.get(key2+key1)
        if wis_k2_k1 is None:
            # check limit
            if len(self.HT) + 1 > self.limit:
                raise LookupError(
                    'Adding Entry:\n' + key2 + key1 + '\nwould exceed incStatHT 2D limit of ' + str(
                        self.limit) + '.\nObservation Rejected.')
            wis_k2_k1 = [windowed_incStat_2D(L)]
        # connect net stats..
        wis_k1_k2[0].join_with_winStat(wis_k2_k1)
        # store
        self.HT[key2 + key1] = wis_k2_k1
        return wis_k1_k2

    def getHeaders_2D(self,L):
        tmp_incs = windowed_incStat_2D(L)
        return tmp_incs.getHeaders()

class incHist:
    #ubIsAnom means that the HBOS score for vals that fall past the upped bound are Inf (not 0)
    def __init__(self,nbins,Lambda=0,ubIsAnom=True,lbIsAnom=True,lbound=-10,ubound=10,scaleGrace=None):
        self.scaleGrace = scaleGrace #the numbe rof instances to observe until a range it determeined
        if scaleGrace is not None:
            self.lbound = np.Inf
            self.ubound = -np.Inf
            self.binSize = None
            self.isScaling = True
        else:
            self.lbound = lbound
            self.ubound = ubound
            self.binSize = (ubound - lbound)/nbins
            self.isScaling = False
        self.nbins = nbins
        self.ubIsAnom = ubIsAnom
        self.lbIsAnom = lbIsAnom
        self.n = 0

        self.Lambda = Lambda
        self.W = np.zeros(nbins)
        self.lT = np.zeros(nbins) #last timestamp of each respective bin
        self.tallestBin = 0 #indx to the bin that currently has the largest freq weight (assumed...)

    #assumes even bin width starting from lbound until ubound. beyond bounds are assigned to the closest bin
    def getBinIndx(self,val,win=0):
        indx = int(np.floor((val - self.lbound)/self.binSize))
        if win == 0:
            if indx < 0:
                return -np.Inf
            if indx > (self.nbins - 1):
                return np.Inf
            return indx
        else: #windowed Histogram
            if indx - win < 0: #does the left of the window stick out of bounds?
                if indx + win >= 0: #if yes, then is there some overlap with inbounds?
                    return range(0,indx+win+1) #return the inbounds range
                else: #then the entire window is our of bounds to the left
                    return -np.Inf
            if indx + win > self.nbins - 1: #does the right of the window stick out of bounds?
                if indx - win < self.nbins: #if yes, then is there some overlap with inbounds?
                    return range(indx - win,self.nbins) #return the inbounds range
                else: #then the entire window is our of bounds to the right
                    return np.Inf
            return range(indx-win,indx+win+1)


    def processDecay(self, bin, timestamp):
        # check for decay
        timeDiff = timestamp - self.lT[bin]
        if np.isscalar(timeDiff):
            if timeDiff > 0:
                factor = math.pow(2, (-self.Lambda * timeDiff))
                self.W[bin] = self.W[bin] * factor
                self.lT[bin] = timestamp
        else: #array
            timeDiff[timeDiff<0]=0 #don't affect decay of out of order entries
            factor = np.power(2, (-self.Lambda * timeDiff))
            #b4 = self.W[bin]
            self.W[bin] = self.W[bin] * factor
            self.lT[bin] = timestamp

    def insert(self,val,timestamp,penalty=False):
        self.n = self.n + 1
        if self.isScaling:
            if self.n < self.scaleGrace:
                if self.lbound > val:
                    self.lbound = val
                if self.ubound < val:
                    self.ubound = val
            if self.n == self.scaleGrace:
                if self.ubound == self.lbound:
                    self.scaleGrace = self.scaleGrace + 1000
                else:
                    width = self.ubound - self.lbound
                    self.ubound = self.ubound + width
                    self.lbound = self.lbound - width
                    self.binSize = (self.ubound - self.lbound) / self.nbins
                    self.isScaling = False
        else:
            bin = self.getBinIndx(val)
            if not np.isinf(bin): #
                self.processDecay(bin, timestamp)
                if penalty:
                    tallestW = self.W[self.tallestBin]
                    scale = tallestW if tallestW > 0 else 1
                    fn = self.W[bin]/scale
                    inc = self.halfsigmoid(fn+0.005,-1.03)
                else:
                    inc = 1
                self.W[bin] = self.W[bin] + inc
                #track who has the tallest bin (for normilization)
                if self.W[bin] > self.W[self.tallestBin]:
                    self.tallestBin = bin

    def halfsigmoid(self,x,k):
        return (k*x)/(k-x+1)

    def score(self,val,timestamp=-1,win=0): #HBOS for one dimension
        if self.isScaling:
            return 0.0
        else:
            bin = self.getBinIndx(val,win=win)
            if np.isscalar(bin):
                if np.isinf(bin):
                    if self.ubIsAnom and bin > 0:
                        return np.Inf #it's an anomaly because it passes the upper bound
                    elif self.lbIsAnom and bin < 0:
                        return np.Inf  # it's an anomaly because it passes the lower bound
                    else:
                        return 0.0 #it fell outside a bound which is consedered not anomalous
            self.processDecay(bin,timestamp) #if timestamp = -1, no decay will be applied
            w = np.mean(self.W[bin])
            if w == 0:
                return np.Inf  # no stat history, anomaly!
            else:
                return np.log(self.W[self.tallestBin] / (w))  # log(  1/(  p/p_max  )    )


    def getFreq(self,val,timestamp=-1): #HBOS for one dimension
        bin = self.getBinIndx(val)
        self.processDecay(bin,timestamp) #if timestamp = -1, no decay will be applied
        if np.isinf(bin):
            return np.nan
        else:
            return self.W[bin]

    def getHist(self,timestamp=-1): #HBOS for one dimension
        H = np.zeros((len(self.W),1))
        for i in range(0,len(self.W)):
            self.processDecay(i,timestamp) #if timestamp = -1, no decay will be applied
            H[i] = self.W[i]
        H = H/np.sum(self.W)
        return H

    def loadFromJSON(self,jsonstring):
        return '' # !!!! very  important: all timestamps in self.lT should be updated so the decay won't wipe out the histogram:
                # self.lT = self.lT + curtime - max(self.lT)
                # this also applies to when the system.train setting is toggled to 'on'