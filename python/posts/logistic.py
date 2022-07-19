import numpy as np
import pandas as pd
from scipy import stats, signal, integrate, interpolate, optimize
import matplotlib.pyplot as plt


law1 = stats.uniform(loc=0.5, scale=1.0) 
law2 = stats.norm(loc=1.0, scale=0.15)
law3 = stats.truncnorm(-2, 2.0, loc=1.0, scale=0.15)    


class Logistic:
    
    _r=1.0
    _N0 = 1e3
    _K = 1e7
    
    _law = law2
    _rmin = 0.0 #_law.support()[0]
    _rmax = 2.0 #_law.support()[1]
    
    @staticmethod
    def N(t, r=_r, N0=_N0, K=_K):
        term = np.exp(r*t)
        return K*N0*term/(K + N0*(term - 1))
    
    @staticmethod
    def sample(ts, N0=_N0, K=_K, law=_law, size=10000):
        rs = law.rvs(size=size)
        samples = {}
        for t in ts:
            samples[t] = Logistic.N(t, r=rs, N0=N0, K=K)
        return pd.DataFrame(samples)
        
    
    @staticmethod
    def dNdt(t, r=_r, N0=_N0, K=_K):
        N = Logistic.N(t, r=r, N0=N0, K=K)
        return signal.savgol_filter(N, 51, 7, deriv=1, delta=np.diff(t)[0])

    @staticmethod
    def moment_integrand(r, t, order, N0=_N0, K=_K, law=_law):
        return np.power(Logistic.N(t, r=r, N0=N0, K=K), order)*law.pdf(r)
    
    @staticmethod
    @np.vectorize
    def moment(t, N0=_N0, K=_K, order=1, law=_law, rmin=_rmin, rmax=_rmax):
        # Numerical Stability is key in this application
        value, error = integrate.quad(Logistic.moment_integrand, rmin, rmax, args=(t, order, N0, K, law), limit=250, epsrel=5e-14)
        return (value, error)
    
    @staticmethod
    def mean(t, N0=_N0, K=_K, law=_law, rmin=_rmin, rmax=_rmax):
        return Logistic.moment(t, N0=N0, K=K, order=1, law=law, rmin=rmin, rmax=rmax)

    @staticmethod
    def variance(t, N0=_N0, K=_K, law=_law, rmin=_rmin, rmax=_rmax):
        mu1, error1 = Logistic.mean(t, N0=N0, K=K, law=law, rmin=rmin, rmax=rmax)
        mu2, error2 = Logistic.moment(t, N0=N0, K=K, order=2, law=law, rmin=rmin, rmax=rmax)
        var = mu2 - mu1**2
        var[np.isclose(var, 0.)] = 0.
        #var[var<0.] = 0.
        return (var, error2)
    
    @staticmethod
    def skewness(t, N0=_N0, K=_K, law=_law, rmin=_rmin, rmax=_rmax):
        mu1, error1 = Logistic.mean(t, N0=N0, K=K, law=law, rmin=rmin, rmax=rmax)
        mu2, error2 = Logistic.variance(t, N0=N0, K=K, law=law, rmin=rmin, rmax=rmax)
        mu3, error3 = Logistic.moment(t, N0=N0, K=K, order=3, law=law, rmin=rmin, rmax=rmax)
        sigma = np.sqrt(mu2)
        skew = (mu3 - 3*mu1*sigma**2 - mu1**3)/(sigma**3)
        return (skew, error3)

