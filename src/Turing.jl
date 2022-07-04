module Turing

using Requires, Reexport, ForwardDiff
using DistributionsAD, Bijectors, StatsFuns, SpecialFunctions
using Statistics, LinearAlgebra
using Libtask
@reexport using Distributions, MCMCChains, Libtask, AbstractMCMC, Bijectors
using Tracker: Tracker
using ConstructionBase

import AdvancedVI
import DynamicPPL: getspace, NoDist, NamedDist
import Random

const PROGRESS = Ref(true)

"""
    setprogress!(progress::Bool)

Enable progress logging in Turing if `progress` is `true`, and disable it otherwise.
"""
function setprogress!(progress::Bool)
    @info "[Turing]: progress logging is $(progress ? "enabled" : "disabled") globally"
    PROGRESS[] = progress
    AdvancedVI.turnprogress(progress)
    return progress
end

# Random probability measures.
include("stdlib/distributions.jl")
include("stdlib/RandomMeasures.jl")
include("utilities/Utilities.jl")
using .Utilities
include("essential/Essential.jl")
Base.@deprecate_binding Core Essential false
using .Essential
include("inference/Inference.jl")  # inference algorithms
using .Inference
include("variational/VariationalInference.jl")
using .Variational

# TODO: re-design `sample` interface in MCMCChains, which unify CmdStan and Turing.
#   Related: https://github.com/TuringLang/Turing.jl/issues/746
#@init @require CmdStan="593b3428-ca2f-500c-ae53-031589ec8ddd" @eval begin
#     @eval Utilities begin
#         using ..Turing.CmdStan: CmdStan, Adapt, Hmc
#         using ..Turing: HMC, HMCDA, NUTS
#         include("utilities/stan-interface.jl")
#     end
# end

@init @require DynamicHMC="bbc10e6e-7c05-544b-b16e-64fede858acb" begin
    @eval Inference begin
        import ..DynamicHMC

        if isdefined(DynamicHMC, :mcmc_with_warmup)
            include("contrib/inference/dynamichmc.jl")
        else
            error("Please update DynamicHMC, v1.x is no longer supported")
        end
    end
end

include("modes/ModeEstimation.jl")
using .ModeEstimation

@init @require Optim="429524aa-4258-5aef-a3af-852621145aeb" @eval begin
    include("modes/OptimInterface.jl")
    export optimize
end

###########
# Exports #
###########
# `using` statements for stuff to re-export
using DynamicPPL: pointwise_loglikelihoods, generated_quantities, logprior, logjoint
using StatsBase: predict

# Turing essentials - modelling macros and inference algorithms
export  @model,                 # modelling
        @varname,
        @submodel,
        DynamicPPL,

        Prior,                  # Sampling from the prior

        MH,                     # classic sampling
        RWMH,
        Emcee,
        ESS,
        Gibbs,
        GibbsConditional,

        HMC,                    # Hamiltonian-like sampling
        SGLD,
        SGHMC,
        HMCDA,
        NUTS,
        DynamicNUTS,
        ANUTS,

        PolynomialStepsize,

        IS,                     # particle-based sampling
        SMC,
        CSMC,
        PG,

        vi,                     # variational inference
        ADVI,

        sample,                 # inference
        setchunksize,
        resume,
        @logprob_str,
        @prob_str,

        auto_tune_chunk_size!,  # helper
        setadbackend,
        setadsafe,

        setprogress!,           # debugging

        Flat,
        FlatPos,
        BinomialLogit,
        BernoulliLogit,
        OrderedLogistic,
        LogPoisson,
        NamedDist,
        filldist,
        arraydist,

        predict,
        pointwise_loglikelihoods,
        elementwise_loglikelihoods,
        generated_quantities,
        logprior,
        logjoint,

        constrained_space,            # optimisation interface
        MAP,
        MLE,
        get_parameter_bounds,
        optim_objective,
        optim_function,
        optim_problem
end
