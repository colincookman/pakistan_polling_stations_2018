library(tidyverse)
library(haven)

f45_files <- list.files(
  "source_data/rcons_data",
  pattern = "45",
  recursive = TRUE,
  full.names = TRUE
)

f45_df <- map_dfr(
  f45_files,
  ~ {
    read_dta(.x) %>%
      mutate_at(
        vars(contains("_turnout"), contains("total_votes")),
        funs(as.numeric(gsub("\\+", "", .)))
      ) %>%
      mutate(file = gsub("source_data/rcons_data/", "", .x))
  }
)

filter(f45_df, constituency_id == "NA13" & ps_id == 140) %>% as.data.frame
f45_w_dupes <- f45_df %>%
  group_by(constituency_id, ps_id) %>%
  mutate_at(vars(-file, -province), funs(unique = length(unique(.))))


f45_no_dupes <- filter_at(f45_w_dupes, vars(ends_with("_unique")), all_vars(all(. == 1))) %>%
  select(-file, -province) %>%
  # Those with all unique = 1 can be compressed!
  summarize_all(unique)
  
f45_pick_dupes <- f45_w_dupes %>%
  filter_at(vars(ends_with("_unique")), any_vars(any(. > 1))) %>%
  filter(grepl("Punjab", file))

f45_cleaned <- bind_rows(f45_no_dupes, f45_pick_dupes) %>%
  select(-ends_with("_unique"))

table(duplicated(select(f45_cleaned, ends_with("_id"))))

f28_files <- list.files(
  "source_data/rcons_data",
  pattern = "Polling_Station_List|28",
  recursive = TRUE,
  full.names = TRUE
)
f28_df <- map_dfr(
  f28_files,
  ~ {
    read_dta(.x) %>% 
      mutate_at(
        vars(starts_with("block_code")), funs(gsub("null", NA, as.character(.)))
      ) %>%
      mutate(male_voters = as.numeric(gsub("\\+", "", male_voters))) %>%
      mutate_at(vars(ends_with("_booths")), funs(as.numeric)) 
  }
)


psd <- left_join(
  f28_df %>%
    group_by(constituency_id, ps_id, ps_name) %>%
    summarize_at(vars(ends_with("_voters")), funs(sum(.[. >= 0], na.rm = FALSE))), 
  f45_cleaned
)


dplyr::select(psd, female_voters, total_female_turnout)
with(psd, table(is.na(total_female_turnout), is.na(total_turnout)))

psdf <- psd %>%
  mutate(
    total_female_turnout = case_when(
      !is.na(total_female_turnout) ~ total_female_turnout,
      is.na(total_female_turnout) & male_voters == 0 ~ total_turnout,
      TRUE ~ NA_real_
    ),
    total_male_turnout = case_when(
      !is.na(total_male_turnout) ~ total_male_turnout,
      is.na(total_male_turnout) & female_voters == 0 ~ total_turnout,
      TRUE ~ NA_real_
    ),
    female_turnout = ifelse(female_voters == 0, NA, total_female_turnout / female_voters),
    male_turnout = ifelse(male_voters == 0, NA, total_male_turnout / male_voters),
    ps_type_voter_inferred = case_when(
      female_voters > 0 & male_voters > 0 ~ "Combined",
      female_voters > 0 & male_voters == 0 ~ "Female only",
      female_voters == 0 & male_voters > 0 ~ "Male only",
      TRUE ~ NA_character_
    ),
    female_only = as.integer(ps_type_voter_inferred == "Female only")
  ) %>%
    group_by(constituency_id) %>%
    mutate(has_both = sum(female_only) > 1 & sum(ps_type_voter_inferred == "Combined") > 0) %>%
    mutate_at(vars(female_turnout, male_turnout), funs(ifelse(. > 1 | . < 0, NA, .)))

with(psdf, table(lum_group, is.na(female_turnout)))


with(psdf, table(female_only, is.na(female_turnout)))


psdf %>%
  group_by(assembly_type, ps_type_voter_inferred) %>%
  summarize_at(vars(female_turnout, male_turnout), funs(mean(., na.rm = TRUE)))

psdf_cons <- psdf %>%
  group_by(constituency_id, ps_type_voter_inferred) %>%
  summarize(n = n())

estimatr::lm_robust(female_turnout ~ female_only, data = psdf)
estimatr::lm_robust(female_turnout ~ female_only, fixed_effects = ~ constituency_id, data = psdf)

## Load in locations
psc <- read_csv("analysis/01d_scraped_ps_data.csv") %>%
  mutate(constituency_id = gsub("\\-", "", constituency_code)) %>%
  filter(!is.na(lat), !is.na(long))

## Load in electricty
library(sp)
library(raster)
lum <- raster(
  "../../pakistan_lights/data/noaa_trim_yearly_maps/trim_F182013.v4c_web.stable_lights.avg_vis.tif"
)
raster.crs <- CRS(projection(lum))
pscpt <- SpatialPointsDataFrame(psc[, c("long", "lat")], data = psc, proj4string = raster.crs)
pscpt@data$lum <- extracted.values <- extract(lum, pscpt)

psdf_lum <- left_join(
  psdf, 
  dplyr::select(as_tibble(pscpt@data), ps_number, constituency_id, lat, long, lum),
  by = c("ps_id" = "ps_number", "constituency_id")
) %>%
  mutate(lum_group = case_when(
    lum == 0 ~ "No lum",
    lum < 12 ~ "below med lum",
    lum < 63 ~ "above med lum",
    lum == 63 ~ "max lum"
  ))

table(psdf$female_only, psdf$ps_type_voter_inferred)

psd %>%
  select(ends_with("turnout"), ends_with("voters")) %>%
  head() %>%
  as.data.frame


sort(table((psdf_lum$lum)))
psdf_lum 
with(psdf_lum, plot(lum, female_turnout))

table(psdf_lum$lum_group, psdf_lum$female_only, is.na(psdf_lum$female_turnout))
estimatr::lm_robust(female_turnout ~ lum_group * female_only, psdf_lum)
summary(psdf$female_turnout)
psd %>%
  filter(female_turnout > 0, male_turnout > 0) %>%
  group_by()

head(f45_cleaned)
plot(f45_cleaned$total_votes, f45_cleaned$total_turnout)

library(estimatr)
summary(lh_robust(mpg ~ am, data = mtcars, linear_hypothesis = "am=2"))
