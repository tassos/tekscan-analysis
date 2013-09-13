%Define the polynomial that we'll use for fitting our data. The order
%of the polynomial is decided by the size of our x, which is decided by
%the input 'order' that is user defined
function F = fitFun(x)
    global xdata ydata
    resid = polyval(x,xdata) - ydata;
    F = resid.*[2;ones(size(resid,1)-1,1)];
end