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
            return {"{}.R{}".format(self._name[0], k): creator(self.matrix[k, :]) for k in [0,1,3,4]}
        else:
            return tuple([creator(self.matrix[k, :]) for k in [0,1,3,4]])
    
    def columns(self, tagged=True, creator=tuple):
        if tagged:
            return {"{}.C{}".format(self._name[0], k): creator(self.matrix[:, k]) for k in [0,1,3,4]}
        else:
            return tuple([creator(self.matrix[k, :]) for k in [0,1,3,4]])
        
    def specials(self, tagged=True, creator=tuple):
        labels = ["D1S", "D2S", "R2S", "C2S"]
        sols = [
            np.diag(self.matrix),
            np.array(list(reversed(np.diag(np.fliplr(self.matrix))))),
            self.matrix[2,:],
            self.matrix[:,2],
        ]
        if tagged:
            return {"{}.{}".format(self._name[0], k): creator(sols[i]) for i,k in enumerate(labels) }
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

        
class Bingo:
    
    def __init__(self, config, nmin=1, nmax=75):
        assert isinstance(config, dict)
        self._config = {k: Card(v, name=k) for (k, v) in config.items()}
        self._numbers = set(range(nmin, nmax + 1))
    
    def __str__(self):
        return "<Bingo {}>".format(list(self.cards))
    
    def __repr__(self):
        return str(self)
    
    @property
    def cards(self):
        return self._config
        
    @property
    def numbers(self):
        return self._numbers