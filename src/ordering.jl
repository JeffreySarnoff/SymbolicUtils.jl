# A total ordering

<ₑ(a::Real,    b::Real) = abs(a) < abs(b)
<ₑ(a::Complex, b::Complex) = (abs(real(a)), abs(imag(a))) < (abs(real(b)), abs(imag(b)))
<ₑ(a::Real,    b::Complex) = true
<ₑ(a::Complex, b::Real) = false

<ₑ(a::Symbolic, b::Number) = false
<ₑ(a::Number,   b::Symbolic) = true

arglength(a) = length(arguments(a))
function <ₑ(a, b)
    if !istree(a) && !istree(b)
        T = typeof(a)
        S = typeof(b)
        return T===S ? isless(a, b) : nameof(T) < nameof(S)
    elseif istree(b) && !istree(a)
        return true
    elseif istree(a) && istree(b)
        return cmp_term_term(a,b)
    else
        return !(b <ₑ a)
    end
end

<ₑ(a::Symbolic, b::Sym) = !(b <ₑ a)

function <ₑ(a::Symbol, b::Symbol)
    # Enforce the order [+,-,\,/,^,*]
    if b === :*
        a in (:^, :/, :\, :-, :+)
    elseif b === :^
        a in (:/, :\, :-, :+) && return true
    elseif b === :/
        a in (:\, :-, :+) && return true
    elseif b === :\
        a in (:-, :+) && return true
    elseif b === :-
        a === :+ && return true
    elseif a in (:*, :^, :/, :-, :+)
        false
    else
        a < b
    end
end

<ₑ(a::Sym, b::Sym) = a.name < b.name

function cmp_term_term(a, b)
    la = arglength(a)
    lb = arglength(b)

    if la == 0 && lb == 0
        return nameof(operation(a)) <ₑ nameof(operation(b))
    elseif la === 0
        return operation(a) <ₑ b
    elseif lb === 0
        return a <ₑ operation(b)
    end

    na = nameof(operation(a))
    nb = nameof(operation(b))

    if 0 < arglength(a) <= 2 && 0 < arglength(b) <= 2
        # e.g. a < sin(a) < b ^ 2 < b
        @goto compare_args
    end

    if na !== nb
        return na <ₑ nb
    elseif arglength(a) != arglength(b)
        return arglength(a) < arglength(b)
    else
        @label compare_args
        aa, ab = arguments(a), arguments(b)
        if length(aa) !== length(ab)
            return length(aa) < length(ab)
        else
            terms = zip(Iterators.filter(!is_literal_number, aa), Iterators.filter(!is_literal_number, ab))

            for (x,y) in terms
                if x <ₑ y
                    return true
                elseif y <ₑ x
                    return false
                end
            end

            # compare the numbers
            nums = zip(Iterators.filter(is_literal_number, aa),
                       Iterators.filter(is_literal_number, ab))

            for (x,y) in nums
                if x <ₑ y
                    return true
                elseif y <ₑ x
                    return false
                end
            end

        end
        return na <ₑ nb # all args are equal, compare the name
    end
end

