#' Run named odin model
#'
#' \code{run_model} returns list with generator function automatically created given the odin model
#' specified.
#'
#' @param model Name of odin model used. Default = \code{"odin_model"}
#' @param time Integer for length of simulation in days. Default = 100
#' @param het_brackets Numeric for heterogeneity brackets
#' @param age Age vector
#' @param init_EIR Initial EIR for initial solution
#' @param init_ft Initial ft for initial solution
#' @param country Character of country in which admin unit exists
#' @param admin2 Character for admin level 2
#' @param ... Any other parameters needed for non-standard model. If they share the same name
#' as any of the defined parameters \code{model_param_list_create} will stop. You can either write
#' any extra parameters you like individually, e.g. create_r_model(extra1 = 1, extra2 = 2)
#' and these parameters will appear appended to the returned list, or you can pass explicitly
#' the ellipsis argument as a list created before, e.g. create_r_model(...=list(extra1 = 1, extra2 = 2))
#'
#' @return list of generator function, initial state, model parameters and generator
#'
#' @importFrom odin odin
#' @export

run_model <- function(model = "odin_model",
                           het_brackets = 5,
                           age = c(0,0.25,0.5,0.75,1,1.25,1.5,1.75,2,3.5,5,7.5,10,15,20,30,40,50,60,70,80),
                           init_EIR = 10,
                           init_ft = 0.4,
                           country = NULL,
                           admin2 = NULL,
                           time = 100,
                           ...){

  ## create model param list using necessary variables
  mpl <- model_param_list_create(...)

  # generate initial state variables from equilibrium solution
  state <- equilibrium_init_create(age_vector=age, EIR=init_EIR,ft=init_ft,
                                   model_param_list = mpl, het_brackets=het_brackets,
                                   country = country,
                                   admin_unit = admin2)

  # create odin generator
  generator <- switch(model,
    "odin_model" = odin_model,
    "odin_model_emanators" = odin_model_emanators,
    "odin_model_hrp2" = odin_model_hrp2,
    "odin_model_IVM_SMChet" = odin_model_IVM_SMChet,
    "odin_model_TBV" = odin_model_TBV,
    stop(sprintf("Unknown model '%s'", model)))

  # There are many parameters used that should not be passed through
  # to the model.
  state_use <- state[names(state) %in% coef(generator)$name]

  # create model with initial values
  mod <- generator(user = state_use, use_dde = TRUE)
  tt <- seq(0, time, 1)

  # run model
  mod_run <- mod$run(tt)

  # shape output
  out <- mod$transform_variables(mod_run)

  # return mod
  return(out)
}

