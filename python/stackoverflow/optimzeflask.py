from http import HTTPStatus

import numpy as np
from scipy import stats, optimize

from flask import Flask
from flask_restful import Resource, Api, reqparse

app = Flask(__name__)
api = Api(app)


class OptimizeStdDev(Resource):

    @staticmethod
    def solve(spread, expected, stddev):
        """Solve a specific problem (staticmethod are stateless)"""
        spread = np.array(spread)
        expected = np.array(expected)
        def mse(s):
            estimated = stats.norm.sf(0.5, spread, scale=s)
            mse = np.sum(np.power((estimated - expected), 2))/spread.size
            return mse
        optsol = optimize.minimize(mse, stddev, method='BFGS')
        return optsol
        
    def post(self):
        """Bind optimizer to POST endpoint"""
        parser = reqparse.RequestParser()
        parser.add_argument('spread', action='append', type=float, required=True)
        parser.add_argument('expected', action='append', type=float, required=True)
        parser.add_argument('stddev', type=float, required=True)
        args = parser.parse_args()
        opt = OptimizeStdDev.solve(**args)
        # Convert OptimizeResult as a JSON serializable object:
        res = {k: v.tolist() if isinstance(v, np.ndarray) else v for k, v in opt.items()}
        return res, HTTPStatus.OK
    
api.add_resource(OptimizeStdDev, '/minimize')

def main():
    app.run(debug=True)

if __name__ == "__main__":
    main()

