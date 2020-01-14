import itertools
import numpy as np


class Card:
    
    def __init__(self, numbers, name=None, joker=0):
        x = np.array(numbers)
        assert x.size == 24
        assert np.all(x[:-1] <= x[1:])
        assert all([np.issubdtype(k, np.integer) for k in x])
        self._numbers = tuple(x)
        self._name = name
        self._joker = joker
        self._matrix = None
    
    def __str__(self):
        return "<Card:'{}' {}>".format(self._name, self.numbers)
    
    def __repr__(self):
        return str(self)
    
    @property
    def numbers(self):
        return self._numbers
    
    @property
    def values(self):
        return np.array(self.numbers)
    
    def spacer(self, numbers):
        return list(numbers[:12]) + [self._joker] + list(numbers[12:])

    @property
    def matrix(self):
        if self._matrix is None:
            self._matrix = np.array(self.spacer(self.numbers)).reshape((5,5)).T
        return self._matrix
    
    def rows(self, tagged=True, creator=tuple):
        if tagged:
            return {"{}.R{}".format(self._name, k): creator(self.matrix[k, :]) for k in [0,1,3,4]}
        else:
            return tuple([creator(self.matrix[k, :]) for k in [0,1,3,4]])
    
    def columns(self, tagged=True, creator=tuple):
        if tagged:
            return {"{}.C{}".format(self._name, k): creator(self.matrix[:, k]) for k in [0,1,3,4]}
        else:
            return tuple([creator(self.matrix[k, :]) for k in [0,1,3,4]])
        
    def specials(self, tagged=True, creator=tuple):
        labels = ["D0", "D1", "R2", "C2"]
        sols = [
            np.diag(self.matrix),
            np.array(list(reversed(np.diag(np.fliplr(self.matrix))))),
            self.matrix[2,:],
            self.matrix[:,2],
        ]
        if tagged:
            return {"{}.{}".format(self._name, k): creator(sols[i]) for i,k in enumerate(labels) }
        else:
            return tuple([creator(sol) for sol in sols])

    def solutions(self, tagged=True, creator=tuple):
        if tagged:
            sols = dict()
            sols.update(self.rows(creator=creator))
            sols.update(self.columns(creator=creator))
            sols.update(self.specials(creator=creator))
            return sols
        else:
            sols = []
            sols.extend(self.rows(tagged=False, creator=creator))
            sols.extend(self.columns(tagged=False, creator=creator))
            sols.extend(self.specials(tagged=False, creator=creator))
            return tuple(sols)
        
    def mark(self, numbers=[]):
        m = self.matrix.copy()
        for i in numbers:
            c = np.where(m == i)
            if c[0].size > 0:
                m[c[0][0],c[1][0]] = 0
        return m
    
    def check(self, numbers=[], m=None):
        if m is None:
            m = self.mark(numbers=numbers)
        sols = []
        for k in range(5):
            col = np.sum(m[:,k]==self._joker)
            row = np.sum(m[k,:]==self._joker)
            if (col == 5):
                sols.append("{}.C{}".format(self._name, k))
            if (row == 5):
                sols.append("{}.R{}".format(self._name, k))
        d0 = np.sum(np.array([m[k,k] for k in range(5)])==self._joker)
        d1 = np.sum(np.array([m[k,5-k-1] for k in range(5)])==self._joker)
        if (d0 == 5):
            sols.append("{}.D0".format(self._name))
        if (d1 == 5):
            sols.append("{}.D1".format(self._name))
        return {"solutions": tuple(sols), "marked": np.sum(m==self._joker)-1}

        
class Bingo:
    
    def __init__(self, config, nmin=1, nmax=75):
        assert isinstance(config, dict)
        self._config = {k: Card(v, name=k) for (k, v) in config.items()}
        self._numbers = set(range(nmin, nmax + 1))
    
    def __str__(self):
        return "<Bingo:{}-{}, {} Card(s)>".format(min(self.numbers), max(self.numbers), len(self.cards))
    
    def __repr__(self):
        return str(self)
    
    @property
    def cards(self):
        return self._config
        
    @property
    def numbers(self):
        return self._numbers
    
    def draw(self, n=30, numbers=None, creator=tuple):
        if numbers is None:
            numbers = self.numbers
        return creator(np.random.choice(list(numbers), size=n, replace=False))
    
    def check(self, numbers):
        return {k: self.cards[k].check(numbers) for k in self.cards}

    def card_product(self, n=2):
        for (a, b) in itertools.product(self.cards, repeat=n):
            yield (self.cards[a], self.cards[b])
    
    def card_permutations(self, n=2):
        for (a, b) in itertools.permutations(self.cards, n):
            yield (self.cards[a], self.cards[b])
            
    def card_combinations(self, n=2):
        for (a, b) in itertools.combinations(self.cards, n):
            yield (self.cards[a], self.cards[b])
    
    def solution_combprod(self):
        for (a, b) in self.card_combinations():
            sas = a.solutions()
            sbs = b.solutions()
            for (sa, sb) in itertools.product(sas, sbs):
                xa = set(sas[sa])
                xb = set(sbs[sb])
                yield {
                    "solutions": {sa: sas[sa], sb: sbs[sb]},
                    "equals": xa == xb,
                    "intersection": xa.intersection(xb),
                    "union": xa.union(xb),
                }



