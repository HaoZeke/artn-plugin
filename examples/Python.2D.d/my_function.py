import numpy as np

class function():

    ## delta for derivatives
    _h=1e-5   ## note: going below 1e-5 can be dangerous,
              ## since at d2f we use h**2, which can be close to precision of python


    def func( self, x, y, shift=0.0 ):
        """
        An analytic 2D function with some interesting features.
        """
        # res= a1 * np.exp( -b1*( (x-x1)**2.0 + (y-y1)**2.0 )) + \
        #      a2 * np.exp( -b2*( (x-x2)**2.0 + (y-y2)**2.0 )) + \
        #      a3 * np.exp( -b3*( (x-x3)**2.0 + (y-y3)**2.0 )) + \
        #      a4 * np.exp( -b4*( (x-x4)**2.0 + (y-y4)**2.0 )) + \
        #      a5 * np.exp( -b5*( (x-x5)**2.0 + (y-y5)**2.0 )) + \
        #      a6 * np.exp( -b6*(               (y-y6)**2.0 )) + \
        #      a7 * np.exp( -b7*( (x-x7)**2.0 ))

        ## function from the SI of convex-regions paper, with multiple shoulder regions
        res = 0.5*np.cos(0.2*x*y) * np.cos(0.2*3*x) * np.cos(0.5*y) + \
              np.cos(x) * np.cos(3.0/2.0*y) + \
              np.exp(-1.0/125.0*((x-17.0)**2+(y-17.0)**2))
        return res-shift

    def df_dx( self, x, y ):
        # df/dx = f(x+h,y) - f(x-h,y) / 2h
        h=self._h
        return (self.func(x+h,y) - self.func(x-h,y))/(2.0*h)
    def df_dy( self, x, y ):
        # df/dy = f(x,y+h) - f(x,y-h) / 2h
        h=self._h
        return (self.func(x,y+h) - self.func(x,y-h))/(2.0*h)
    def grad( self, x, y ):
        # grad(f) = [ df_dx, df_dy ]
        return self.df_dx(x,y), self.df_dy(x,y)

    def d2f_dx2( self, x, y ):
        # d2f/dx2 = f(x+h,y) - 2f(x,y) + f(x-h,y) / h^2
        h=self._h
        return (self.func(x+h,y) - 2.0*self.func(x,y) + self.func(x-h,y))/(h**2)
    def d2f_dy2( self, x, y ):
        # d2f/dy2 = f(x,y+h) - 2f(x,y) + f(x,y-h) / h^2
        h=self._h
        return (self.func(x,y+h) - 2.0*self.func(x,y) + self.func(x,y-h))/(h**2)
    def d2f_dxdy( self, x, y ):
        # d2/dxdy = f(x+h,y+k) - f(x+h,y-k) - f(x-h,y+k) + f(x-h,y-k) / 4hk
        h=self._h
        xph = x+h
        xmh = x-h
        yph = y+h
        ymh = y-h
        res=(self.func(xph,yph) - self.func(xph,ymh) - \
             self.func(xmh,yph) + self.func(xmh,ymh)) / (4.0*h**2)
        return res
    def hess_eigval( self, x, y ):
        # H = (a b) = ( d2f/du2  d2f/dudv )
        #     (b c)   ( d2f/dvdu d2f/dv2  )
        a = self.d2f_dx2( x, y )
        b = self.d2f_dxdy( x, y )
        c = self.d2f_dy2( x, y )
        # trace
        T = a+c
        # determinant
        D = a*c - b*b
        # lmin=0.5*( -(a**2.0-2*a*c+4*b**2.0+c**2.0)**0.5 + a + c)
        ## eigvals
        l1 = 0.5*T - (T**2/4.0 - D)**0.5
        l2 = 0.5*T + (T**2/4.0 - D)**0.5
        return l1, l2
