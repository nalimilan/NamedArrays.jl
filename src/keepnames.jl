## index.jl  methods for NamedArray that keep the names (some checking may be done)

## (c) 2013, 2014 David A. van Leeuwen

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

# Keep names for consistently named vectors, or drop them 
function Base.hcat{T}(V::NamedVector{T}...) 
    keepnames=true
    V1=V[1]
    firstnames = names(V1,1)
    for i=2:length(V)
        keepnames &= names(V[i],1)==firstnames
    end
    a = hcat(map(a -> a.array, V)...)
    if keepnames
        colnames = [string(i) for i=1:size(a,2)]
        NamedArray(a, (firstnames, colnames), (V1.dimnames[1], "hcat"))
    else
        NamedArray(a)
    end
end

## helper function for broadcast
function verify_names(a::NamedArray...)
    nargs = length(a)
    @assert nargs>1
    bigi = indmax(map(length, a)) # find biggest dimension
    big = a[bigi]
    for i in setdiff(bigi, 1:nargs)
        println("i ", i)
        for d=1:ndims(a[i])
            println("d ", d)
            if size(a[i],d) > 1
                @assert names(big,d) == names(a(i),d)
            end
        end
    end
    return bigi::Int, big
end

## broadcast
import Base.broadcast, Base.broadcast!
function broadcast(f::Function, a::NamedArray...)
    ## verify that the names are consistent
    bigi, big = verify_names(a...)
    arrays = map(x->x.array, a)
    NamedArray(broadcast(f, arrays...), big.dicts, big.dimnames)
end

function broadcast!(f::Function, dest::NamedArray, a::NamedArray, b::NamedArray...)
    ab = tuple(a, b...)
    ## verify that the names are consistent, we assume dest is the right size
    bigi, big = verify_names(ab...)
    arrays = map(x->x.array, ab)
    broadcast!(f, dest.array, arrays...)
    dest
end

## keep names intact
for f in (:sin, :cos, :tan, :sind, :cosd, :tand, :sinpi, :cospi, :sinh, :cosh, :tanh, :asin, :acos, :atan, :asind, :acosd, :sec, :csc, :cot, :secd, :cscd, :cotd, :asec, :acsc, :asecd, :acscd, :acotd, :sech, :csch, :coth, :asinh, :acosh, :atanh, :asech, :acsch, :acoth, :sinc, :cosc, :deg2rad, :log, :log2, :log10, :log1p, :exp, :exp2, :exp10, :expm1, :iround, :iceil, :ifloor, :itrunc, :round, :abs, :abs2, :sign, :signbit, :sqrt, :isqrt, :cbrt, :erf, :erfc, :erfcx, :erfi, :dawson, :erfinv, :erfcinv, :real, :imag, :conj, :angle, :cis, :gamma, :lgamma, :digamma, :invdigamma, :trigamma, :airyai, :airyprime, :airyaiprime, :airybi, :airybiprime, :besselj0, :besselj1, :bessely0, :bessely1, :eta, :zeta)
    eval(Expr(:import, :Base, f))
    @eval ($f)(a::NamedArray) = NamedArray(($f)(a.array), a.dicts, a.dimnames)
end

## reorder names
import Base.sort
function sort(a::NamedVector)
    i = sortperm(a.array)
    return NamedArray(a.array[i], (names(a, 1)[i],), a.dimnames)
end

## drop names
function sort(a::NamedArray, dim::Integer)
    if ndims(a)==1 && dim==1
        return sort(a)
    else
        return sort(a.array, dim)
    end
end
