import numpy as np
import pandas as pd
from scipy import stats, signal, integrate, interpolate, optimize
import matplotlib.pyplot as plt


law1 = stats.uniform(loc=0.5, scale=1.0) 
law2 = stats.norm(loc=1.0, scale=0.15)


class Logistic:
    
    _r=1.0
    _N0 = 1e3
    _K = 1e7
    
    _law = None
    _rmin = 0.0
    _rmax = 2.0
    
    @classmethod
    def defaults(cls, r=None, K=None, N0=None):
        if r is None:
            r = cls._r
        if K is None:
            K = cls._K
        if N0 is None:
            N0 = cls._N0
        return (r, K, N0)
    
    @classmethod
    def N(cls, t, r=None, K=None, N0=None):
        r, K, N0 = cls.defaults(r=r, K=K, N0=N0)
        term = np.exp(r*t)
        return cls._K*cls._N0*term/(cls._K + cls._N0*(term - 1))
    
    @classmethod
    def sample(cls, ts, size=10000, seed=846):
        np.random.seed(seed)
        rs = cls._law.rvs(size=size)
        samples = {}
        for t in ts:
            samples[t] = Logistic.N(t, rs)
        frame = pd.DataFrame(samples)
        frame["rvs"] = rs
        return frame
    
    @classmethod
    @np.vectorize
    def jacobian(cls, t=0., r=None, K=None, N0=None):
        r, K, N0 = cls.defaults(r=r, K=K, N0=N0)
        term = np.exp(r*t)
        return np.array([
            K*N0*(K-N0)*r*term,
            K*N0*(K-N0)*t*term,
            N0**2*term*(term - 1),
            K**2*term
        ])/(K + N0*(term - 1))**2
    
    @classmethod
    def dNdt(cls, t, r):
        N = cls.N(t, r)
        return signal.savgol_filter(N, 51, 7, deriv=1, delta=np.diff(t)[0])

    @classmethod
    def moment_integrand(cls, r, t, order):
        return np.power(cls.N(t, r), order)*cls._law.pdf(r)
    
    @classmethod
    @np.vectorize
    def moment(cls, t, order=1):
        value, error = integrate.quad(cls.moment_integrand, cls._rmin, cls._rmax, args=(t, order), limit=250, epsrel=5e-14)
        return (value, error)
    
    @classmethod
    def mean(cls, t):
        return cls.moment(t, order=1)

    @classmethod
    def variance(cls, t):
        mu1, error1 = cls.mean(t)
        mu2, error2 = cls.moment(t, order=2)
        var = mu2 - mu1**2
        return (var, error2)
    
    @classmethod
    def skewness(cls, t):
        mu1, error1 = cls.mean(t)
        mu2, error2 = cls.variance(t)
        mu3, error3 = cls.moment(t, order=3)
        sigma = np.sqrt(mu2)
        skew = (mu3 - 3*mu1*sigma**2 - mu1**3)/(sigma**3)
        return (skew, error3)
