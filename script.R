library(tidyverse)
library(rstanarm)
library(loo)
options(mc.cores = parallel::detectCores())

load("data/df_raw.rda")  # load raw data frame df
set.seed(2405)

##########################################################################################################
#### Some preprocessing
## removing NA values
df <- df %>% 
  filter(gesamtwohnflaeche > 0) %>%
  mutate_at(c("herstellung", "grundstueckskaufpreis", 
              "kaufpreis", "modernisierung"), funs(replace(., is.na(.), 0))) %>%
  mutate(gesamt_kaufpreis = herstellung + grundstueckskaufpreis + kaufpreis + modernisierung,
         qm_preis =  gesamt_kaufpreis / gesamtwohnflaeche)

#######################################################
### filter out test case: 
## removing all properties that have as address the old or new company's address
df <- df %>%
  filter(strasse != "Klosterstraße" &
           !str_detect(produktanbieterid, "MUSTER") &
           !(hausnummer==71 & plz=="10179") &
           !(hausnummer == 77 & plz == "10247"))

########################################################
#### filter out extreme outlier cases

df.m  <- df %>%
  filter(grundstuecksgroesse < 5e4 &
           gesamtwohnflaeche < 500 &
           gesamt_kaufpreis < 3e6  )


#########################################################
#### last preprocessing: scaling

df.model <- df.m %>% 
  select(gesamtwohnflaeche,  gesamt_kaufpreis, plz) %>%
  rename(area = gesamtwohnflaeche, price = gesamt_kaufpreis) %>%
  mutate(area.s = as.numeric(scale(area, scale=T)),
         price.s = price / 100000) %>%
  as.tibble



##########################################################################################################
### run the models
mod_base <-   stan_lmer( price.s ~  area.s + 
                           (1 + area.s | plz)  ,
                         data=df.model,
                         prior_intercept=normal(location=3, scale=3, autoscale = F),
                         prior=normal(location=0, scale=2.5, autoscale=F)) 


mod_base_default_prior <-   stan_lmer( price.s ~  area.s + (1 + area.s | plz)  ,
                    data=df.model)

mod_simple <- stan_glm( price.s ~  area.s   ,
                        data=df.model)

weakly_informed_prior_fit  <- stan_glm( price.s ~ area.s,
                                        prior_PD = TRUE,
                                        data=df.model)

informed_prior_fit <- stan_glm( price.s ~ area.s,
                                prior_PD = TRUE,
                                prior_intercept = normal(location=3, scale=3, autoscale=F),
                                prior=normal(location=0, scale=2.5, autoscale=F),
                                data=df.model)


######################################
## compute loo values

l_simple <- loo(mod_simple)
l_base <- loo(mod_base)

## compute waic
w_simple <- waic(mod_simple)
w_base <- waic(mod_base)

## compute kfold
k_simple <- kfold(mod_simple, K=10)
folds_plz <- kfold_split_stratified(K=10, x=df.model$plz)
k_base <- kfold(mod_base, K=10, folds=folds_plz)


##########################################################################################################
## save everything
save(mod_base_default_prior, file="data/mod_base_default_prior.rda")
save(mod_simple, file="data/mod_simple.rda")
save(weakly_informed_prior_fit, file="data/weakly_informed_prior.rda")
save(informed_prior_fit, file="data/informed_prior.rda")
save(mod_base, file="data/mod_base.rda")
save(l_simple, file="data/loo_simple.rda")
save(l_base, file="data/loo_base.rda")
save(k_simple, file="data/kfold_simple.rda")
save(k_base, file="data/kfold_base.rda")
save(w_simple, file="data/waic_simple.rda")
save(w_base, file="data/waic_base.rda")
save(df.model, file="data/df_model.rda")