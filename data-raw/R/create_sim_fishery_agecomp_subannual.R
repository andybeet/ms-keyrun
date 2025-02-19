#' Read in fishery data save as rda
#' 
#' atlantosom output is accessed and fishery catch numbers at true age
#' pulled for each output timestep
#' 
#'@param atlmod configuration file specifying Atlantis simulation model filenames 
#'and locations  
#'@param saveToData Boolean. Export to data folder (Default = T)
#'
#'@return A tibble (Also written to \code{data} folder)
#'\item{ModSim}{Atlantis model name and simulation id}
#'\item{year}{year simulated fishery conducted}
#'\item{fishMonth}{month simulated fishery conducted}
#'\item{Code}{Atlantis model three letter code for functional group}
#'\item{Name}{Atlantis model common name for functional group}
#'\item{fishery}{simulated fishery name}
#'\item{age}{annual age of Atlantis functional group}
#'\item{variable}{number at age (Natage)}
#'\item{value}{value of the variable}
#'\item{units}{units of the variable}
#'

library(magrittr)

create_sim_fishery_agecomp_subannual <- function(atlmod,fitstart=NULL,fitend=NULL,saveToData=T) {

  # input is path to model config file for atlantisom
  source(atlmod)
  
  # path for survey and fishery config files
  cfgpath <- stringr::str_extract(atlmod, ".*config")
  
  #works because atlantis directory named for model and simulation
  modpath <- stringr::str_split(d.name, "/", simplify = TRUE)
  modsim <- modpath[length(modpath)]
  
  #read in fishery annual age comp data
  fish_annage_comp <- atlantisom::read_savedfisheries(d.name, 'catchAnnAge')
  
  # get config files -- needed?
  fvcon <- list.files(path=cfgpath, pattern = "*fishery*", full.names = TRUE)
  
  # read true list with run and biol pars, etc
  omlist_ss <- readRDS(file.path(d.name, paste0(scenario.name, "omlist_ss.rds")))
  
  # model timesteps, etc from omdimensions script
  source(paste0(cfgpath,"/omdimensions.R"), local = TRUE)
  
  #Number of years
  nyears <- omlist_ss$runpar$nyears
  total_sample <- omlist_ss$runpar$tstop/omlist_ss$runpar$outputstep
  
  # user specified fit start and times if different from full run
  fitstartyr <- ifelse(!is.null(fitstart), fitstart-1, 0)
  fitendyr <- ifelse(!is.null(fitend), fitend, total_sample)
  
  # throw an error if fstepperyr is not equal to stepperyr
  if(stepperyr != fstepperyr) stop("Error: check Atlantis timestep output for fishery")
  
  atlantis_full <- c(1:total_sample)  
  mod_burnin <- fitstartyr*stepperyr+1
  fit_nyears <- fitendyr-fitstartyr
  fit_ntimes <- fit_nyears*stepperyr
  fittimes <- atlantis_full[mod_burnin:(mod_burnin+fit_ntimes-1)]
  #fit_timesteps <- seq(fittimes[stepperyr], max(fittimes), by=stepperyr) #last timestep
  #fit_years <- unique(floor(fittimes/stepperyr)) #from Christine's new sardine_config.R
  fittimes.days <- if(omlist_ss$runpar$outputstepunit=="days") fittimes*omlist_ss$runpar$outputstep
  
  # # fishery cv lookup from config files
  # fcvlook <- tibble::tibble()
  # for(c in 1:length(fishcon)){
  #   source(fishcon[c], local = TRUE)
  #   fish_cv_n <- fish_cv %>%
  #     dplyr::mutate(fishery=fishery.name)
  #   fcvlook <- dplyr::bind_rows(fcvlook, fish_cv_n)
  # }
  
  allfishage <- tibble::tibble()
  
  #multiple surveys named in list object
  for(f in names(fish_annage_comp)){
    #arrange into wide format: year, Species1, Species2 ... and write csv
    fishage <- fish_annage_comp[[f]][[1]] %>%
      dplyr::filter(time %in% fittimes) %>%
      dplyr::mutate(year = ceiling(time/stepperyr),
                    fishMonth = 12 + ceiling(time/stepperyr*12) - year*12) %>%
      dplyr::select(species, year, fishMonth, agecl, Natage = atoutput) %>%
      #dplyr::group_by(species, year, agecl) %>%
      #dplyr::summarise(Natage = sum(atoutput)) %>%
      #dplyr::ungroup() %>%
      dplyr::left_join(dplyr::select(omlist_ss$funct.group_ss, Code, Name), by = c("species" = "Name")) %>%
      dplyr::mutate(ModSim = modsim) %>%
      dplyr::mutate(fishery = f) %>%
      #dplyr::left_join(svcvlook) %>%
      dplyr::select(ModSim, year, fishMonth, Code, Name=species, fishery, age=agecl, everything()) %>%
      tidyr::pivot_longer(cols = c("Natage"), 
                          names_to = "variable",
                          values_to = "value") %>%
      dplyr::mutate(units = ifelse(variable=="Natage", "number", "NA")) %>%
      dplyr::arrange(Name, fishery, variable, year, fishMonth, age)
    
    allfishage <- dplyr::bind_rows(allfishage, fishage)
  }
  
  simFisheryAgecompSubannual <- allfishage
  
  if (saveToData) {
  
    usethis::use_data(simFisheryAgecompSubannual, overwrite = TRUE)
  }
  
  return(simFisheryAgecompSubannual)
  
  
}
