library(tidyverse)

ps_import <- read.csv("scrape/scraped_ps_data.csv", stringsAsFactors = FALSE, na.strings = "")

ps_data <- ps_import %>%
  select(-ps_number.1) %>%
  mutate(
    constituency_type = recode(
      cons_type,
      `PA` = "Provincial Assembly",
      `NA` = "National Assembly"
    ),
    # convert province numbers to province names
    province = recode(
      prov_number,
      `9` = "KPK",
      `10` = "FATA",
      `11` = "Punjab",
      `12` = "Sindh",
      `13` = "Balochistan",
      `14` = "Islamabad"
    ),
    # concatenate standard constituency numbers
    constituency_code = case_when(
      cons_type == "NA" ~ paste0("NA-", cons_number),
      province == "KPK" & cons_type == "PA" ~ paste0("PK-", cons_number),
      province == "Punjab" & cons_type == "PA" ~ paste0("PP-", cons_number),
      province == "Sindh" & cons_type == "PA" ~ paste0("PS-", cons_number),
      province == "Balochistan" & cons_type == "PA" ~ paste0("PB-", cons_number),
      TRUE ~ NA_character_
    ),
    # add a polling station code
    ps_code = paste(constituency_code, ps_number, sep = "-"),
    # categorize PS type by PS booths
    # ps_type = case_when(
    #   male_booths == 0 ~ "Female PS",
    #   female_booths == 0 ~ "Male PS",
    #   TRUE ~ "Mixed PS"
    # ),
    # identify possible errors in voter booths
    booth_errors = case_when(
      total_booths == 0 ~ "No Booths Reported",
      male_votes > 0 & male_booths == 0 ~ "Male Voters No Male Booths",
      female_voters > 0 & female_booths == 0 ~ "Female Voters No Female Booths"
    ),
    lat = as.numeric(lat),
    long = as.numeric(long),
    GIS_errors = case_when(
      lat < 24 | lat > 40 | long < 60 ~ "Lat-Lon Error",
      is.na(lat) | is.na(long) ~ "No GIS Data Reported",
      TRUE ~ NA_character_
    )
  ) %>%
  rename(constituency_number = cons_number,
         assembly = constituency_type,
         assembly_lab = cons_type,
         male_voter_reg = male_votes,
         female_voter_reg = female_voters,
         total_voter_reg = total_votes) %>%
  select(assembly, assembly_lab, province, constituency_code, constituency_number, 
         ps_code, ps_number, ps_name, 
         male_booths, female_booths, total_booths,
         male_voter_reg, female_voter_reg, total_voter_reg, 
         lat, long, GIS_errors, booth_errors) %>%
  arrange(assembly, province, constituency_number, ps_number)

sum_errors <- ps_data %>% filter((male_voter_reg + female_voter_reg) != total_voter_reg)
#no sum errors found

# ps_data <- ps_data %>% mutate(
#   lat_lon = paste(ps_data$lat, ps_data$long, sep = ", ")
# )
# ps_data$lat_lon[ps_data$lat_lon == ", "] <- NA

# rearrange and rename variables

# identify missing polling stations in sequence

missing_ps <- ps_data %>%
  group_by(assembly, province, constituency_code) %>%
  summarize(missing_ps_number = list(setdiff(seq_len(max(ps_number)), ps_number))) %>% 
  unnest() %>%
  mutate(ps_code = paste0(constituency_code, "-", missing_ps_number))

write.csv(missing_ps, "validity_checks/ps_sequence_gaps.csv", row.names = FALSE)


# identify unique polling stations by coordinates

# remove GIS errors
unique_PS <- ps_data %>% filter(is.na(GIS_errors))
# just the instance for each ps instance by lat/lon
unique_PS <- unique_PS[!duplicated(select(unique_PS, lat, long)) & !is.na(unique_PS$lat)& !is.na(unique_PS$long), ]

write.csv(unique_PS, "validity_checks/unique_PS_coords.csv", row.names = FALSE)

# summary statistics
province_summary <- ps_data %>% group_by(assembly, province) %>%
  summarize(
    total_male_reg = sum(male_voter_reg),
    total_female_reg = sum(female_voter_reg),
    total_voter_reg = sum(total_voter_reg)
  )

write.csv(province_summary, "validity_checks/province_voter_reg.csv", row.names = FALSE)

constituency_summary <- ps_data %>% group_by(assembly, province, constituency_code) %>%
  summarize(
    total_male_reg = sum(male_voter_reg),
    total_female_reg = sum(female_voter_reg),
    total_voter_reg = sum(total_voter_reg)
  )

write.csv(constituency_summary, "validity_checks/constituency_voter_reg.csv", row.names = FALSE)

write.csv(ps_data, "pk_polling_stations_2018.csv", row.names = FALSE)
