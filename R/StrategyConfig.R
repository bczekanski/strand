StrategyConfig <-  R6Class(
  "StrategyConfig",
  public = list(
    config = list(),
    
    initialize = function(config) {
      
      # TODO consider alternative mechanism for defaults
      if (is.null(config$solver)) {
        config$solver <- "glpk"
      }
      
      if (is.null(config$vol_var)) {
        config$vol_var <- "average_volume"
      }
      
      if (is.null(config$price_var)) {
        config$price_var <- "ref_price"
      }
      
      self$config <- config

      self$valid()
      invisible(self)
    },
    
    getStrategyNames = function() {
      setdiff(names(self$config$strategies), "joint")
    },
    
    getConfig = function(name) {
      config_val <- self$config[[name]]
      if (length(config_val) %in% 0) {
        return(NULL)
      }
      
      config_val
    },
    
    getStrategyConfig = function(strategy, name) {
      
      config_val <- self$config$strategies[[strategy]][[name]]
      if (length(config_val) %in% 0) {
        return(NULL)  
      }
      
      if (!name %in% c("in_var", "constraints")) {
        config_val <- as.numeric(config_val)
      }
      
      config_val
    },
      
    valid = function() {
      
      # Need to move to a schema definition for enforcing yaml config file
      # structure.
      
      # Check top-level config items
      top_level_required <-
        c("vol_var",
          "price_var",
          "solver")
        
      for (name in top_level_required) {
        if (is.null(self$getConfig(name))) {
          stop(paste0("Missing top-level setting: ", name))
        }
      }
      
      # Check strategy-level config items
      if (length(self$getStrategyNames()) %in% 0) {
        stop("No strategies found in config")
      }
      
      for (strategy in self$getStrategyNames()) {
        
        required_config_vars <- c("strategy_capital",
                                  "position_limit_pct_adv",
                                  "position_limit_pct_lmv",
                                  "position_limit_pct_smv",
                                  "trading_limit_pct_adv",
                                  "ideal_long_weight",
                                  "ideal_short_weight"
                                  )
        
        for (config_var in required_config_vars) {
          if (is.null(self$getStrategyConfig(strategy, config_var))) {
            stop(paste0("Missing ", config_var, " setting in strategy config for strategy: ", strategy))
          }
        }
        
        # Checks on constraint entries
        constraint_config <- self$getStrategyConfig(strategy, "constraints")
        for (constraint_name in names(constraint_config)) {
          in_var <- constraint_config[[constraint_name]]$in_var
          if (is.null(in_var) || length(in_var) %in% 0) {
            stop(paste0("Missing in_var value for constraint: ", constraint_name))
          }
          constraint_type <- constraint_config[[constraint_name]]$type
          if (is.null(constraint_type) || length(constraint_type) %in% 0) {
            stop(paste0("Missing constraint_type value for constraint: ", constraint_name))
          }
          if (!constraint_type %in% c("factor", "category")) {
            stop(paste0("Invalid constraint type of constraint: ", constraint_name))
          }
        }
      }
      
      TRUE
    }
  ))